`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/01 08:55:45
// Module Name: rd_exp
// Project Name:cnn.acc.bfp 
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: rd_ddr_exp simulation top module
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module top_rd_ddr_exp(
  input  wire           clk,
  input  wire           rst_n,
  // ddr request
  output wire           rd_data_req,
  input  wire           rd_data_grant,
  // ddr interface
  input  wire           ddr_rd_data_valid,
  input  wire           ddr_rdy,
  input  wire           ddr_wdf_rdy,
  input  wire [511:0]   ddr_rd_data,
  input  wire           ddr_rd_data_end,
  input  wire           tb_load_done, // image,parameters and exponent data are loaded
  
  output wire [29:0]    rd_data_addr,
  output wire [2:0]     rd_data_cmd,
  output wire           rd_data_en
);

  localparam DDR_BANK_IMAGE     = 4'b0000;
  localparam DDR_BANK_BOTTOM    = 4'b0001;
  localparam DDR_BANK_PARAM     = 4'b0010;
  localparam DDR_BANK_TOP       = 4'b0011;
  localparam DDR_BANK_EXP       = 4'b0101;
  localparam DDR_ROW            = 16'h0;
  localparam DDR_COL            = 10'h0;
  localparam BOTTOM_START_ADDR  = {DDR_BANK_BOTTOM, DDR_ROW, DDR_COL};
  localparam TOP_START_ADDR     = {DDR_BANK_TOP, DDR_ROW, DDR_COL};
  localparam KER_START_ADDR     = {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
  localparam IMG_DATA_ADDR      = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL};
  localparam EXP_START_ADDR     = {DDR_BANK_EXP, DDR_ROW, DDR_COL};

  localparam DATA_WIDTH       = 8;
  localparam EXP_WIDTH        = 5;
  localparam LAYER_NUM        = 13;
  localparam CHANNELS         = 10'd3;
  localparam FM_SIZE          = 30'd16384;
  localparam BAR_SIZE         = 30'd1024;
  localparam HALF_BAR_SIZE    = 30'd512;
  localparam END_OF_X         = 4'd15;
  localparam END_OF_Y         = 4'd15;
  localparam EXP_FM           = 5'h16;
  
  //read control
  reg                       _rd_exp;
  reg  [3:0]                _rd_exp_ker_burst_num;
  wire                      _rd_exp_ker_only;
//  reg  [29:0]               _rd_exp_addr;
  wire [EXP_WIDTH-1:0]      _rd_exp_bottom_exp_in;
  wire [EXP_WIDTH-1:0]      _rd_exp_bottom_exp;
  wire [EXP_WIDTH*64-1:0]   _rd_exp_bias_exp;
  wire                      _rd_exp_valid;
  wire                      _rd_exp_full;
  
  wire              _loadingDone;
  wire              _rd_data_load_ddr_done_rising_edge;
  reg               _rd_data_load_ddr_done_reg;
  reg               start_next;
  reg  [3:0]        _layer_idx;
  reg               _readEnd;

  initial start_next = 1'b0;
  assign _loadingDone                         = _rd_data_load_ddr_done_rising_edge;
  assign _rd_data_load_ddr_done_rising_edge   = ((!_rd_data_load_ddr_done_reg) && tb_load_done);
  assign rd_data_req                          = _rd_exp;
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_load_ddr_done_reg <= 1'b0;
    end else begin
      _rd_data_load_ddr_done_reg <= tb_load_done;
    end
  end 
  
  //read control 
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_exp <= 1'b0;
      _layer_idx <= 4'd0;
      _readEnd <= 1'b0;
    end else begin
      if(tb_load_done) begin
        if(start_next || _loadingDone) begin
          if(_loadingDone) begin
            _rd_exp <= 1'b1;
            _layer_idx <= 4'd0;
          end else if (start_next) begin
            _rd_exp <= 1'b1;
            if(_layer_idx == (LAYER_NUM-1'b1)) begin
              _layer_idx <= 4'd0;
              _readEnd <= 1'b1;
            end else begin
              _layer_idx <= _layer_idx + 1'b1;
            end
          end
        end
      end
    end
  end
  
  assign _rd_exp_ker_only = (_layer_idx != 4'd0);
  assign _rd_exp_bottom_exp_in = _layer_idx;
  
  always@(_layer_idx) begin
    case(_layer_idx)
      4'd0:  _rd_exp_ker_burst_num = 4'd1;
      4'd1:  _rd_exp_ker_burst_num = 4'd1;
      4'd2:  _rd_exp_ker_burst_num = 4'd2;
      4'd3:  _rd_exp_ker_burst_num = 4'd2;
      4'd4:  _rd_exp_ker_burst_num = 4'd4;
      4'd5:  _rd_exp_ker_burst_num = 4'd4;
      4'd6:  _rd_exp_ker_burst_num = 4'd4;
      4'd7:  _rd_exp_ker_burst_num = 4'd8;
      4'd8:  _rd_exp_ker_burst_num = 4'd8;
      4'd9:  _rd_exp_ker_burst_num = 4'd8;
      4'd10: _rd_exp_ker_burst_num = 4'd8;
      4'd11: _rd_exp_ker_burst_num = 4'd8;
      4'd12: _rd_exp_ker_burst_num = 4'd8;
    endcase
  end
  
  
  //read next layer
  always@(_rd_exp_full) begin
    if(_rd_exp_full) begin
      _rd_exp = 1'b0;
      #200 start_next = 1'b1;
      #20 start_next = 1'b0;
    end
  end
  
  
 rd_ddr_exp #(
  .DATA_WIDTH(DATA_WIDTH),
  .EXP_WIDTH(EXP_WIDTH)
 )rd_ddr_exp_u(
   .clk(clk),
   .rst_n(rst_n),
   .ddr_rdy(ddr_rdy),
   .ddr_addr(rd_data_addr),
   .ddr_cmd(rd_data_cmd),
   .ddr_en(rd_data_en),
   .ddr_rd_data(ddr_rd_data),
   .ddr_rd_data_valid(ddr_rd_data_valid),
   
   .rd_exp(_rd_exp),
   .rd_exp_ker_burst_num(_rd_exp_ker_burst_num), // number of conv layer bias data, 8bits*512/512=8
   .rd_exp_ker_only(_rd_exp_ker_only), //valid except for conv1_1 layer
   .rd_exp_addr(EXP_START_ADDR),
   .rd_exp_bottom_exp_in(_rd_exp_bottom_exp_in), //max exp of bottom, input from wr_ddr_data
   
   .rd_exp_bottom_exp(_rd_exp_bottom_exp),
   .rd_exp_bias_exp(_rd_exp_bias_exp),
   .rd_exp_valid(_rd_exp_valid),
   .rd_exp_full(_rd_exp_full)
 );
  
  always@(_rd_exp or _layer_idx or _readEnd) 
  begin
    if(_rd_exp) begin
      $write("reading info: \n");
      $write("readExp:%d, ",_rd_exp);
      $write("layerIdx:%d, ", _layer_idx);
      $write("readEnd:%d\n", _readEnd);
    end
  end      
  
  always@(_readEnd) begin
    if(_readEnd) begin
      $finish;
    end
  end

endmodule
