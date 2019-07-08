`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/13 15:06:13
// Module Name: conv
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: top moudle of convolution layer 
// 
// Revision 1.1 - connect with board.tb.v(for simulation)
//          1.2 - connect with fsm.v/rd_ddr_data.v/mem_top.v
//////////////////////////////////////////////////////////////////////////////////

`define NULL 0

module conv(
  input  wire                             clk,
  input  wire                             rst_n,
  // ddr interface
  output reg                              fm_ddr_req,
  output reg  [29:0]                      ddr_addr,
  output reg  [2:0]                       ddr_cmd,
  output reg                              ddr_en,
  input  wire                             ddr_rdy,
  input  wire                             ddr_wdf_rdy,
  input  wire [511:0]                     ddr_rd_data,
  input  wire                             ddr_rd_data_valid,
  output wire [511:0]                     ddr_wdf_data,
  output wire [63:0]                      ddr_wdf_mask, // stuck at 64'b1
  output wire                             ddr_wdf_end,  // stuck at 1'b1
  output wire                             ddr_wdf_wren,
  // layer configuration
//  input  wire [2:0]                       fm_ker_size,                 
  input  wire                             fm_relu_en, // enable relu
  input  wire                             fm_pooling_en, // enable pooling
  input  wire                             fm_last_layer, // last input layer
  // bottom
//  input  wire [7:0]                       fm_bottom_width, //224 
input  wire [4:0]                       fm_layer_index,
  input  wire [4:0]                       fm_width, // bottom data width / atomic_width
  input  wire [4:0]                       fm_height, // bottom data height / atomic_height
  input  wire [29:0]                      fm_bottom_ddr_addr, // bottom data address to read from
  input  wire [9:0]                       fm_bottom_channels, // num of bottom data channels
  input  wire [29:0]                      fm_size, // fm_width*fm_height*float_num_width/ddr_data_width
  input  wire [29:0]                      fm_1bar_size, // 14*fm_width*float_num_width/ddr_data_width -> 64*4*num_of_atom*float_num_width/ddr_data_width(32bit)
  input  wire [29:0]                      fm_half_bar_size, // 7*rd_data_max_x*float_num_width/ddr_data_width -> 64*2*num_of_atom*float_num_width/ddr_data_width(32bit)
  // exp,kernel and bias
  input  wire [29:0]                      fm_rd_exp_addr,
  input  wire [9:0]                       fm_bias_num, // num of top data channels -> num of bias
  input  wire [4:0]                       fm_bias_ddr_burst_num, // num of burst to read all bias data ,16
  input  wire [8:0]                       fm_bias_offset, // address occupied by bias data
  input  wire [29:0]                      fm_ker_ddr_addr, // parameter data address
  // top
  input  wire [29:0]                      fm_top_ddr_addr, // top data address to write to
  input  wire [9:0]                       fm_top_channels, // num of top data channels
  input  wire [29:0]                      fm_top_fm_size, // top feature map size
  input  wire [29:0]                      fm_top_half_bar_size, // 7*rd_data_max_x*float_num_width/ddr_data_width -> 64*2*num_of_atom*float_num_width/ddr_data_width(32bit)
  // last layer
  output wire                             fm_llayer_last_data,
  output wire                             fm_llayer_bram_we,
  output wire [9:0]                       fm_llayer_bram_addr,
  output wire [64*16-1:0]                 fm_llayer_bram_o, //mid_data_with:29-->32
  //
  input  wire                             fm_data_ready, // bottom data and kernel data is ready on ddr -> convolution start
  /*(*mark_debug="TRUE"*)*/input  wire                             fm_start, // conv layer operation start signal
  output wire                             fm_conv_done // current layer convolution(read & convolution & write) done
);

  localparam ATOMIC_W         = 14;
  localparam ATOMIC_H         = 14;
  localparam DATA_WIDTH       = 8;
  localparam FP_WIDTH         = 16;
  localparam EXP_WIDTH        = 5;
  localparam MID_WIDTH        = 29;
  localparam DDR_DATA_WIDTH   = 64;
  localparam DDR_BURST_LEN    = 8;
  localparam K_C              = 64;
  localparam K_H              = 3;
  localparam K_W              = 3;
  localparam MAX_O_C          = 512;
  localparam DDR_PARAM_OFFSET = K_C * K_H * K_W * FP_WIDTH / DDR_DATA_WIDTH;
  
  //ddr interface
  wire            _fm_ddr_req;
  wire [29:0]     _fm_rd_exp_ddr_addr;
  wire [2:0]      _fm_rd_exp_ddr_cmd;
  wire            _fm_rd_exp_ddr_en;
  wire [29:0]     _fm_rd_data_ddr_addr;
  wire [2:0]      _fm_rd_data_ddr_cmd;
  wire            _fm_rd_data_ddr_en;
  wire [29:0]     _fm_rd_param_ddr_addr;
  wire [2:0]      _fm_rd_param_ddr_cmd;
  wire            _fm_rd_param_ddr_en;
  wire [29:0]     _fm_wr_data_ddr_addr;
  wire [2:0]      _fm_wr_data_ddr_cmd;
  wire            _fm_wr_data_ddr_en;
  // conv_op
  /*(*mark_debug="TRUE"*)*/wire                                _fm_conv_start;
  wire                                _fm_conv_busy;
  wire                                _fm_conv_at_last_pos;
  /*(*mark_debug="TRUE"*)*/wire                                _fm_conv_last_valid;
  wire                                _fm_conv_start_at_next_clk;
  wire                                _fm_conv_ker0;
  wire                                _fm_conv_ker1;
  wire                                _fm_conv_on_first_fm;
  wire                                _fm_conv_on_last_fm;
  /*(*mark_debug="TRUE"*)*/wire                                _fm_conv_valid;
  /*(*mark_debug="TRUE"*)*/wire [3:0]                          _fm_conv_x;
  /*(*mark_debug="TRUE"*)*/wire [3:0]                          _fm_conv_y;
  wire [3:0]                          _fm_to_conv_x;
  wire [3:0]                          _fm_to_conv_y;
  wire [4:0]                          _fm_conv_rd_col;
//`ifdef sim_
//  wire [4:0]                          _fm_conv_rd_row;
//`endif
  wire                                _fm_patch_bram_rd_en;
  wire [9:0]                          _fm_conv_ker_num;
  wire [K_C*K_H*K_W*DATA_WIDTH-1:0]   _fm_conv_ker;
  wire [16*DATA_WIDTH-1:0]            _fm_conv_bottom;
  wire                                _fm_conv_bottom_valid;
  wire [7*7*FP_WIDTH-1:0]             _fm_conv_top;
  wire [K_C*MID_WIDTH-1:0]            _fm_conv_op_top_o;
  wire                                _fm_conv_op_rd_partial_sum;
  wire [K_C*MID_WIDTH-1:0]            _fm_conv_op_partial_sum;
  /*(*mark_debug="TRUE"*)*/wire                                _fm_conv_op_partial_sum_valid;
  
//  (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] _fm_conv_bottom_h;
//  assign _fm_conv_bottom_h = _fm_conv_bottom[16*DATA_WIDTH-1:15*DATA_WIDTH]; 
//  (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] _fm_conv_ker_h;
//  assign _fm_conv_ker_h = _fm_conv_ker[DATA_WIDTH-1:0];   
//  (*mark_debug="TRUE"*)wire [MID_WIDTH-1:0] _fm_conv_op_top_o_h;
//  assign _fm_conv_op_top_o_h = _fm_conv_op_top_o[MID_WIDTH-1:0];
//  (*mark_debug="TRUE"*)wire [MID_WIDTH-1:0] _fm_conv_op_partial_sum_h;
//  assign _fm_conv_op_partial_sum_h = _fm_conv_op_partial_sum[MID_WIDTH-1:0];
  // pooling
  wire                                _fm_pooling_last_pos;
  // write_data
  wire                           _fm_wr_data_sw_on;
  /*(*mark_debug="TRUE"*)*/wire                           _fm_wr_data_top; // write enable
  wire                           _fm_wr_data_x_eq_0;
  wire                           _fm_wr_data_y_eq_0;
  wire                           _fm_wr_data_x_eq_end;
  wire                           _fm_wr_data_y_eq_end;
  wire                           _fm_top_data_valid;
  wire                           _fm_wr_data_next_quarter;
  wire                           _fm_wr_data_next_channel;
  /*(*mark_debug="TRUE"*)*/wire                           _fm_wr_data_done;
  wire [K_C*FP_WIDTH-1:0]        _fm_wr_llayer_o;
  wire                           _fm_wr_llayer_valid;
  wire                           _fm_wr_llayer_last_pos;
  wire                           _fm_wr_llayer_first_pos;
  wire [3:0]                     _fm_wr_llayer_ker_set;
  //rd_ddr_exp
  /*(*mark_debug="TRUE"*)*/wire                           _fm_rd_exp;
  wire                           _fm_rd_exp_sw_on;
  wire [29:0]                    _fm_rd_exp_addr;
  wire [EXP_WIDTH-1:0]           _fm_rd_exp_bottom_exp_i; //max exp of bottom, input from wr_ddr_data
  wire                           _fm_rd_exp_bottom_exp_i_valid;
  wire [EXP_WIDTH-1:0]           _fm_rd_exp_bottom_exp_o; //updated max exp of bottom
  wire                           _fm_rd_exp_bottom_exp_o_valid;
  wire [(EXP_WIDTH+1)*K_C-1:0]   _fm_rd_exp_bias_exp;
  wire                           _fm_rd_bias_exp_valid;
  wire                           _fm_rd_bias_exp_last;
  wire                           _fm_rd_exp_full;
 
  // rd_ddr_data
  wire          _fm_rd_data_full;
  /*(*mark_debug="TRUE"*)*/wire          _fm_rd_data_bottom;
  wire [4:0]    _fm_rd_data_x;
  wire [4:0]    _fm_rd_data_y;
  wire [4:0]    _fm_rd_data_end_of_x;
  wire [4:0]    _fm_rd_data_end_of_y;
  wire          _fm_rd_data_first_fm;
  wire [29:0]   _fm_rd_data_ith_offset;
  wire [8:0]    _fm_rd_data_ith_fm;
  wire          _fm_rd_data_sw_on;
  wire          _fm_rd_data_cache_full;
//  wire          _fm_rd_data_cache_release_done;
  wire [255:0]  _fm_rd_data_data;
  wire          _fm_rd_data_valid;
//  wire          _fm_rd_data_cache_idx;  //index of reg cache for current busrt 
  wire [4:0]    _fm_rd_data_grp; //0~9x2-1
  wire [4:0]    _fm_rd_data_data_x;
  wire [4:0]    _fm_rd_data_data_y;
  // rd_ddr_param
  wire          _fm_rd_param_full;
  wire [29:0]   _fm_rd_ker_ddr_addr;
  /*(*mark_debug="TRUE"*)*/wire          _fm_rd_param;
  wire          _fm_rd_param_ker_only;
  wire [29:0]   _fm_rd_param_addr;
  wire          _fm_rd_param_sw_on;
  wire          _fm_rd_param_valid;
  wire          _fm_rd_param_ker_valid_last;
  wire          _fm_rd_param_bias_valid;
  wire          _fm_rd_param_bias_valid_last;
  wire [511:0]  _fm_rd_param_data;
  wire          _fm_rd_param_ker0;
  wire          _fm_rd_param_ker1;
  //mem
  //mem_top
  wire [8:0]    _fm_rd_patch_ith_fm;
  wire [4:0]    _fm_rd_patch_x; //read bottom from patch_bram
  wire          _fm_rd_patch_x_eq_end;
  wire          _fm_rd_patch_y_eq_zero;
  wire          _fm_rd_patch_y_eq_end;
  wire          _fm_rd_patch_y_is_odd;
  
  // ddr input/output switch
  
  always@(posedge clk) begin
    fm_ddr_req <= _fm_ddr_req;
  end
  always@(_fm_rd_exp_sw_on or _fm_rd_data_sw_on or _fm_rd_param_sw_on or _fm_wr_data_sw_on or 
          _fm_rd_exp_ddr_addr or _fm_rd_data_ddr_addr or _fm_rd_param_ddr_addr or _fm_wr_data_ddr_addr or
          _fm_rd_exp_ddr_cmd or _fm_rd_data_ddr_cmd or _fm_rd_param_ddr_cmd or _fm_wr_data_ddr_cmd or
          _fm_rd_exp_ddr_en or _fm_rd_data_ddr_en or _fm_rd_param_ddr_en or _fm_wr_data_ddr_en ) 
  begin
    if(_fm_rd_exp_sw_on) begin
      ddr_addr  = _fm_rd_exp_ddr_addr;
      ddr_cmd   = _fm_rd_exp_ddr_cmd;
      ddr_en    = _fm_rd_exp_ddr_en;
    end else if(_fm_rd_data_sw_on) begin
      ddr_addr  = _fm_rd_data_ddr_addr;
      ddr_cmd   = _fm_rd_data_ddr_cmd;
      ddr_en    = _fm_rd_data_ddr_en;
    end else if(_fm_rd_param_sw_on) begin
      ddr_addr  = _fm_rd_param_ddr_addr;
      ddr_cmd   = _fm_rd_param_ddr_cmd;
      ddr_en    = _fm_rd_param_ddr_en;
    end else if(_fm_wr_data_sw_on) begin
      ddr_addr  = _fm_wr_data_ddr_addr;
      ddr_cmd   = _fm_wr_data_ddr_cmd;
      ddr_en    = _fm_wr_data_ddr_en;
    end else begin
      ddr_addr  = 30'h0;
      ddr_cmd   = 3'h0;
      ddr_en    = 1'b0;
    end
  end
 
  wire   _fm_conv_op_busy;
  assign _fm_conv_op_busy = (_fm_conv_busy || (_fm_conv_valid && (!_fm_conv_last_valid)));
  
  fsm fsm_u(
    .clk(clk),
    .rst_n(rst_n),
    .fsm_ddr_req(_fm_ddr_req),  // read ddr data request
    
    .fsm_data_ready(fm_data_ready), // bottom data and kernel data is ready on ddr
    .fsm_start(fm_start),  // conv layer operation start signal
    .fsm_done(fm_conv_done), // conv layer operation have finished, write data to ddr sdram
    //pooling
    //i
    .fsm_pooling_en(fm_pooling_en),
    .fsm_pooling_last_pos(_fm_pooling_last_pos),
    //conv_op
    //i
    .fsm_conv_start_at_next_clk(_fm_conv_start_at_next_clk),
    .fsm_conv_at_last_pos(_fm_conv_at_last_pos),
    .fsm_conv_busy(_fm_conv_op_busy),
    .fsm_conv_last_valid(_fm_conv_last_valid),
    //o
    .fsm_conv_start(_fm_conv_start),
    .fsm_conv_on_ker0(_fm_conv_ker0), //operate on ker0
    .fsm_conv_on_ker1(_fm_conv_ker1), //operate on ker1
    .fsm_conv_on_first_fm(_fm_conv_on_first_fm), //conv on first fm
    .fsm_conv_on_last_fm(_fm_conv_on_last_fm),  //conv on last fm
    .fsm_conv_cur_ker_num(_fm_conv_ker_num), //current operation output kernel num
    //wr_op
    //i
    .fsm_wr_data_done(_fm_wr_data_done), //wr operation done
    .fsm_last_layer(fm_last_layer),
    //o
    .fsm_wr_data_top(_fm_wr_data_top),  //start writing top data to ddr
    .fsm_wr_data_sw_on(_fm_wr_data_sw_on),
    .fsm_wr_data_x_eq_0(_fm_wr_data_x_eq_0),
    .fsm_wr_data_y_eq_0(_fm_wr_data_y_eq_0),
    .fsm_wr_data_x_eq_end(_fm_wr_data_x_eq_end),
    .fsm_wr_data_y_eq_end(_fm_wr_data_y_eq_end),
    //rd_ddr_data
    //i
    .fsm_rd_data_full(_fm_rd_data_full), //rd operation done
    .fsm_rd_data_bottom_channels(fm_bottom_channels),
    .fsm_rd_data_fm_width(fm_width),
    .fsm_rd_data_fm_height(fm_height),
    .fsm_rd_data_fm_size(fm_size),
    //o
    .fsm_rd_data_bottom(_fm_rd_data_bottom),   //start reading bottom data from ddr
    .fsm_rd_data_x(_fm_rd_data_x),
    .fsm_rd_data_y(_fm_rd_data_y),
    .fsm_rd_data_end_of_x(_fm_rd_data_end_of_x),
    .fsm_rd_data_end_of_y(_fm_rd_data_end_of_y),
    .fsm_rd_data_first_fm(_fm_rd_data_first_fm),
    .fsm_rd_data_ith_offset(_fm_rd_data_ith_offset),
    .fsm_rd_data_ith_fm(_fm_rd_data_ith_fm),
    .fsm_rd_data_sw_on(_fm_rd_data_sw_on),
    //rd_ddr_param
    //i
    .fsm_rd_param_full(_fm_rd_param_full),  //rd operation done
    .fsm_rd_param_ker_ddr_addr(fm_ker_ddr_addr),  // address of kernal data(skip bias)
    .fsm_rd_param_bias_num(fm_bias_num),  //number of top channels
    .fsm_rd_param_bias_offset(fm_bias_offset), //address occupied by bias data
    //o
    .fsm_rd_param(_fm_rd_param), //start reading param from ddr
    .fsm_rd_param_ker_only(_fm_rd_param_ker_only),
    .fsm_rd_param_addr(_fm_rd_param_addr),
    .fsm_rd_param_sw_on(_fm_rd_param_sw_on),
    .fsm_rd_param_ker0(_fm_rd_param_ker0),  //-->mem_ker
    .fsm_rd_param_ker1(_fm_rd_param_ker1),
    //rd_exp
    //i
    .fsm_rd_exp_full(_fm_rd_exp_full),  //rd operation done
    //o
    .fsm_rd_exp(_fm_rd_exp),  //start reading exp from ddr
    .fsm_rd_exp_sw_on(_fm_rd_exp_sw_on),
    //mem
    .fsm_rd_patch_ith_fm(_fm_rd_patch_ith_fm),
    .fsm_rd_patch_x(_fm_rd_patch_x),
    .fsm_rd_patch_x_eq_end(_fm_rd_patch_x_eq_end),
    .fsm_rd_patch_y_eq_zero(_fm_rd_patch_y_eq_zero),
    .fsm_rd_patch_y_eq_end(_fm_rd_patch_y_eq_end),
    .fsm_rd_patch_y_is_odd(_fm_rd_patch_y_is_odd)
  );

  conv_op #(
    .K_C(K_C), 
    .K_H(K_H), 
    .K_W(K_W),
    .DATA_WIDTH(DATA_WIDTH),
    .MID_WIDTH(MID_WIDTH) 
  )conv_op_u (
     .conv_rst_n(rst_n),
     .conv_clk(clk),
     //i
     .conv_start(_fm_conv_start),  // at current clock, last data is writen, convolution starts at next clock
//     .conv_ker_size(fm_ker_size),    //cnn kernal size:1 or 3 or 5.
     .conv_ker(_fm_conv_ker),    // shape: k_c k_h k_w
     .conv_bottom(_fm_conv_bottom), // shape: data_h data_w
     .conv_bottom_valid(_fm_conv_bottom_valid),
     .conv_partial_sum_valid(_fm_conv_op_partial_sum_valid), // partial sum data valid
     .conv_partial_sum(_fm_conv_op_partial_sum), // partial sum from output buffer (512x14x14)
     //o
     .conv_rd_data_partial_sum(_fm_conv_op_rd_partial_sum), // need to read partial sum data
     .conv_top(_fm_conv_op_top_o),    // shape: k_c, no output buffer reg
     .conv_first_pos(_fm_conv_start_at_next_clk), // conv started
     .conv_last_pos(_fm_conv_at_last_pos), // conv at the last position
     .conv_output_valid(_fm_conv_valid),
     .conv_output_last(_fm_conv_last_valid), // last output, convolution done
     .conv_x(_fm_conv_x),      
     .conv_y(_fm_conv_y),      
     .conv_to_x(_fm_to_conv_x),
     .conv_to_y(_fm_to_conv_y),
     .conv_rd_col(_fm_conv_rd_col),
     .conv_patch_bram_rd_en(_fm_patch_bram_rd_en),
     .conv_busy(_fm_conv_busy)
  );
  
  // write top to ddr
  wire _fm_wr_data_rd_top_buffer;
  wire _fm_wr_on_last_layer;
  wire _fm_wr_last_layer;
  reg  _fm_last_layer_reg;
  reg  _fm_last_layer_reg2;
  reg  _fm_last_layer;
  always@(posedge clk) begin
    _fm_last_layer_reg <= fm_last_layer;
    _fm_last_layer_reg2 <= _fm_last_layer_reg;
    _fm_last_layer  <= _fm_last_layer_reg2;
  end
  assign _fm_wr_last_layer = (_fm_last_layer && _fm_wr_on_last_layer);
  
  wr_ddr_data #(
    .FP_WIDTH(FP_WIDTH),
    .K_C(K_C)
  ) wr_ddr_data_u(
    .clk(clk),
    .rst_n(rst_n),
    //ddr interface
    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),
    .ddr_wdf_data(ddr_wdf_data),
    .ddr_wdf_mask(ddr_wdf_mask),
    .ddr_wdf_end(ddr_wdf_end),
    .ddr_wdf_wren(ddr_wdf_wren),
    .ddr_addr(_fm_wr_data_ddr_addr),
    .ddr_cmd(_fm_wr_data_ddr_cmd),
    .ddr_en(_fm_wr_data_ddr_en),
    //wr ctrl
    .wr_data_top(_fm_wr_data_top), // write top data enable
    .wr_data_top_addr(fm_top_ddr_addr), // writing address
    .wr_data_top_channels(fm_top_channels), // num of top data channels
    .wr_data_data_i(_fm_conv_top),
    .wr_data_x_eq_0(_fm_wr_data_x_eq_0),
    .wr_data_y_eq_0(_fm_wr_data_y_eq_0),
    .wr_data_x_eq_end(_fm_wr_data_x_eq_end),
    .wr_data_y_eq_end(_fm_wr_data_y_eq_end),
    .wr_data_pooling_en(fm_pooling_en), // is pooling layer output
    .wr_data_half_bar_size(fm_top_half_bar_size), // size of half bar
    .wr_data_fm_size(fm_top_fm_size),
    .wr_data_data_valid(_fm_top_data_valid), // <-x input port
    .wr_data_rd_top_buffer(_fm_wr_data_rd_top_buffer),
    .wr_data_next_quarter(_fm_wr_data_next_quarter), // <-x input port
    .wr_data_next_channel(_fm_wr_data_next_channel), // current channel finished, writing the last datum to ddr
    .wr_data_done(_fm_wr_data_done), // data writing done
    //last layer
    .wr_data_last_layer(_fm_wr_last_layer), // <-x input port
    .wr_data_llayer_i(_fm_wr_llayer_o),   // last
    .wr_data_cur_ker_set(_fm_wr_llayer_ker_set),
    .wr_data_llayer_data_valid(_fm_wr_llayer_valid), // <-x input port
    .wr_data_llayer_valid_first(_fm_wr_llayer_first_pos),
    .wr_data_llayer_valid_last(_fm_wr_llayer_last_pos), // <-x input port
    .wr_data_llayer_last_data(fm_llayer_last_data),
    .wr_data_bram_we(fm_llayer_bram_we), // <-x output port
    .wr_data_bram_addr(fm_llayer_bram_addr), // <-x output port
    .wr_data_llayer_o(fm_llayer_bram_o) // <-x output port
  );
  
  //read and update exp
  wire [3:0]  _rd_exp_ker_burst_num;
  wire        _rd_exp_ker_only;
  assign _rd_exp_ker_burst_num = fm_bias_ddr_burst_num >> 1;
  assign _rd_exp_ker_only      = (fm_bottom_channels != 10'd3);
//  assign _rd_exp_ker_only = 1'b0;
  rd_ddr_exp #(
    .DATA_WIDTH(DATA_WIDTH),
    .EXP_WIDTH(EXP_WIDTH) 
  )rd_ddr_exp_u(
     .clk(clk),
     .rst_n(rst_n),
     //ddr
     .ddr_rdy(ddr_rdy),
     .ddr_addr(_fm_rd_exp_ddr_addr),
     .ddr_cmd(_fm_rd_exp_ddr_cmd),
     .ddr_en(_fm_rd_exp_ddr_en),
     .ddr_rd_data(ddr_rd_data),
     .ddr_rd_data_valid(ddr_rd_data_valid),
     
     .rd_exp(_fm_rd_exp),
     .rd_exp_ker_burst_num(_rd_exp_ker_burst_num), // number of conv layer bias data, 8bits*512/512=8
     .rd_exp_ker_only(_rd_exp_ker_only), //valid except for conv1_1 layer
     .rd_exp_addr(fm_rd_exp_addr),
     .rd_exp_bottom_exp_in(_fm_rd_exp_bottom_exp_i), //max exp of bottom, input from wr_ddr_data
     .rd_exp_bottom_exp_in_valid(_fm_rd_exp_bottom_exp_i_valid),
     
     .rd_exp_bottom_exp(_fm_rd_exp_bottom_exp_o),
     .rd_exp_bottom_exp_valid(_fm_rd_exp_bottom_exp_o_valid),
     .rd_exp_bias_exp(_fm_rd_exp_bias_exp),
     .rd_exp_bias_valid(_fm_rd_bias_exp_valid),
     .rd_exp_bias_valid_last(_fm_rd_bias_exp_last),
     .rd_exp_full(_fm_rd_exp_full)
  );
  
  rd_ddr_data #(
    .FP_WIDTH(FP_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DDR_DATA_WIDTH(DDR_DATA_WIDTH),
    .DDR_BURST_LEN(DDR_BURST_LEN)
  )rd_ddr_data_u(
     .clk(clk),
     .rst_n(rst_n),
     //ddr
     .ddr_rdy(ddr_rdy),
     .ddr_addr(_fm_rd_data_ddr_addr),
     .ddr_cmd(_fm_rd_data_ddr_cmd),
     .ddr_en(_fm_rd_data_ddr_en),
     .input_exp(_fm_rd_exp_bottom_exp_o),
     .ddr_rd_data(ddr_rd_data),
     .ddr_rd_data_valid(ddr_rd_data_valid),
     //fsm
     //i
     .rd_data_bottom(_fm_rd_data_bottom),     // read bottom data enable
     .rd_data_bottom_addr(fm_bottom_ddr_addr),// read bottom data address, start address of bottom data
     .rd_data_end_of_x(_fm_rd_data_end_of_x),
     .rd_data_end_of_y(_fm_rd_data_end_of_y),
     .rd_data_x(_fm_rd_data_x),          // column index of the patch, stable till end
     .rd_data_y(_fm_rd_data_y),          // row index of the patch
     .rd_data_first_fm(_fm_rd_data_first_fm),   // first input feature map, update base address
     .rd_data_bottom_ith_offset(_fm_rd_data_ith_offset),  // ith bottom feature map size, stable till end
     .rd_data_bar_offset(fm_1bar_size), // 14*rd_data_max_x*float_num_width/ddr_data_width
     .rd_data_half_bar_offset(fm_half_bar_size), // 7*rd_data_max_x*float_num_width/ddr_data_width
//     .rd_data_cache_release_done(_fm_rd_data_cache_release_done), //finished release
      .rd_data_cache_full(_fm_rd_data_cache_full),
     //mem
     //o
     .rd_data_data(_fm_rd_data_data), // rearranged ddr data
//     .rd_data_cache_idx(_fm_rd_data_cache_idx),  //index of reg cache for current busrt 
     .rd_data_grp(_fm_rd_data_grp), //0~9x2-1
     .rd_data_valid(_fm_rd_data_valid),
     .rd_data_full(_fm_rd_data_full)
  );
  
  rd_ddr_param #(
    .FLOAT_NUM_WIDTH(FP_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DDR_DATA_WIDTH(DDR_DATA_WIDTH),
    .DDR_BURST_LEN(DDR_BURST_LEN),
    .K_C(K_C)  //ppmac kernal channels
  )rd_ddr_param_u(
     .clk(clk),
     .rst_n(rst_n),
     //ddr
     .ddr_rdy(ddr_rdy),
     .ddr_addr(_fm_rd_param_ddr_addr),
     .ddr_cmd(_fm_rd_param_ddr_cmd),
     .ddr_en(_fm_rd_param_ddr_en),
//     .ker_size, 
     .ddr_rd_data(ddr_rd_data),
     .ddr_rd_data_valid(ddr_rd_data_valid),
     
     .rd_param(_fm_rd_param),
     .rd_param_ker_only(_fm_rd_param_ker_only),
     .rd_param_bias_burst_num(fm_bias_ddr_burst_num), // number of conv layer bias data, 16bits*512/512=16
     .rd_param_addr(_fm_rd_param_addr),
     //mem
     .rd_param_data(_fm_rd_param_data),
     .rd_param_valid(_fm_rd_param_valid),
     .rd_param_bias_valid(_fm_rd_param_bias_valid), // bias valid if not read_kernel_only
     .rd_param_bias_valid_last(_fm_rd_param_bias_valid_last), // last valid bias data
     .rd_param_full(_fm_rd_param_full)
  );
    
  mem_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .EXP_WIDTH(EXP_WIDTH),
    .MID_WIDTH(MID_WIDTH),
    .FP_WIDTH(FP_WIDTH),
    .IM_C(8),
    .K_H(K_H),
    .K_W(K_W),
    .K_C(K_C)
 )mem_top_u(
    .clk(clk),
    .rst_n(rst_n),
//    .ker_size(fm_ker_size), //1 or 3 or 5
    //conv_op
    .mem_top_layer_index(fm_layer_index),
    .mem_top_data(_fm_conv_top), // top data to write to ddr
    .mem_top_partial_sum(_fm_conv_op_partial_sum),
    .mem_top_conv_data_i(_fm_conv_op_top_o), // conv_op module output
    .mem_top_rd_partial_sum(_fm_conv_op_rd_partial_sum), // from conv_op
    .mem_top_partial_sum_valid(_fm_conv_op_partial_sum_valid), // connect to conv_op
    .mem_top_conv_valid(_fm_conv_valid), // convolution data valid
    .mem_top_conv_x(_fm_conv_x), // output x position
    .mem_top_conv_y(_fm_conv_y), // output y position
    .mem_top_conv_to_x(_fm_to_conv_x),
    .mem_top_conv_to_y(_fm_to_conv_y),
    .mem_top_conv_rd_col(_fm_conv_rd_col),
    .mem_top_conv_on_first_fm(_fm_conv_on_first_fm), // convolve on first fm
    .mem_top_conv_on_last_fm(_fm_conv_on_last_fm),
    .mem_top_conv_cur_ker_set(_fm_conv_ker_num), // current convolutin kernel set
    .mem_top_conv_ker0(_fm_conv_ker0), // flags on convolution ker0
    .mem_top_conv_ker1(_fm_conv_ker1),
    //relu
    .mem_top_relu_en(fm_relu_en), //enable relu activation function
    //pooling
    .mem_top_pooling_en(fm_pooling_en),
    .mem_top_pooling_last_pos(_fm_pooling_last_pos),
    //wr_ddr_op
    .mem_top_wr_x_eq_end(_fm_wr_data_x_eq_end),
    .mem_top_wr_y_eq_end(_fm_wr_data_y_eq_end),
    .mem_top_wr_ddr_en(_fm_wr_data_top),
    .mem_top_wr_rd_top_buffer(_fm_wr_data_rd_top_buffer),
    .mem_top_wr_next_channel(_fm_wr_data_next_channel), // <-x from wr_ddr_op module
    .mem_top_wr_next_quarter(_fm_wr_data_next_quarter), // <-x from wr_ddr_op module
    .mem_top_wr_done(_fm_wr_data_done), // <-x from wr_ddr_op module
    .mem_top_wr_data_valid(_fm_top_data_valid), // <-x to wr_ddr_op module
    // last layer
    .mem_top_last_layer(_fm_last_layer),
    .mem_top_last_layer_on(_fm_wr_on_last_layer),
    .mem_top_last_layer_o(_fm_wr_llayer_o),
    .mem_top_last_layer_valid(_fm_wr_llayer_valid),
    .mem_top_last_layer_last_pos(_fm_wr_llayer_last_pos),
    .mem_top_last_layer_first_pos(_fm_wr_llayer_first_pos),
    .mem_top_last_layer_ker_set(_fm_wr_llayer_ker_set),
    //rd_data
    .mem_top_rd_ddr_data_i(_fm_rd_data_data),           // ddr bottom data burst
    .mem_top_rd_ddr_data_grp(_fm_rd_data_grp),
    .mem_top_rd_ddr_data_valid(_fm_rd_data_valid),      // ddr bottom data valid
    .mem_top_rd_ddr_data_x(_fm_rd_data_x),
    .mem_top_rd_ddr_data_y(_fm_rd_data_y),
    .mem_top_rd_ddr_data_ith_fm(_fm_rd_data_ith_fm),     //_ith_fm%8, i.e. _ith_fm && 3'd7
//    .mem_top_rd_ddr_data_bottom_fm_width(fm_bottom_width),
//    .mem_top_rd_ddr_data_cache_idx(_fm_rd_data_cache_idx),
//    .mem_top_rd_ddr_data_cache_done(_fm_rd_data_cache_release_done),
    .mem_top_rd_ddr_data_cache_full(_fm_rd_data_cache_full),
    //rd_patch_bram
    .mem_top_rd_patch_bram_en(_fm_patch_bram_rd_en),
    .mem_top_rd_patch_ith_fm(_fm_rd_patch_ith_fm),
    .mem_top_rd_patch_x(_fm_rd_patch_x),
    .mem_top_rd_patch_x_eq_end(_fm_rd_patch_x_eq_end),  //whether current CW is on the right side of fm.
    .mem_top_rd_patch_y_eq_zero(_fm_rd_patch_y_eq_zero),
    .mem_top_rd_patch_y_eq_end(_fm_rd_patch_y_eq_end),
    .mem_top_rd_patch_y_is_odd(_fm_rd_patch_y_is_odd),
    .mem_top_conv_bottom(_fm_conv_bottom),
    .mem_top_conv_bottom_valid(_fm_conv_bottom_valid),
    //rd_ker
    .mem_top_rd_ddr_param_i(_fm_rd_param_data),
    .mem_top_rd_ddr_ker_valid(_fm_rd_param_valid),
    .mem_top_rd_ddr_ker_valid_last(_fm_rd_param_full),
    .mem_top_rd_ddr_ker_ker0(_fm_rd_param_ker0),
    .mem_top_rd_ddr_ker_ker1(_fm_rd_param_ker1),
    .mem_top_conv_ker(_fm_conv_ker),
    //rd_bias
    .mem_top_rd_ddr_bias_valid(_fm_rd_param_bias_valid),
    .mem_top_rd_ddr_bias_valid_last(_fm_rd_param_bias_valid_last),
    //rd_exp
    .mem_top_rd_bias_exp(_fm_rd_exp_bias_exp),
    .mem_top_rd_bias_exp_valid(_fm_rd_bias_exp_valid),
    .mem_top_rd_bias_exp_last(_fm_rd_bias_exp_last),
    .mem_top_fm_max_exp_i_valid(_fm_rd_exp_bottom_exp_o_valid), //flag of a new layer start
    .mem_top_fm_max_exp_o(_fm_rd_exp_bottom_exp_i),
    .mem_top_fm_max_exp_o_valid(_fm_rd_exp_bottom_exp_i_valid)
 );
  
endmodule
