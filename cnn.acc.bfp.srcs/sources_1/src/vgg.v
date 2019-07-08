`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/21 20:52:59
// Module Name: vgg
// Project Name: vnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: top module of vgg16
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module vgg(
  input  wire           clk,
  input  wire           rst_n,
  // ddr request
  output reg            vgg_conv_req,
  input  wire           vgg_conv_grant,
  output wire           vgg_fc_req,
  input  wire           vgg_fc_grant,
  // ddr interface
  /*(*mark_debug="TRUE"*)*/input  wire           ddr_rd_data_valid,
  input  wire           ddr_rdy,
  input  wire           ddr_wdf_rdy,
  input  wire [511:0]   ddr_rd_data,
  input  wire           ddr_rd_data_end,
  
  output wire [29:0]    vgg_conv_addr,
  output wire [2:0]     vgg_conv_cmd,
  output wire           vgg_conv_en,
  output wire [511:0]   vgg_conv_wdf_data,
  output wire [63:0]    vgg_conv_wdf_mask, // stuck at 64'b1
  output wire           vgg_conv_wdf_end,  // stuck at 1'b1
  /*(*mark_debug="TRUE"*)*/output wire           vgg_conv_wdf_wren,
  
  output wire [29:0]    vgg_fc_addr,
  output wire [2:0]     vgg_fc_cmd,
  output wire           vgg_fc_en,
  output wire [511:0]   vgg_fc_wdf_data,
  output wire [63:0]    vgg_fc_wdf_mask, // stuck at 64'b1
  output wire           vgg_fc_wdf_end,  // stuck at 1'b1
  /*(*mark_debug="TRUE"*)*/output wire           vgg_fc_wdf_wren,
  // CNN information
  /*(*mark_debug="TRUE"*)*/input  wire           vgg_data_ready, // image data and kernel parameters are loaded
  /*(*mark_debug="TRUE"*)*/output reg            vgg_end  // end of convolution operation
);
  /*(*mark_debug="TRUE"*)*/wire [16-1:0]  _ddr_rd_data_h;
assign _ddr_rd_data_h = ddr_rd_data[16-1 : 0];
//  (*mark_debug="TRUE"*)wire [16-1:0]  _vgg_conv_wdf_data_h;
//assign _vgg_conv_wdf_data_h = vgg_conv_wdf_data[16-1 : 0];
  /*(*mark_debug="TRUE"*)*/wire [16-1:0]  _vgg_fc_wdf_data_h;
assign _vgg_fc_wdf_data_h = vgg_fc_wdf_data[16-1 : 0];
  
  localparam DDR_BANK_IMAGE   = 4'b0000;
  localparam DDR_BANK_BOTTOM  = 4'b0001;
  localparam DDR_BANK_PARAM   = 4'b0010;
  localparam DDR_BANK_TOP     = 4'b0011;
//  localparam DDR_BANK_FC      = 4'b0100;
//  localparam DDR_BANK_EXP     = 4'b0101;
  localparam DDR_ROW          = 16'h0;
  localparam DDR_COL          = 10'h0;
  localparam BOTTOM_START_ADDR  = {DDR_BANK_BOTTOM, DDR_ROW, DDR_COL};
  localparam TOP_START_ADDR     = {DDR_BANK_TOP, DDR_ROW, DDR_COL};  
  localparam KER_START_ADDR     = {DDR_BANK_PARAM, DDR_ROW, DDR_COL}; 
  localparam IMG_DATA_ADDR      = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL};
//  localparam EXP_START_ADDR     = {DDR_BANK_EXP, DDR_ROW, DDR_COL};
  
  localparam BATCH_SIZE         = 1; // total number of image in image data bank
  localparam IMG_SIZE           = 30'd49152; // 256*256*3*16/64  
  localparam EXP_SIZE           = 30'd1024;  // 8192*8bits/64
  localparam IMG_DATA_SIZE      = (IMG_SIZE + EXP_SIZE)*(BATCH_SIZE-1); // 64*4*16*16*3*16/64  
  
  //conv start,end
  reg         _vgg_start;
  reg         _vgg_data_ready_reg; // image data, parameter data loaded
  reg         _vgg_conv_end_reg;
  wire        _vgg_conv_end; // all conv. layers finished
  reg [29:0]  _vgg_image_addr; // image address in one batch
  reg [29:0]  _vgg_exp_addr;
  always@(posedge clk) begin
    _vgg_data_ready_reg <= vgg_data_ready;
    _vgg_conv_end_reg   <= _vgg_conv_end;
  end
  wire _vgg_data_ready_rising_edge;
  wire _vgg_conv_end_rising_edge;
  assign _vgg_data_ready_rising_edge= (!_vgg_data_ready_reg) && vgg_data_ready;
  assign _vgg_conv_end_rising_edge  = (!_vgg_conv_end_reg) && _vgg_conv_end;
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _vgg_start <= 1'd0;
    end else begin
      if(_vgg_data_ready_rising_edge) begin
        _vgg_start <= 1'd1;
      end else if(_vgg_conv_end_rising_edge && (_vgg_image_addr!=IMG_DATA_SIZE) )begin
        _vgg_start <= 1'd1;
      end else begin
        _vgg_start <= 1'd0;
      end
    end
  end
  
  // image addr
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _vgg_image_addr <= 30'd0;
      _vgg_exp_addr <= 30'd0;
    end else begin
      if(_vgg_data_ready_rising_edge) begin
        _vgg_image_addr <= 30'd0;
        _vgg_exp_addr <= 30'd0 + IMG_SIZE;
      end else if(_vgg_conv_end_rising_edge && (_vgg_image_addr!=IMG_DATA_SIZE)) begin
        _vgg_image_addr <= _vgg_image_addr + (IMG_SIZE+EXP_SIZE);
        _vgg_exp_addr <= _vgg_exp_addr + (IMG_SIZE+EXP_SIZE);
      end
    end
  end
  
  wire _vgg_conv_req;
  wire _vgg_conv_grant_rdy;
  wire _vgg_conv_grant_data_valid;
  wire _vgg_conv_grant_wdf_rdy;
  wire _vgg_fc_buffer_ready;
  assign _vgg_conv_grant_rdy        = ddr_rdy && vgg_conv_grant;
  assign _vgg_conv_grant_wdf_rdy    = ddr_wdf_rdy && vgg_conv_grant;
  assign _vgg_conv_grant_data_valid = ddr_rd_data_valid && vgg_conv_grant;
  // connect with fc
  wire          _vgg_conv_bram_we;
  wire [9:0]    _vgg_conv_bram_addr;
  wire [64*16-1:0]  _vgg_conv_bram_data;
  wire          _vgg_conv_bram_last_data;
  
  vgg_conv conv_layers(
    .clk(clk),
    .rst_n(rst_n),
    // to arbiter
    .vgg_conv_req(_vgg_conv_req),
    .ddr_rd_data_valid(_vgg_conv_grant_data_valid),
    .ddr_rdy(_vgg_conv_grant_rdy),
    .ddr_wdf_rdy(_vgg_conv_grant_wdf_rdy),
    .ddr_rd_data(ddr_rd_data),

    .ddr_addr(vgg_conv_addr),
    .ddr_cmd(vgg_conv_cmd),
    .ddr_en(vgg_conv_en),
    .ddr_wdf_data(vgg_conv_wdf_data),
    .ddr_wdf_mask(vgg_conv_wdf_mask),
    .ddr_wdf_end(vgg_conv_wdf_end),
    .ddr_wdf_wren(vgg_conv_wdf_wren),
    // conv. layer
    .vgg_conv_image_addr(_vgg_image_addr),
    .vgg_conv_fm_addr1(BOTTOM_START_ADDR),
    .vgg_conv_fm_addr2(TOP_START_ADDR),
    .vgg_conv_ker_addr(KER_START_ADDR),
    .vgg_conv_exp_addr(_vgg_exp_addr),
    .vgg_conv_data_ready(vgg_data_ready),
    .vgg_conv_start(_vgg_start),
    .vgg_conv_end(_vgg_conv_end),
    .vgg_conv_fc_input_buffer_ready(_vgg_fc_buffer_ready), // <-xxxxxxxxxxxxxxxxx
    .vgg_conv_last_data(_vgg_conv_bram_last_data), // fc layers start, <-xxxxxxxxxxxxxxxxx
    .vgg_conv_bram_we(_vgg_conv_bram_we),
    .vgg_conv_bram_addr(_vgg_conv_bram_addr),
    .vgg_conv_llayer_o(_vgg_conv_bram_data)
  );
  
  always@(posedge clk) begin
    vgg_conv_req  <= _vgg_conv_req;
  end
  
//  //end <-xxxxxxxxxxxxxxx
//  //simulation of conv for 1 image 
//  //---------------------------------------------
//  always@(posedge clk) begin
//    if(_vgg_conv_end_rising_edge) begin
//      vgg_end <= 1'b1;
//    end else begin
//      vgg_end <= 1'b0;
//    end
//  end
//  //fc layer
//  assign vgg_fc_req = 1'b0;
//  //---------------------------------------------
  wire _rst_i;
  wire _vgg_fc_rdy;
  wire _vgg_fc_wdf_rdy;
  wire _vgg_fc_data_valid;
  wire _vgg_all_fc_end;
  assign _rst_i = !rst_n;
  assign _vgg_fc_rdy  = ddr_rdy && vgg_fc_grant;
  assign _vgg_fc_wdf_rdy  = ddr_wdf_rdy && vgg_fc_grant;
  assign _vgg_fc_data_valid = ddr_rd_data_valid && vgg_fc_grant;

  vgg_fc fc_layers (
    .clk_i(clk),
    .rst_i(_rst_i),
    .init_calib_complete_i(_vgg_data_ready_reg),
    
    .app_rdy_i(_vgg_fc_rdy),
    .app_en_o(vgg_fc_en),
    .app_cmd_o(vgg_fc_cmd),
    .app_addr_o(vgg_fc_addr),
    .ddr3_wr_en_i(1'b0),
    .wr_burst_num_i(20'd0),
    .wr_start_addr_i(30'd0),
    .wr_data_i(512'd0),
    .app_wdf_rdy_i(_vgg_fc_wdf_rdy),
    .app_wdf_wren_o(vgg_fc_wdf_wren),
    .app_wdf_data_o(vgg_fc_wdf_data),
    .app_wdf_mask_o(vgg_fc_wdf_mask),
    .app_wdf_end_o(vgg_fc_wdf_end),
    .arbitor_req_o(vgg_fc_req),
    .arbitor_ack_i(vgg_fc_grant),
    .app_rd_data_valid_i(_vgg_fc_data_valid),
    .app_rd_data_i(ddr_rd_data),
    .app_rd_data_end_i(ddr_rd_data_end),
    .fetch_data_en_o(),
    .wr_ddr_done_o(),
    
    .prepare_data_valid_i(_vgg_conv_bram_we),
    .prepare_data_addr_i(_vgg_conv_bram_addr),
    .prepare_data_i(_vgg_conv_bram_data),
    .prepare_done_i(_vgg_conv_bram_last_data),
//    .prepare_data_valid_i(1'b0),
//    .prepare_data_addr_i(10'b0),
//    .prepare_data_i(1024'b0),
//    .prepare_done_i(1'b0),
    
    .conv_buf_free_o(_vgg_fc_buffer_ready),
    .ip_done_o(), // calculation complete
    
    .exp_done_o(_vgg_all_fc_end)
  );
 
  // vgg end
  // image counter
  reg  [6:0]  _vgg_img_count;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _vgg_img_count <= 6'd0;
    end else begin
      if(_vgg_data_ready_rising_edge) begin
        _vgg_img_count <= 6'd0;
      end else begin
        if(_vgg_conv_end_rising_edge) begin
          _vgg_img_count <= _vgg_img_count + 6'd1;
        end
      end
    end
  end
  // end
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      vgg_end <= 1'b1;
    end else begin
      if(_vgg_data_ready_rising_edge) begin
        vgg_end <= 1'b0;
      end else begin
        if((_vgg_img_count == BATCH_SIZE) && _vgg_all_fc_end) begin
          vgg_end <= 1'b1;
        end
      end
    end
  end
  
endmodule
