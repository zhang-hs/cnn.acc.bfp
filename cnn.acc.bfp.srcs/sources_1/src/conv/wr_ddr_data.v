`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: zhanghs
// 
// Create Date: 2018/11/05 22:14:47
// Module Name: wr_ddr_data
// Project Name: cnn.bfp.acc
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: write data into ddr
//              with pooling enabled
//              check 14x14 error -- 1.1
//              compensate for bram reading -- 1.2
//              16 bit data width (not checked) -- 1.3
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//`define sim_

module wr_ddr_data#(
  parameter FP_WIDTH   = 16,
  parameter MID_WIDTH  = 29,
  parameter K_C        = 64
)(
  input  wire                                                     clk,
  input  wire                                                     rst_n,
  // ddr
  input  wire                                                     ddr_rdy,
  input  wire                                                     ddr_wdf_rdy,
  output reg  [511:0]                                             ddr_wdf_data,
  output reg  [63:0]                                              ddr_wdf_mask,
  output reg                                                      ddr_wdf_end,
  output reg                                                      ddr_wdf_wren,
  output reg  [29:0]                                              ddr_addr,
  output reg  [2:0]                                               ddr_cmd,
  output reg                                                      ddr_en,
  //
  input  wire                                                     wr_data_top, // write top data enable, from fsm
  input  wire [29:0]                                              wr_data_top_addr, // writing address; provided by top module, not fsm
  input  wire [9:0]                                               wr_data_top_channels, // num of top data channels; provided by top module, not fsm
  input  wire [7*7*FP_WIDTH-1:0]                                  wr_data_data_i,
  input  wire                                                     wr_data_x_eq_0,
  input  wire                                                     wr_data_y_eq_0,
  input  wire                                                     wr_data_x_eq_end,
  input  wire                                                     wr_data_y_eq_end,
  input  wire                                                     wr_data_pooling_en, // is pooling layer output; provided by top module, not fsm
  input  wire [29:0]                                              wr_data_half_bar_size, // size of half bar; provided by top module, not fsm
  input  wire [29:0]                                              wr_data_fm_size, // provided by top module, not fsm, output fm size
  /*(*mark_debug="TRUE"*)*/input  wire                                                     wr_data_data_valid, // data valid on wr_data_data_i
  output reg                                                      wr_data_rd_top_buffer,
  output wire                                                     wr_data_next_quarter,   // writing the last datum of current 7x7, requiring the next 7x7 data
  output wire                                                     wr_data_next_channel, // current channel finished, writing the last datum to ddr
  output wire                                                     wr_data_done, // data writing done
  // last layer
  input  wire                                                     wr_data_last_layer, // is last conv. layer output; from top module, last input feature map
  input  wire [K_C*FP_WIDTH-1:0]                                  wr_data_llayer_i,   // last layer pooling data
  input  wire [3:0]                                               wr_data_cur_ker_set, // kernel set
  /*(*mark_debug="TRUE"*)*/input  wire                                                     wr_data_llayer_data_valid, // last layer pooling data valid
  input  wire                                                     wr_data_llayer_valid_first,// first valid pooling data
  input  wire                                                     wr_data_llayer_valid_last, // last valid pooling data
  output reg                                                      wr_data_llayer_last_data,
  output reg                                                      wr_data_bram_we, // enable writing to bram
  output wire [9:0]                                               wr_data_bram_addr, // maximum 49*16=784
  output reg  [K_C*FP_WIDTH-1:0]                                  wr_data_llayer_o   // last layer pooling data
  );
//  (*mark_debug="TRUE"*)wire[16-1:0]   _wr_data_data_i_partial;
//  assign _wr_data_data_i_partial = wr_data_data_i[16-1:0];
//    (*mark_debug="TRUE"*)wire[16-1:0]   _wr_data_llayer_i_partial;
//  assign _wr_data_llayer_i_partial = wr_data_llayer_i[16-1:0];

  localparam WR_DATA_RST    =3'd0;
  localparam WR_DATA_UPPER0 =3'd1; // top left 7x7
  localparam WR_DATA_UPPER1 =3'd2; // top right 7x7
  localparam WR_DATA_LOWER0 =3'd3; // bottom left 7x7
  localparam WR_DATA_LOWER1 =3'd4; // bottom right 7x7
  localparam WR_DATA_POOL   =3'd5; // write pooling data
  //
  localparam DDR_DATA_WIDTH   = 64;
  localparam DDR_BURST_LEN    = 8; // ddr data burst length
  localparam DATA_WIDTH       = FP_WIDTH;
  localparam DDR_DATA_BURST_WIDTH = 512;
  localparam MINI_PATCH_NUM   = 4; // number of mini-patch in 1 atom(14x14)
  localparam MINI_PATCH_DATUM_NUM = 64; // number of datum in 1 7x7 mini-patch
  localparam DATUM_NUM        = MINI_PATCH_DATUM_NUM*MINI_PATCH_NUM*DATA_WIDTH/DDR_DATA_BURST_WIDTH; // num of burst data to write
  localparam MINI_1_SIZE = (7*7*DATA_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*DDR_BURST_LEN;
  localparam MINI_2_SIZE = 2*MINI_1_SIZE;
  localparam MINI_1_CNT  = MINI_PATCH_DATUM_NUM*DATA_WIDTH/DDR_DATA_BURST_WIDTH-1;
  localparam MINI_2_CNT  = 2*MINI_PATCH_DATUM_NUM*DATA_WIDTH/DDR_DATA_BURST_WIDTH-1;

  reg  [2:0]    _wr_data_state;
  reg  [2:0]    _wr_data_next_state;

  reg         _wr_data_data_next;
  reg [29:0]  _wr_data_patch_addr;
  reg [2:0]   _wr_data_data_cnt;
  reg [29:0]  _wr_data_fm_offset;
  reg [9:0]   _wr_data_channel_cnt; // channel counter, increase by 1 when the last datum is writen
  wire[511:0] _wr_data_0;
  wire[511:0] _wr_data_1;
  wire[9:0]   _wr_data_end_channel; // last channel number
  assign      _wr_data_end_channel = wr_data_top_channels - 1'b1;
  wire        _wr_data_upper0_last;
  wire        _wr_data_upper1_last;
  wire        _wr_data_lower0_last;
  wire        _wr_data_lower1_last;
  wire        _wr_data_pool_last;
  wire        _wr_data_last_channel;

  // FF
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _wr_data_state <= WR_DATA_RST;
    end else begin
      _wr_data_state <= _wr_data_next_state;
    end
  end
  // transition
  always@(_wr_data_state or wr_data_top or wr_data_pooling_en or 
          _wr_data_upper0_last or _wr_data_upper1_last or _wr_data_lower0_last or
          _wr_data_lower1_last or _wr_data_pool_last or
          _wr_data_last_channel) begin
    _wr_data_next_state = WR_DATA_RST;
    case(_wr_data_state)
      WR_DATA_RST: begin
        if(wr_data_top) begin
          if(wr_data_pooling_en) begin
            _wr_data_next_state = WR_DATA_POOL;
          end else begin
            _wr_data_next_state = WR_DATA_UPPER0;
          end
        end else begin
          _wr_data_next_state = WR_DATA_RST;
        end
      end
      // top left
      WR_DATA_UPPER0: begin
        if(_wr_data_upper0_last) begin
          _wr_data_next_state = WR_DATA_UPPER1;
        end else begin
          _wr_data_next_state = WR_DATA_UPPER0;
        end
      end
      // top right
      WR_DATA_UPPER1: begin
        if(_wr_data_upper1_last) begin
          _wr_data_next_state = WR_DATA_LOWER0;
        end else begin
          _wr_data_next_state = WR_DATA_UPPER1;
        end
      end
      // bottom left
      WR_DATA_LOWER0: begin
        if(_wr_data_lower0_last) begin
          _wr_data_next_state = WR_DATA_LOWER1;
        end else begin
          _wr_data_next_state = WR_DATA_LOWER0;
        end
      end
      // bottom right
      WR_DATA_LOWER1: begin
        if(_wr_data_lower1_last) begin
          if(_wr_data_last_channel) begin
            _wr_data_next_state = WR_DATA_RST;
          end else begin
            _wr_data_next_state = WR_DATA_UPPER0;
          end
        end else begin
          _wr_data_next_state = WR_DATA_LOWER1;
        end
      end
      // pooling
      WR_DATA_POOL: begin
        if(_wr_data_pool_last) begin
          if(_wr_data_last_channel) begin
            _wr_data_next_state = WR_DATA_RST;
          end else begin
            _wr_data_next_state = WR_DATA_POOL;
          end
        end else begin
          _wr_data_next_state = WR_DATA_POOL;
        end
      end
    endcase
  end
  // logic
  always@(_wr_data_state or ddr_rdy or ddr_wdf_rdy or wr_data_data_valid) begin
    ddr_en        = 1'b0;
    ddr_cmd       = 3'b1; // read
    ddr_wdf_end   = 1'b0;
    ddr_wdf_wren  = 1'b0;
    ddr_wdf_mask  = 64'hffffffff;
    _wr_data_data_next  = 1'b0;
    case(_wr_data_state)
      WR_DATA_RST: begin
        ddr_en        = 1'b0;
        ddr_cmd       = 3'b1; // read
        ddr_wdf_wren  = 1'b0;
      end
      WR_DATA_POOL,
      WR_DATA_UPPER0,
      WR_DATA_UPPER1: begin
        if(ddr_rdy && ddr_wdf_rdy && wr_data_data_valid) begin
          ddr_en  = 1'd1;
          ddr_cmd = 3'd0;
          ddr_wdf_end   = 1'b1;
          ddr_wdf_wren  = 1'b1;
          ddr_wdf_mask  = 64'h0; // no mask
          _wr_data_data_next  = 1'b1;
        end else begin
          ddr_en        = 1'd0;
          ddr_cmd       = 3'h0;
          ddr_wdf_wren  = 1'b0;
          _wr_data_data_next  = 1'b0;
        end
      end
      WR_DATA_LOWER0,
      WR_DATA_LOWER1: begin
        if(ddr_rdy && ddr_wdf_rdy && wr_data_data_valid) begin
          ddr_en  = 1'd1;
          ddr_cmd = 3'd0;
          ddr_wdf_end   = 1'b1;
          ddr_wdf_wren  = 1'b1;
          ddr_wdf_mask  = 64'h0; // no mask
          _wr_data_data_next  = 1'b1;
        end else begin
          ddr_en        = 1'd0;
          ddr_cmd       = 3'h0;
          ddr_wdf_wren  = 1'b0;
          _wr_data_data_next  = 1'b0;
        end
      end
    endcase
  end
  // ddr_addr
  always@(_wr_data_state or _wr_data_patch_addr or _wr_data_fm_offset or
          _wr_data_data_cnt or wr_data_half_bar_size) begin
    ddr_addr = 30'd0;
    case(_wr_data_state)
      WR_DATA_RST: begin
        ddr_addr = 30'd0;
      end
      WR_DATA_POOL,
      WR_DATA_UPPER0: begin
        ddr_addr  = _wr_data_patch_addr + _wr_data_fm_offset +
                   {{27'h0,_wr_data_data_cnt}<<3}; // <-x
      end
      WR_DATA_UPPER1: begin
        ddr_addr  = _wr_data_patch_addr + _wr_data_fm_offset +
                   {{27'h0,_wr_data_data_cnt}<<3} + MINI_1_SIZE; // <-x
      end
      WR_DATA_LOWER0: begin
        ddr_addr  = _wr_data_patch_addr + _wr_data_fm_offset +
                    wr_data_half_bar_size + {{27'h0,_wr_data_data_cnt}<<3}; // <-x
      end
      WR_DATA_LOWER1: begin
        ddr_addr  = _wr_data_patch_addr + _wr_data_fm_offset +
                    wr_data_half_bar_size + {{27'h0,_wr_data_data_cnt}<<3} + MINI_1_SIZE; // <-x
      end
    endcase
  end
  // patch start addr
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _wr_data_patch_addr <= 30'd0;
    end else begin
      // update patch address
      if(wr_data_top && (_wr_data_state==WR_DATA_RST)) begin
        if(wr_data_x_eq_0) begin
          if(wr_data_y_eq_0) begin
          // output fm first address
            _wr_data_patch_addr <= wr_data_top_addr;
          end else begin
            // to next bar
            if(wr_data_pooling_en) begin
              _wr_data_patch_addr <= _wr_data_patch_addr + MINI_1_SIZE;
            end else begin
              _wr_data_patch_addr <= _wr_data_patch_addr + wr_data_half_bar_size + MINI_2_SIZE;
            end
          end
        end else begin
          // increment
          if(wr_data_pooling_en) begin
            _wr_data_patch_addr <= _wr_data_patch_addr + MINI_1_SIZE;
          end else begin
            _wr_data_patch_addr <= _wr_data_patch_addr + MINI_2_SIZE;
          end
        end
      end
      // reset
      if(wr_data_x_eq_end && wr_data_y_eq_end && wr_data_done) begin
        _wr_data_patch_addr <= 30'd0;
      end
    end
  end
  // fm offset, data counter, channel counter
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _wr_data_data_cnt   <= 3'h0;
      _wr_data_fm_offset  <= 30'h0;
      _wr_data_channel_cnt<= 10'h0;
    end else begin
      if(wr_data_top && (_wr_data_state==WR_DATA_RST)) begin
      // reset
        _wr_data_data_cnt   <= 3'h0;
        _wr_data_fm_offset  <= 30'h0;
        _wr_data_channel_cnt<= 10'h0;
      end else begin
      // increment
        if(_wr_data_data_next) begin
          _wr_data_data_cnt <= _wr_data_data_cnt + 1'b1;
        end
        if(_wr_data_upper0_last || _wr_data_upper1_last ||
           _wr_data_lower0_last || _wr_data_lower1_last ||
           _wr_data_pool_last) begin
        // end of current channel half/pooling patch data
          _wr_data_data_cnt <= 3'd0;
        end
        if(_wr_data_lower1_last) begin
        // increase fm offset and channel counter value at next clock
          _wr_data_fm_offset  <= _wr_data_fm_offset + wr_data_fm_size;
          _wr_data_channel_cnt<= _wr_data_channel_cnt + 1'b1;
        end
        if(_wr_data_pool_last) begin
          _wr_data_fm_offset  <= _wr_data_fm_offset + wr_data_fm_size;
          _wr_data_channel_cnt<= _wr_data_channel_cnt + 1'b1;
        end
      end
    end
  end
  // "last" signals
  assign _wr_data_last_channel = (_wr_data_channel_cnt == _wr_data_end_channel);
  assign _wr_data_upper0_last = ddr_wdf_wren ? ((_wr_data_data_cnt == MINI_1_CNT) && (_wr_data_state==WR_DATA_UPPER0)) : 1'b0;
  assign _wr_data_upper1_last = ddr_wdf_wren ? ((_wr_data_data_cnt == MINI_1_CNT) && (_wr_data_state==WR_DATA_UPPER1)) : 1'b0;
  assign _wr_data_lower0_last = ddr_wdf_wren ? ((_wr_data_data_cnt == MINI_1_CNT) && (_wr_data_state==WR_DATA_LOWER0)) : 1'b0;
  assign _wr_data_lower1_last = ddr_wdf_wren ? ((_wr_data_data_cnt == MINI_1_CNT) && (_wr_data_state==WR_DATA_LOWER1)) : 1'b0;
  assign _wr_data_pool_last   = ddr_wdf_wren ? ((_wr_data_data_cnt == MINI_1_CNT) && (_wr_data_state==WR_DATA_POOL)) : 1'b0;
  assign wr_data_next_channel = wr_data_pooling_en ? _wr_data_pool_last : _wr_data_lower1_last;
  assign wr_data_next_quarter = _wr_data_lower0_last || _wr_data_lower1_last || _wr_data_upper0_last || _wr_data_upper1_last || _wr_data_pool_last;
  assign wr_data_done         = ((wr_data_pooling_en ? _wr_data_pool_last : _wr_data_lower1_last) && _wr_data_last_channel) ? 1'b1 : 1'b0;
  // data to write
  assign _wr_data_0 = wr_data_data_i[32*DATA_WIDTH-1 : 0*DATA_WIDTH];
  assign _wr_data_1 = {{(15*DATA_WIDTH){1'b0}}, wr_data_data_i[49*DATA_WIDTH-1 : 32*DATA_WIDTH]};

  // read buffer
  always@(posedge clk) begin
    if(_wr_data_next_state!=WR_DATA_RST && _wr_data_state==WR_DATA_RST) begin
      wr_data_rd_top_buffer <= 1'b1;
    end else begin
      if(wr_data_next_quarter) begin
        wr_data_rd_top_buffer <= 1'b1;
      end else begin
        wr_data_rd_top_buffer <= 1'b0;
      end
    end
  end

  // data
  always@(_wr_data_data_cnt or wr_data_data_valid or
          _wr_data_0 or _wr_data_1) begin
    ddr_wdf_data = {512*{1'b0}};
    case(_wr_data_data_cnt)
      3'd0: begin
        if(wr_data_data_valid) begin
          ddr_wdf_data = _wr_data_0;
        end
      end
      3'd1: begin
        if(wr_data_data_valid) begin
          ddr_wdf_data = _wr_data_1;
        end
      end
    endcase
  end

  // <---need to be modified
  // last layer data write, used for fc 
  //------------------------------------------------------------------------------------
  // enable && data
  reg [9:0] _wr_data_bram_base_addr;
  reg [9:0] _wr_data_bram_base_addr_reg;
  reg [9:0] _wr_data_bram_offset;
  always@(wr_data_last_layer or wr_data_cur_ker_set) begin
    if(!wr_data_last_layer) begin
      _wr_data_bram_base_addr = 10'd0;
    end else begin
      _wr_data_bram_base_addr = 10'd0;
      case(wr_data_cur_ker_set)
        4'd0:  _wr_data_bram_base_addr = 10'd0;
        4'd1:  _wr_data_bram_base_addr = 10'd98;
        4'd2:  _wr_data_bram_base_addr = 10'd196;
        4'd3:  _wr_data_bram_base_addr = 10'd294;
        4'd4:  _wr_data_bram_base_addr = 10'd392;
        4'd5: _wr_data_bram_base_addr = 10'd490;
        4'd6: _wr_data_bram_base_addr = 10'd588;
        4'd7: _wr_data_bram_base_addr = 10'd686;
      endcase
    end
  end
  always@(posedge clk) begin
    _wr_data_bram_base_addr_reg <= _wr_data_bram_base_addr;
  end
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wr_data_bram_we   <= 1'b0;
      wr_data_llayer_o  <= {(K_C*DATA_WIDTH){1'b0}};
    end else begin
      if(wr_data_last_layer) begin
        if(wr_data_llayer_data_valid) begin
          wr_data_bram_we   <= 1'b1;
          wr_data_llayer_o <= wr_data_llayer_i;
        end else begin
          wr_data_bram_we   <= 1'b0;
        end
      end else begin
        wr_data_bram_we   <= 1'b0;
      end
    end
  end
  // address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _wr_data_bram_offset  <= 10'd0;
    end else begin
      if(wr_data_last_layer) begin
        if(wr_data_llayer_valid_first) begin
          _wr_data_bram_offset  <= 10'd0;
        end else if(wr_data_llayer_data_valid) begin
          if(_wr_data_bram_offset==10'd48) begin
            _wr_data_bram_offset  <= 10'd0;
          end else begin
            _wr_data_bram_offset  <= _wr_data_bram_offset + 1'b1;
          end
        end
      end
    end
  end
  assign wr_data_bram_addr = _wr_data_bram_base_addr_reg + _wr_data_bram_offset;
  // last conv. data
  always@(posedge clk) begin
    wr_data_llayer_last_data <= wr_data_llayer_valid_last;
//    `ifdef sim_
//    if(wr_data_llayer_valid_last) begin
//      $display("***************************************************************");
//      $display("* %t: last layer last valid (at conv/wr_op/wr_ddr_data.7x7.v)", $realtime);
//      $display("***************************************************************");
//    end
//    `endif
  end
  //----------------------------------------------------------------------------------------


endmodule
