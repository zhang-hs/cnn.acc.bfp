`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/08/31 10:44:59
// Module Name: mem_top
// Module Name: rd_ddr_param
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: Top module of cache units. 
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//`define sim_

module mem_top #(
  parameter DATA_WIDTH    = 8,
  parameter EXP_WIDTH     = 5,
  parameter MID_WIDTH     = 29,
  parameter FP_WIDTH      = 16,
  parameter IM_C          = 8,  //bram channels
  parameter K_H           = 3, //ppmac kernel height
  parameter K_W           = 3, //ppmac kernel width
  parameter K_C           = 64 //ppmac kernel channels 
)(
//`ifdef sim_
//// -------------------- simulation --------------------{{{
//  input  wire                                                             mem_top_cmp_result_en,
//  input  wire                                                             mem_top_cmp_top,
//  output wire[16*DATA_WIDTH-1:0]                                          mem_top_rd_proc_ram,
//  output reg [K_C*K_H*K_W*DATA_WIDTH-1:0]                                 mem_top_rd_ker,
//  output wire[512*FP_WIDTH-1:0]                                           mem_top_bias_fp,
//  output wire[512*32-1:0]                                                 mem_top_bias,
//  output wire[512*8-1:0]                                                  mem_top_bias_exp,
//// -------------------- simulation --------------------}}}
//`endif
  input  wire                                                             clk,
  input  wire                                                             rst_n,
//  input  wire [2:0]                                                       ker_size, //1 or 3 or 5
  //conv_op: (fsm)
  input  wire[4:0]                                                        mem_top_layer_index,
  output wire[7*7*FP_WIDTH-1:0]                                           mem_top_data,  // top data, connect to wr_op   <-XXXXXXXXXXXXX
  output wire[K_C*MID_WIDTH-1:0]                                          mem_top_partial_sum, // (partial summation of mem_data) or (bias data)
  input  wire[K_C*MID_WIDTH-1:0]                                          mem_top_conv_data_i, // convolution results   <-XXXXXXXXXXXXX
  input  wire                                                             mem_top_rd_partial_sum,
  output wire                                                             mem_top_partial_sum_valid,
  input  wire                                                             mem_top_conv_valid, // convolution output valid  
  input  wire[3:0]                                                        mem_top_conv_x, // convolution output x position, for write
  input  wire[3:0]                                                        mem_top_conv_y, // convolution output x position, for write
  input  wire[3:0]                                                        mem_top_conv_to_x, // to convolve at posX, for read
  input  wire[3:0]                                                        mem_top_conv_to_y, // to convolve at posY, for read
  input  wire[4:0]                                                        mem_top_conv_rd_col,
  input  wire                                                             mem_top_conv_on_first_fm, // current convolving on first fm
  input  wire                                                             mem_top_conv_on_last_fm, // current convolving on last fm
  input  wire[9:0]                                                        mem_top_conv_cur_ker_set, // current convolution kernel set
  input  wire                                                             mem_top_conv_ker0, // flags on convolution ker0
  input  wire                                                             mem_top_conv_ker1,
  // relu
  input  wire                                                             mem_top_relu_en, // enable ReLU
  // pooling (with relu)
  input  wire                                                             mem_top_pooling_en, // enable pooling
  output wire                                                             mem_top_pooling_last_pos, // last pooling position
  // wr_ddr_op
  input  wire                                                             mem_top_wr_x_eq_end,
  input  wire                                                             mem_top_wr_y_eq_end,
  input  wire                                                             mem_top_wr_ddr_en, // write data to ddr
  input  wire                                                             mem_top_wr_rd_top_buffer,
  input  wire                                                             mem_top_wr_next_channel, // next channel of convolution result, wr_ddr_op module is writing the last data in current channel
  input  wire                                                             mem_top_wr_next_quarter, // next quart of convolution output buffer
  input  wire                                                             mem_top_wr_done, // writing operation finished
  output wire                                                             mem_top_wr_data_valid, // output buffer data valid
  // last layer
  input  wire                                                             mem_top_last_layer,
  output wire                                                             mem_top_last_layer_on,
  output wire[FP_WIDTH*K_C-1:0]                                           mem_top_last_layer_o,
  output wire                                                             mem_top_last_layer_valid,
  output wire                                                             mem_top_last_layer_last_pos,
  output wire                                                             mem_top_last_layer_first_pos,
  output wire[3:0]                                                        mem_top_last_layer_ker_set,
  //rd_data:
  input  wire [255:0]                                                     mem_top_rd_ddr_data_i,           // ddr bottom data burst
  input  wire [4:0]                                                       mem_top_rd_ddr_data_grp,
  input  wire                                                             mem_top_rd_ddr_data_valid,      // ddr bottom data valid
  input  wire [4:0]                                                       mem_top_rd_ddr_data_x,
  input  wire [4:0]                                                       mem_top_rd_ddr_data_y,
  input  wire [8:0]                                                       mem_top_rd_ddr_data_ith_fm,     //_ith_fm%8, i.e. _ith_fm && 3'd7
//  input  wire [7:0]                                                       mem_top_rd_ddr_data_bottom_fm_width,
//  input  wire                                                             mem_top_rd_ddr_data_cache_idx,
//  output wire                                                             mem_top_rd_ddr_data_cache_done,
  output wire                                                             mem_top_rd_ddr_data_cache_full,
  //mem_patch_rd:
//  input  wire                                                             mem_top_conv_start,
//  input  wire                                                             mem_top_conv_busy,
  input  wire                                                             mem_top_rd_patch_bram_en,
  input  wire [8:0]                                                       mem_top_rd_patch_ith_fm,
  input  wire [4:0]                                                       mem_top_rd_patch_x,
  input  wire                                                             mem_top_rd_patch_x_eq_end,  //whether current CW is on the right side of fm.
  input  wire                                                             mem_top_rd_patch_y_eq_zero,
  input  wire                                                             mem_top_rd_patch_y_eq_end,
  input  wire                                                             mem_top_rd_patch_y_is_odd,
  
//  output wire [18*DATA_WIDTH-1:0]                                         mem_top_conv_bottom,   // bottom data, connect to conv_op
  output wire [16*DATA_WIDTH-1:0]                                         mem_top_conv_bottom, //for debug
  output wire                                                             mem_top_conv_bottom_valid,
  //rd_ker:
  input  wire [511:0]                                                     mem_top_rd_ddr_param_i,
  input  wire                                                             mem_top_rd_ddr_ker_valid,
  input  wire                                                             mem_top_rd_ddr_ker_valid_last,
  input  wire                                                             mem_top_rd_ddr_ker_ker0,
  input  wire                                                             mem_top_rd_ddr_ker_ker1,
  output wire [K_H*K_W*K_C*DATA_WIDTH-1:0]                                mem_top_conv_ker, // kernel weight, connect to conv_op
  //rd_bias: (rd_ddr_param,mem_data)
  input  wire                                                             mem_top_rd_ddr_bias_valid,
  input  wire                                                             mem_top_rd_ddr_bias_valid_last,
  //rd_exp
  input  wire [K_C*(EXP_WIDTH+1)-1:0]                                     mem_top_rd_bias_exp,
  input  wire                                                             mem_top_rd_bias_exp_valid,
  input  wire                                                             mem_top_rd_bias_exp_last,
//  input  wire [EXP_WIDTH-1:0]                                             mem_top_fm_max_exp_i,
  input  wire                                                             mem_top_fm_max_exp_i_valid, //flag of a new layer start
  output wire [EXP_WIDTH-1:0]                                             mem_top_fm_max_exp_o,
  output wire                                                             mem_top_fm_max_exp_o_valid
);
  //top
  mem_data #(
    .DATA_WIDTH(DATA_WIDTH),
    .EXP_WIDTH(EXP_WIDTH),
    .FP_WIDTH(FP_WIDTH),
    .MID_WIDTH(MID_WIDTH),
    .K_C(K_C)
  )mem_data_u(
//  `ifdef sim_ // {{{
//    .mem_bias_fp(mem_top_bias_fp),
//    .mem_bias(mem_top_bias),
//    .mem_bias_exp(mem_top_bias_exp),
//    .mem_cmp_result(mem_top_cmp_result_en),
//    .mem_cmp_top(mem_top_cmp_top),
//  `endif //}}}
    .clk(clk),
    .rst_n(rst_n),
    //bias_interface
    .mem_bias_exp_valid(mem_top_rd_bias_exp_valid),
    .mem_bias_exp_last(mem_top_rd_bias_exp_last),
    .mem_bias_exp_i(mem_top_rd_bias_exp),
    .mem_bias_valid(mem_top_rd_ddr_bias_valid),     // bias data valid
    .mem_bias_last(mem_top_rd_ddr_bias_valid_last),      // last bias data burst
    .mem_bias_i(mem_top_rd_ddr_param_i),         // bias data
    //update max_exp of fm,after current layer's top data are witten to ddr 
//    .mem_fm_max_exp_i(mem_top_fm_max_exp_i), //max_exp of cur_layer's bottom
    .mem_fm_max_exp_i_valid(mem_top_fm_max_exp_i_valid),  //flag of a new layer starts
    .mem_fm_max_exp_o(mem_top_fm_max_exp_o), //max_exp of cur_layer's top
    .mem_fm_max_exp_o_valid(mem_top_fm_max_exp_o_valid),
    // bias interface
    .mem_data_cur_on_first_fm(mem_top_conv_on_first_fm), // operate on first fm, need to add bias when convolve on first fm
    .mem_data_relu_en(mem_top_relu_en), // activiation function
    //pooling interface
    .mem_data_pooling_en(mem_top_pooling_en), // current layer should be subsampled
    .mem_data_last_fm(mem_top_conv_on_last_fm), // convolving on last fm
    .mem_data_pooling_last_pos(mem_top_pooling_last_pos), // last valid pooling data will be written
    //conv interface
    .mem_data_cur_ker_set(mem_top_conv_cur_ker_set), // current convolution kernel set
    .mem_data_conv_x(mem_top_conv_x),  // convolution output x position
    .mem_data_conv_y(mem_top_conv_y),  // convolution output y position
    .mem_data_to_conv_x(mem_top_conv_to_x), // to convolve at posX
    .mem_data_to_conv_y(mem_top_conv_to_y), // to convolve at posY
    .mem_data_conv_rd_partial_sum(mem_top_rd_partial_sum), // read partial sum, should be synchronized with _to_conv_x/y
    .mem_data_conv_partial_sum_valid(mem_top_partial_sum_valid), // partial sum data valid
    .mem_data_conv_valid(mem_top_conv_valid), // convolution output valid
    .mem_data_conv_data_i(mem_top_conv_data_i), // convolution output (+bias, if needed), 1x32
    .mem_data_conv_partial_sum(mem_top_partial_sum), // partial summation
    //wr interface
    .mem_data_wr_x_eq_end(mem_top_wr_x_eq_end),
    .mem_data_wr_y_eq_end(mem_top_wr_y_eq_end),
    .mem_data_wr_next_channel(mem_top_wr_next_channel), // next channel of convolution result, wr_ddr_op module is writing the last data in current channel
    .mem_data_wr_data_re(mem_top_wr_ddr_en), // write data to ddr enable, from fsm
    .mem_data_rd_buffer(mem_top_wr_rd_top_buffer),
    .mem_data_wr_next_quarter(mem_top_wr_next_quarter), // next quarter of convolution result
    .mem_data_wr_data_valid(mem_top_wr_data_valid), // next quarter of convolution result
    .mem_data_wr_done(mem_top_wr_done), // writing operation finished, one 14*14 or 7*7 top fm tile of all output channels
    .mem_data_data(mem_top_data), // data to write into ddr
    //last layer
    .mem_data_last_layer(mem_top_last_layer),
    .mem_data_last_layer_on(mem_top_last_layer_on), // on last layer
    .mem_data_conv_data_last_layer_o(mem_top_last_layer_o),
    .mem_data_last_layer_valid(mem_top_last_layer_valid),
    .mem_data_last_layer_last_pos(mem_top_last_layer_last_pos),
    .mem_data_last_layer_first_pos(mem_top_last_layer_first_pos),
    .mem_data_last_layer_ker_set(mem_top_last_layer_ker_set)
  );
  
  //mem_patch_bram_wr_ctrl
  wire [IM_C-1:0]                       _patch_bram_wr_ith_valid;
  wire [DATA_WIDTH*7-1:0]               _patch_bram_in;
  wire [4:0]                            _patch_bram_wr_en; //{a_upper, a, b, c_upper, c}
  wire [10:0]                           _patch_bram_wr_addr; //0~1792-1
  mem_patch_update #(
   .DATA_WIDTH(DATA_WIDTH),
   .IM_C(IM_C)
  )mem_patch_update_u(   
   .clk(clk),
   .rst_n(rst_n),
   //rd_ddr_data
   .mem_patch_layer_index(mem_top_layer_index),
   .mem_patch_ddr_i(mem_top_rd_ddr_data_i),
   .mem_patch_ddr_grp(mem_top_rd_ddr_data_grp),
   .mem_patch_ddr_valid(mem_top_rd_ddr_data_valid),
   .mem_patch_x(mem_top_rd_ddr_data_x),
   .mem_patch_y(mem_top_rd_ddr_data_y),
   .mem_patch_ith_fm(mem_top_rd_ddr_data_ith_fm),
//   .mem_patch_bottom_fm_width(mem_top_rd_ddr_data_bottom_fm_width),
//   .mem_patch_cache_idx(mem_top_rd_ddr_data_cache_idx),
//   .mem_patch_bram_done(mem_top_rd_ddr_data_cache_done),  // --> rd_ddr_data
   .mem_patch_cache_full(mem_top_rd_ddr_data_cache_full),
   //bram_wr_options
   .mem_patch_bram_ith_valid(_patch_bram_wr_ith_valid),
   .mem_patch_bram_o(_patch_bram_in),
   .mem_patch_bram_en(_patch_bram_wr_en),
   .mem_patch_bram_addr(_patch_bram_wr_addr)
  );
  
 //mem_patch_bram_rd_ctrl 
   wire                                  _patch_bram_rd_y_eq_zero;
   wire                                  _patch_bram_rd_y_eq_end;                 
   wire                                  _patch_bram_rd_y_is_odd;
   wire [IM_C-1:0]                       _patch_bram_rd_ith_valid;
   wire [2:0]                            _patch_bram_rd_ith;
   wire [10:0]                           _patch_bram_rd_addr;
   wire [18*DATA_WIDTH-1:0]              _patch_bram_o; 
   wire [18*DATA_WIDTH-1:0]              _mem_top_conv_bottom;
   assign mem_top_conv_bottom = _mem_top_conv_bottom[DATA_WIDTH*17-1:DATA_WIDTH*1]; //for debug
  mem_patch_rd #(
    .DATA_WIDTH(DATA_WIDTH),
    .IM_C(IM_C)
  )mem_patch_rd_u(
    .clk(clk),
    .rst_n(rst_n),
//    .ker_size(ker_size),
    
//    .mem_patch_rd_conv_start(mem_top_conv_start), //start reading
//    .mem_patch_rd_conv_busy(mem_top_conv_busy),
.mem_patch_rd_layer_index(mem_top_layer_index),
    .mem_patch_rd_en(mem_top_rd_patch_bram_en),
    .mem_patch_rd_ith_fm(mem_top_rd_patch_ith_fm),
    .mem_patch_rd_x(mem_top_rd_patch_x),
    .mem_patch_rd_x_eq_end(mem_top_rd_patch_x_eq_end),
    .mem_patch_rd_y_eq_zero(mem_top_rd_patch_y_eq_zero),
    .mem_patch_rd_y_eq_end(mem_top_rd_patch_y_eq_end),
    .mem_patch_rd_y_is_odd(mem_top_rd_patch_y_is_odd),
//    .mem_patch_rd_bottom_fm_width(mem_top_rd_ddr_data_bottom_fm_width),
    .mem_patch_rd_col(mem_top_conv_rd_col), //addr_offset
    .mem_patch_rd_bram_o(_patch_bram_o),
                     
    .mem_patch_rd_ith_valid(_patch_bram_rd_ith_valid),
    .mem_patch_rd_ith(_patch_bram_rd_ith),
    .mem_patch_rd_addr(_patch_bram_rd_addr),
    .mem_patch_rd_y_eq_zero_valid(_patch_bram_rd_y_eq_zero), 
    .mem_patch_rd_y_eq_end_valid(_patch_bram_rd_y_eq_end), 
    .mem_patch_rd_y_is_odd_valid(_patch_bram_rd_y_is_odd),
    .mem_patch_rd_o(_mem_top_conv_bottom),
    .mem_patch_rd_o_valid(mem_top_conv_bottom_valid)                    
  );
  
  //mem_patch_bram
  mem_patch_bram #(
    .DATA_WIDTH(DATA_WIDTH),
    .IM_C(IM_C)
  ) mem_patch_bram_u(
    .clk(clk),
    //wr options
    .mem_patch_bram_wr_ith_valid(_patch_bram_wr_ith_valid),
    .mem_patch_bram_in(_patch_bram_in),
    .mem_patch_bram_wr_en(_patch_bram_wr_en),
    .mem_patch_bram_wr_addr(_patch_bram_wr_addr),
    //rd options
    .mem_patch_bram_rd_ith_valid(_patch_bram_rd_ith_valid),
    .mem_patch_bram_rd_ith(_patch_bram_rd_ith),
    .mem_patch_bram_rd_y_eq_zero(_patch_bram_rd_y_eq_zero),
    .mem_patch_bram_rd_y_eq_end(_patch_bram_rd_y_eq_end),
    .mem_patch_bram_rd_y_is_odd(_patch_bram_rd_y_is_odd),
    .mem_patch_bram_rd_addr(_patch_bram_rd_addr), //1792
    .mem_patch_bram_o(_patch_bram_o)
  );
  
  //kernal memory
  wire[K_C*K_H*K_W*DATA_WIDTH-1:0]  _top_ker0;
  wire[K_C*K_H*K_W*DATA_WIDTH-1:0]  _top_ker1;
  wire _ker0_valid;  // kernel set 0 weight valid
  wire _ker0_last;
  wire _ker1_valid; // kernel set 1 weight valid
  wire _ker1_last;
  assign mem_top_conv_ker    = mem_top_conv_ker0 ? _top_ker0 : (mem_top_conv_ker1 ? _top_ker1 : {(K_C*K_H*K_W*DATA_WIDTH){1'b0}});
  assign _ker0_valid  = (mem_top_rd_ddr_ker_ker0 && mem_top_rd_ddr_ker_valid && (!mem_top_rd_ddr_bias_valid));
  assign _ker0_last   = (mem_top_rd_ddr_ker_ker0 && mem_top_rd_ddr_ker_valid_last);
  assign _ker1_valid  = (mem_top_rd_ddr_ker_ker1 && mem_top_rd_ddr_ker_valid && (!mem_top_rd_ddr_bias_valid));
  assign _ker1_last   = (mem_top_rd_ddr_ker_ker1 && mem_top_rd_ddr_ker_valid_last);
  
  //set 0
  mem_ker#(
    .DATA_WIDTH(DATA_WIDTH),
    .K_H(K_H),
    .K_W(K_W),
    .K_C(K_C)
  ) mem_ker0 (
    .clk(clk),
    .rst_n(rst_n),
    .mem_ker_valid(_ker0_valid),
    .mem_ker_last(_ker0_last),
    .mem_ker_i(mem_top_rd_ddr_param_i),
    .mem_ker_o(_top_ker0)
  );
  //set 1
  mem_ker#(
    .DATA_WIDTH(DATA_WIDTH),
    .K_H(K_H),
    .K_W(K_W),
    .K_C(K_C)
  ) mem_ker1 (
    .clk(clk),
    .rst_n(rst_n),
    .mem_ker_valid(_ker1_valid),
    .mem_ker_last(_ker1_last),
    .mem_ker_i(mem_top_rd_ddr_param_i),
    .mem_ker_o(_top_ker1)
  ); 
//  //register for one clk
//  reg           _ker0_param_valid;
//  reg           _ker0_param_last;
//  reg           _ker1_param_valid;
//  reg           _ker1_param_last;
//  reg [511:0]   _rd_ddr_param_i;
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _ker0_param_valid <= 1'b0;
//      _ker0_param_last <= 1'b0;
//      _ker1_param_valid <= 1'b0;
//      _ker1_param_last <= 1'b0;
//    end else begin
//      _ker0_param_valid <= _ker0_valid;
//      _ker0_param_last  <= _ker0_last; 
//      _ker1_param_valid <= _ker1_valid;
//      _ker1_param_last  <= _ker1_last;   
//    end
//  end
//  always@(posedge clk) begin
//    _rd_ddr_param_i <= mem_top_rd_ddr_param_i;
//  end
  
//  //set 0
//  mem_ker#(
//    .DATA_WIDTH(DATA_WIDTH),
//    .K_H(K_H),
//    .K_W(K_W),
//    .K_C(K_C)
//  ) mem_ker0 (
//    .clk(clk),
//    .rst_n(rst_n),
//    .mem_ker_valid(_ker0_param_valid),
//    .mem_ker_last(_ker0_param_last),
//    .mem_ker_i(_rd_ddr_param_i),
//    .mem_ker_o(_top_ker0)
//  );
//  //set 1
//  mem_ker#(
//    .DATA_WIDTH(DATA_WIDTH),
//    .K_H(K_H),
//    .K_W(K_W),
//    .K_C(K_C)
//  ) mem_ker1 (
//    .clk(clk),
//    .rst_n(rst_n),
//    .mem_ker_valid(_ker1_param_valid),
//    .mem_ker_last(_ker1_param_last),
//    .mem_ker_i(_rd_ddr_param_i),
//    .mem_ker_o(_top_ker1)
//  );

  
//`ifdef sim_
//  assign mem_top_rd_proc_ram = mem_top_conv_bottom;
  
//  reg _top_ker0_valid;
//  reg _top_ker1_valid;
//  always@(posedge clk) begin
//    _top_ker0_valid <= _ker0_valid;
//    _top_ker1_valid <= _ker1_valid;
//  end
//  always@(posedge clk) begin
//    if(_top_ker0_valid) begin
//      mem_top_rd_ker <= _top_ker0;
//    end else if(_top_ker1_valid) begin
//      mem_top_rd_ker <= _top_ker1;  
//    end
//  end
//`endif

endmodule
