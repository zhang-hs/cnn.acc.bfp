`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/11 14:57:44
// Module Name: mem_data
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vviado 2018.1
// Description: partial convolution result storage module,
//              convolution result of current ker_set,
//              asynchronous read
//              merged with mem_bias -- 1.1
//              merged with pooling -- 1.2
//              output with bias checked -- 1.3
//              check relu -- 1.4
//              bias connects to partial_sum -- 1.5
//              connect with ofbuf.v -- 1.6
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//`define sim_
 
// drirectC simulation {{{
`define TOPCHANNEL 512
`define END_X 0
`define END_Y 0
`ifdef sim_
  extern pointer  getFileDescriptor(input string fileName); //open for read
  extern pointer  wrFileDescriptor(input string fileName); //open for write
  extern void     write2File(input pointer fileDescriptor, input bit wrEnable, input bit PoolEn, input bit[8:0] posX, input bit[8:0] posY,
                             input bit[1:0] quarterIdx, input bit[9:0] channelIdx, input bit[7*7*16-1:0] wrData);
  extern void     write2FileFixed29(input pointer fileDescriptor, input bit wrEnable, input bit PoolEn, input bit[8:0] posX, input bit[8:0] posY,
                                    input bit[1:0] quarterIdx, input bit[9:0] channelIdx, input bit[7*7*32-1:0] wrData);    
  extern void     write2FileExp5(input pointer fileDescriptor, input bit wrEnable, input bit PoolEn, input bit[8:0] posX, input bit[8:0] posY,
                                 input bit[1:0] quarterIdx, input bit[9:0] channelIdx, input bit[8-1:0] wrData);
  extern void     closeFile(input pointer fileDescriptor);
  extern bit      cmpTop(input bit cmpTopEn, input bit cmpPoolEn, input pointer fileDescriptor, input bit[8:0] posX,
                          input bit[8:0] posY, input bit[`TOPCHANNEL*14*14*32-1:0] verilogTopResult, inout bit[31:0] maxError);
  extern bit      cmp7x7output(input bit cmp7x7En, input bit cmpPoolEn, input pointer fileDescriptor, input bit[8:0] posX,
                          input bit[8:0] posY, input bit[1:0] quarterIdx, input bit[9:0] channelIdx, input bit[7*7*16-1:0] verilogOutputData, input bit[7*7*5-1:0] verilogOutputDataExp);
  extern bit      cmp7x7output_bfp(input bit cmp7x7En, input bit cmpPoolEn, input pointer fileDescriptor, input bit[8:0] posX,
                               input bit[8:0] posY, input bit[1:0] quarterIdx, input bit[9:0] channelIdx, input bit[7*7*16-1:0] verilogOutputData);
`endif //}}}
module mem_data #(
  parameter DATA_WIDTH  = 8,
  parameter EXP_WIDTH   = 5,
  parameter FP_WIDTH    = 16,
  parameter MID_WIDTH   = 29,
  parameter K_C         = 64
)(
`ifdef sim_ // {{{
  input  wire                                                             mem_cmp_result, // compare convolution result
  input  wire                                                             mem_cmp_top,
  output wire[512*FP_WIDTH-1:0]                                           mem_bias_fp,
  output wire[512*32-1:0]                                                 mem_bias,
  output wire[512*8-1:0]                                                  mem_bias_exp,                   
`endif // }}}
  input  wire                                                             clk,
  input  wire                                                             rst_n,
  // bias interface
  input  wire                                                             mem_bias_exp_valid,
  input  wire                                                             mem_bias_exp_last,
  input  wire[(EXP_WIDTH+1)*64-1:0]                                       mem_bias_exp_i,
  input  wire                                                             mem_bias_valid,     // bias data valid
  input  wire                                                             mem_bias_last,      // last bias data burst
  input  wire[511:0]                                                      mem_bias_i,         // bias data
  //update max_exp of fm
//  input  wire[EXP_WIDTH-1:0]                                              mem_fm_max_exp_i, //max_exp of cur_layer's bottom
  input  wire                                                             mem_fm_max_exp_i_valid, //flag of a new layer start
  output wire[EXP_WIDTH-1:0]                                              mem_fm_max_exp_o, //max_exp of cur_layer's top
  output wire                                                             mem_fm_max_exp_o_valid,
  // bias interface
  input  wire                                                             mem_data_cur_on_first_fm, // operate on first fm, need to add bias when convolve on first fm
  input  wire                                                             mem_data_relu_en, // activiation function
  // pooling interface
  input  wire                                                             mem_data_pooling_en, // current layer should be subsampled
  input  wire                                                             mem_data_last_fm, // convolving on last fm
  output wire                                                             mem_data_pooling_last_pos, // last valid pooling data will be written
  //conv interface
  input  wire[9:0]                                                        mem_data_cur_ker_set, // current convolution kernel set, used to select data address, remain stable untill the end of pooling operation
  input  wire[3:0]                                                        mem_data_conv_x,  // convolution output x position, used to select data address, valid on conv_valid, otherwise, it should be zero
  input  wire[3:0]                                                        mem_data_conv_y,  // convolution output y position, used to select data address
  input  wire[3:0]                                                        mem_data_to_conv_x, // to convolve at posX
  input  wire[3:0]                                                        mem_data_to_conv_y, // to convolve at posY
  input  wire                                                             mem_data_conv_rd_partial_sum, // read partial sum, should be synchronized with _to_conv_x/y
  output wire                                                             mem_data_conv_partial_sum_valid, // partial sum data valid
  input  wire                                                             mem_data_conv_valid, // convolution output valid
  input  wire[MID_WIDTH*K_C-1:0]                                          mem_data_conv_data_i, // convolution output (+bias, if needed), 1x32
  output wire[MID_WIDTH*K_C-1:0]                                          mem_data_conv_partial_sum, // partial summation
  //input  wire                                                             mem_data_wr_to_fc_bram, // write output to fully connected layer bram buffer
  //input  wire                                                             mem_data_wr_to_ddr, // write output data to ddr
  //wr top tiles to ddr
  input  wire                                                             mem_data_wr_x_eq_end,
  input  wire                                                             mem_data_wr_y_eq_end,
  input  wire                                                             mem_data_wr_next_channel, // next channel of convolution result, wr_ddr_op module is writing the last data in current channel
  input  wire                                                             mem_data_wr_data_re, // write data to ddr enable, from fsm
  input  wire                                                             mem_data_rd_buffer,
  input  wire                                                             mem_data_wr_next_quarter, // next quarter of convolution result
  output reg                                                              mem_data_wr_data_valid, // next quarter of convolution result
  input  wire                                                             mem_data_wr_done, // writing operation finished, one 14*14 or 7*7 top fm tile of all output channels
  output wire[7*7*FP_WIDTH-1:0]                                           mem_data_data, // data to write into ddr
  // last layer
  input  wire                                                             mem_data_last_layer,
  output reg [K_C*FP_WIDTH-1:0]                                           mem_data_conv_data_last_layer_o,
  output reg                                                              mem_data_last_layer_valid,
  output reg                                                              mem_data_last_layer_last_pos,
  output reg                                                              mem_data_last_layer_first_pos,
  output reg                                                              mem_data_last_layer_on, // on last layer
  output reg [3:0]                                                        mem_data_last_layer_ker_set
  );
  
  localparam MAX_O_CHANNELS = 512;
  localparam DDR_BURST_DATA_WIDTH = 512;
  localparam NUM_OF_BIAS_IN_1_BURST = DDR_BURST_DATA_WIDTH / FP_WIDTH; //512/16=32
  localparam NUM_OF_BIAS_EXP_IN_1_BURST = DDR_BURST_DATA_WIDTH/8;
  
  reg  [5:0]                              _mem_data_channel_idx; // channel index,0~63
  reg  [1:0]                              _mem_data_quar_num; // index of 4 14x14 quarter
  wire [3:0]                              _mem_data_rd_x;   // partial sum reading position
  wire [3:0]                              _mem_data_rd_y;
  reg  [1:0]                              _mem_data_output_mode; // conv., pooling, buffer output
  // kernel set
  reg  [2:0]                              _mem_data_ofmem_portion; // 0~7
  wire [2:0]                              _mem_data_ker_set; // 0~7
  wire                                    _mem_data_conv_rd_valid;
  wire                                    _mem_data_wr_en; // buffer write enable
  // bias buffer
  wire [K_C*MID_WIDTH-1 : 0]              _mem_data_bias_data;// bias data to add
  wire [K_C*MID_WIDTH-1 : 0]              _mem_data_pre_data; // previous summation result
  reg  [9:0]                              _mem_data_cur_ker_set;
  // pooling
  wire [MID_WIDTH*K_C-1:0]                _mem_data_pooling_o; // pooling result
  wire [MID_WIDTH*K_C-1:0]                _mem_data_max_op2; // 2nd operand of 1x32_max
  reg  [MID_WIDTH*K_C-1:0]                _mem_data_max_reg;
  wire [MID_WIDTH*K_C-1:0]                _mem_data_max_o;
  reg  [3:0]                              _mem_data_pooling_x;
  reg  [3:0]                              _mem_data_pooling_y;
  reg  [3:0]                              _mem_data_pooling_rd_x;
  wire                                    _mem_data_pooling_we;
  wire                                    _mem_data_pooling_re;
  wire                                    _mem_data_conv_we;
  wire [3:0]                              _mem_data_wr_x;
  wire [3:0]                              _mem_data_wr_y;
  // last layer
  wire                                    _mem_data_pooling_first_pos;
  // wr to ddr
  wire [7*7*MID_WIDTH-1:0]                _mem_data_data;
  wire                                    _mem_data_wr_data_valid;
  //update fm exp
  wire [7*7*EXP_WIDTH-1:0]                _mem_data_data_exp;
  wire [EXP_WIDTH-1:0]                    _mem_data_data_exp_max;
  reg  [EXP_WIDTH-1:0]                    _mem_fm_max_exp_o;
//  reg                                     _mem_fm_max_exp_o_valid;
  
  assign mem_data_conv_partial_sum  = mem_data_cur_on_first_fm ? _mem_data_bias_data : _mem_data_pre_data;

  //--------------------------------bias----------------------------------
  reg  [EXP_WIDTH:0]          _mem_bias_exp[0:MAX_O_CHANNELS-1]; ////increase 1bit to prevent upward overflow,has an offset of 30
  reg  [9:0]                  _mem_bias_exp_offset;

  always@(posedge clk) begin
    _mem_data_cur_ker_set <= mem_data_cur_ker_set;
  end
  
  //bias exp memory address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_bias_exp_offset <= 10'h0;
    end else begin
      if(mem_bias_exp_valid) begin
        _mem_bias_exp_offset <= _mem_bias_exp_offset + NUM_OF_BIAS_EXP_IN_1_BURST; //from 0 to 512, stride is 64
      end
      if(mem_bias_exp_last) begin
        _mem_bias_exp_offset <= 10'h0;
      end
    end
  end

  //storage bias_exp
  always@(posedge clk) begin
    if(mem_bias_exp_valid) begin
    _mem_bias_exp[_mem_bias_exp_offset +  0] <= mem_bias_exp_i[( 0+1)*(EXP_WIDTH+1)-1 :  0*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  1] <= mem_bias_exp_i[( 1+1)*(EXP_WIDTH+1)-1 :  1*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  2] <= mem_bias_exp_i[( 2+1)*(EXP_WIDTH+1)-1 :  2*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  3] <= mem_bias_exp_i[( 3+1)*(EXP_WIDTH+1)-1 :  3*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  4] <= mem_bias_exp_i[( 4+1)*(EXP_WIDTH+1)-1 :  4*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  5] <= mem_bias_exp_i[( 5+1)*(EXP_WIDTH+1)-1 :  5*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  6] <= mem_bias_exp_i[( 6+1)*(EXP_WIDTH+1)-1 :  6*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  7] <= mem_bias_exp_i[( 7+1)*(EXP_WIDTH+1)-1 :  7*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  8] <= mem_bias_exp_i[( 8+1)*(EXP_WIDTH+1)-1 :  8*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset +  9] <= mem_bias_exp_i[( 9+1)*(EXP_WIDTH+1)-1 :  9*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 10] <= mem_bias_exp_i[(10+1)*(EXP_WIDTH+1)-1 : 10*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 11] <= mem_bias_exp_i[(11+1)*(EXP_WIDTH+1)-1 : 11*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 12] <= mem_bias_exp_i[(12+1)*(EXP_WIDTH+1)-1 : 12*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 13] <= mem_bias_exp_i[(13+1)*(EXP_WIDTH+1)-1 : 13*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 14] <= mem_bias_exp_i[(14+1)*(EXP_WIDTH+1)-1 : 14*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 15] <= mem_bias_exp_i[(15+1)*(EXP_WIDTH+1)-1 : 15*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 16] <= mem_bias_exp_i[(16+1)*(EXP_WIDTH+1)-1 : 16*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 17] <= mem_bias_exp_i[(17+1)*(EXP_WIDTH+1)-1 : 17*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 18] <= mem_bias_exp_i[(18+1)*(EXP_WIDTH+1)-1 : 18*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 19] <= mem_bias_exp_i[(19+1)*(EXP_WIDTH+1)-1 : 19*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 20] <= mem_bias_exp_i[(20+1)*(EXP_WIDTH+1)-1 : 20*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 21] <= mem_bias_exp_i[(21+1)*(EXP_WIDTH+1)-1 : 21*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 22] <= mem_bias_exp_i[(22+1)*(EXP_WIDTH+1)-1 : 22*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 23] <= mem_bias_exp_i[(23+1)*(EXP_WIDTH+1)-1 : 23*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 24] <= mem_bias_exp_i[(24+1)*(EXP_WIDTH+1)-1 : 24*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 25] <= mem_bias_exp_i[(25+1)*(EXP_WIDTH+1)-1 : 25*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 26] <= mem_bias_exp_i[(26+1)*(EXP_WIDTH+1)-1 : 26*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 27] <= mem_bias_exp_i[(27+1)*(EXP_WIDTH+1)-1 : 27*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 28] <= mem_bias_exp_i[(28+1)*(EXP_WIDTH+1)-1 : 28*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 29] <= mem_bias_exp_i[(29+1)*(EXP_WIDTH+1)-1 : 29*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 30] <= mem_bias_exp_i[(30+1)*(EXP_WIDTH+1)-1 : 30*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 31] <= mem_bias_exp_i[(31+1)*(EXP_WIDTH+1)-1 : 31*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 32] <= mem_bias_exp_i[(32+1)*(EXP_WIDTH+1)-1 : 32*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 33] <= mem_bias_exp_i[(33+1)*(EXP_WIDTH+1)-1 : 33*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 34] <= mem_bias_exp_i[(34+1)*(EXP_WIDTH+1)-1 : 34*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 35] <= mem_bias_exp_i[(35+1)*(EXP_WIDTH+1)-1 : 35*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 36] <= mem_bias_exp_i[(36+1)*(EXP_WIDTH+1)-1 : 36*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 37] <= mem_bias_exp_i[(37+1)*(EXP_WIDTH+1)-1 : 37*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 38] <= mem_bias_exp_i[(38+1)*(EXP_WIDTH+1)-1 : 38*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 39] <= mem_bias_exp_i[(39+1)*(EXP_WIDTH+1)-1 : 39*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 40] <= mem_bias_exp_i[(40+1)*(EXP_WIDTH+1)-1 : 40*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 41] <= mem_bias_exp_i[(41+1)*(EXP_WIDTH+1)-1 : 41*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 42] <= mem_bias_exp_i[(42+1)*(EXP_WIDTH+1)-1 : 42*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 43] <= mem_bias_exp_i[(43+1)*(EXP_WIDTH+1)-1 : 43*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 44] <= mem_bias_exp_i[(44+1)*(EXP_WIDTH+1)-1 : 44*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 45] <= mem_bias_exp_i[(45+1)*(EXP_WIDTH+1)-1 : 45*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 46] <= mem_bias_exp_i[(46+1)*(EXP_WIDTH+1)-1 : 46*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 47] <= mem_bias_exp_i[(47+1)*(EXP_WIDTH+1)-1 : 47*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 48] <= mem_bias_exp_i[(48+1)*(EXP_WIDTH+1)-1 : 48*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 49] <= mem_bias_exp_i[(49+1)*(EXP_WIDTH+1)-1 : 49*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 50] <= mem_bias_exp_i[(50+1)*(EXP_WIDTH+1)-1 : 50*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 51] <= mem_bias_exp_i[(51+1)*(EXP_WIDTH+1)-1 : 51*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 52] <= mem_bias_exp_i[(52+1)*(EXP_WIDTH+1)-1 : 52*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 53] <= mem_bias_exp_i[(53+1)*(EXP_WIDTH+1)-1 : 53*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 54] <= mem_bias_exp_i[(54+1)*(EXP_WIDTH+1)-1 : 54*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 55] <= mem_bias_exp_i[(55+1)*(EXP_WIDTH+1)-1 : 55*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 56] <= mem_bias_exp_i[(56+1)*(EXP_WIDTH+1)-1 : 56*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 57] <= mem_bias_exp_i[(57+1)*(EXP_WIDTH+1)-1 : 57*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 58] <= mem_bias_exp_i[(58+1)*(EXP_WIDTH+1)-1 : 58*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 59] <= mem_bias_exp_i[(59+1)*(EXP_WIDTH+1)-1 : 59*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 60] <= mem_bias_exp_i[(60+1)*(EXP_WIDTH+1)-1 : 60*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 61] <= mem_bias_exp_i[(61+1)*(EXP_WIDTH+1)-1 : 61*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 62] <= mem_bias_exp_i[(62+1)*(EXP_WIDTH+1)-1 : 62*(EXP_WIDTH+1)];
    _mem_bias_exp[_mem_bias_exp_offset + 63] <= mem_bias_exp_i[(63+1)*(EXP_WIDTH+1)-1 : 63*(EXP_WIDTH+1)];
    end
  end 
   
  reg  [MID_WIDTH-1:0]        _mem_bias[0:MAX_O_CHANNELS-1];
  reg  [9:0]                  _mem_bias_offset;
  // bias memory address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_bias_offset <= 10'h0;
    end else begin
      // increment
      if(mem_bias_valid) begin
        _mem_bias_offset <= _mem_bias_offset+NUM_OF_BIAS_IN_1_BURST; //from 0 to 512.stride is 32
      end
      // reset
      if(mem_bias_last) begin
        _mem_bias_offset <= 10'h0;
      end
    end
  end 
  
  //transform fp_bias to bfp_bias, and storage them
  wire [MID_WIDTH-1:0]      _mem_bias_fixed[0:31];
  reg  [9:0]       _mem_bias_fixed_offset;
  reg              _mem_bias_fixed_valid;
  always@(posedge clk) begin
    _mem_bias_fixed_offset <= _mem_bias_offset;
    _mem_bias_fixed_valid <= mem_bias_valid;
  end
  genvar i;
  generate
    for(i=0; i<NUM_OF_BIAS_IN_1_BURST; i=i+1)
    begin:a
      float_to_fixed_bias fp2fixed_bias(
      .clk(clk),
      .datain(mem_bias_i[(i+1)*FP_WIDTH-1:i*FP_WIDTH]),
//      .datain({(FP_WIDTH){1'b0}}),
      .expin(_mem_bias_exp[_mem_bias_offset + i]),
//      .datain_valid(mem_bias_valid),
//      .dataout_valid(),
      .dataout(_mem_bias_fixed[i])
    );
    end
  endgenerate 
  
  always@(posedge clk) begin
    if(_mem_bias_fixed_valid) begin
      _mem_bias[_mem_bias_fixed_offset + 0] <= _mem_bias_fixed[ 0];
      _mem_bias[_mem_bias_fixed_offset + 1] <= _mem_bias_fixed[ 1];
      _mem_bias[_mem_bias_fixed_offset + 2] <= _mem_bias_fixed[ 2];
      _mem_bias[_mem_bias_fixed_offset + 3] <= _mem_bias_fixed[ 3];
      _mem_bias[_mem_bias_fixed_offset + 4] <= _mem_bias_fixed[ 4];
      _mem_bias[_mem_bias_fixed_offset + 5] <= _mem_bias_fixed[ 5];
      _mem_bias[_mem_bias_fixed_offset + 6] <= _mem_bias_fixed[ 6];
      _mem_bias[_mem_bias_fixed_offset + 7] <= _mem_bias_fixed[ 7];
      _mem_bias[_mem_bias_fixed_offset + 8] <= _mem_bias_fixed[ 8];
      _mem_bias[_mem_bias_fixed_offset + 9] <= _mem_bias_fixed[ 9];
      _mem_bias[_mem_bias_fixed_offset +10] <= _mem_bias_fixed[10];
      _mem_bias[_mem_bias_fixed_offset +11] <= _mem_bias_fixed[11];
      _mem_bias[_mem_bias_fixed_offset +12] <= _mem_bias_fixed[12];
      _mem_bias[_mem_bias_fixed_offset +13] <= _mem_bias_fixed[13];
      _mem_bias[_mem_bias_fixed_offset +14] <= _mem_bias_fixed[14];
      _mem_bias[_mem_bias_fixed_offset +15] <= _mem_bias_fixed[15];
      _mem_bias[_mem_bias_fixed_offset +16] <= _mem_bias_fixed[16];
      _mem_bias[_mem_bias_fixed_offset +17] <= _mem_bias_fixed[17];
      _mem_bias[_mem_bias_fixed_offset +18] <= _mem_bias_fixed[18];
      _mem_bias[_mem_bias_fixed_offset +19] <= _mem_bias_fixed[19];
      _mem_bias[_mem_bias_fixed_offset +20] <= _mem_bias_fixed[20];
      _mem_bias[_mem_bias_fixed_offset +21] <= _mem_bias_fixed[21];
      _mem_bias[_mem_bias_fixed_offset +22] <= _mem_bias_fixed[22];
      _mem_bias[_mem_bias_fixed_offset +23] <= _mem_bias_fixed[23];
      _mem_bias[_mem_bias_fixed_offset +24] <= _mem_bias_fixed[24];
      _mem_bias[_mem_bias_fixed_offset +25] <= _mem_bias_fixed[25];
      _mem_bias[_mem_bias_fixed_offset +26] <= _mem_bias_fixed[26];
      _mem_bias[_mem_bias_fixed_offset +27] <= _mem_bias_fixed[27];
      _mem_bias[_mem_bias_fixed_offset +28] <= _mem_bias_fixed[28];
      _mem_bias[_mem_bias_fixed_offset +29] <= _mem_bias_fixed[29];
      _mem_bias[_mem_bias_fixed_offset +30] <= _mem_bias_fixed[30];
      _mem_bias[_mem_bias_fixed_offset +31] <= _mem_bias_fixed[31];
    end
  end
  
`ifdef sim_ // bias info{{{
  reg [FP_WIDTH-1:0] _mem_bias_fp[0:511];
  always@(posedge clk) begin
  if(mem_bias_valid) begin
    _mem_bias_fp[_mem_bias_offset+ 0] <= mem_bias_i[( 0+1)*FP_WIDTH-1 :  0*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 1] <= mem_bias_i[( 1+1)*FP_WIDTH-1 :  1*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 2] <= mem_bias_i[( 2+1)*FP_WIDTH-1 :  2*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 3] <= mem_bias_i[( 3+1)*FP_WIDTH-1 :  3*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 4] <= mem_bias_i[( 4+1)*FP_WIDTH-1 :  4*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 5] <= mem_bias_i[( 5+1)*FP_WIDTH-1 :  5*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 6] <= mem_bias_i[( 6+1)*FP_WIDTH-1 :  6*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 7] <= mem_bias_i[( 7+1)*FP_WIDTH-1 :  7*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 8] <= mem_bias_i[( 8+1)*FP_WIDTH-1 :  8*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+ 9] <= mem_bias_i[( 9+1)*FP_WIDTH-1 :  9*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+10] <= mem_bias_i[(10+1)*FP_WIDTH-1 : 10*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+11] <= mem_bias_i[(11+1)*FP_WIDTH-1 : 11*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+12] <= mem_bias_i[(12+1)*FP_WIDTH-1 : 12*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+13] <= mem_bias_i[(13+1)*FP_WIDTH-1 : 13*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+14] <= mem_bias_i[(14+1)*FP_WIDTH-1 : 14*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+15] <= mem_bias_i[(15+1)*FP_WIDTH-1 : 15*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+16] <= mem_bias_i[(16+1)*FP_WIDTH-1 : 16*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+17] <= mem_bias_i[(17+1)*FP_WIDTH-1 : 17*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+18] <= mem_bias_i[(18+1)*FP_WIDTH-1 : 18*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+19] <= mem_bias_i[(19+1)*FP_WIDTH-1 : 19*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+20] <= mem_bias_i[(20+1)*FP_WIDTH-1 : 20*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+21] <= mem_bias_i[(21+1)*FP_WIDTH-1 : 21*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+22] <= mem_bias_i[(22+1)*FP_WIDTH-1 : 22*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+23] <= mem_bias_i[(23+1)*FP_WIDTH-1 : 23*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+24] <= mem_bias_i[(24+1)*FP_WIDTH-1 : 24*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+25] <= mem_bias_i[(25+1)*FP_WIDTH-1 : 25*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+26] <= mem_bias_i[(26+1)*FP_WIDTH-1 : 26*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+27] <= mem_bias_i[(27+1)*FP_WIDTH-1 : 27*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+28] <= mem_bias_i[(28+1)*FP_WIDTH-1 : 28*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+29] <= mem_bias_i[(29+1)*FP_WIDTH-1 : 29*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+30] <= mem_bias_i[(30+1)*FP_WIDTH-1 : 30*FP_WIDTH];
    _mem_bias_fp[_mem_bias_offset+31] <= mem_bias_i[(31+1)*FP_WIDTH-1 : 31*FP_WIDTH];
  end
end

 genvar m;
  generate
    for(m=0; m<512; m=m+1)
    begin
      assign mem_bias[(m+1)*32-1 : m*32] = {3'b0, _mem_bias[m]};
      assign mem_bias_fp[(m+1)*FP_WIDTH-1 : m*FP_WIDTH] = _mem_bias_fp[m];
      assign mem_bias_exp[(m+1)*8-1 : m*8] = {2'b0, _mem_bias_exp[m]};
    end
  endgenerate
  
  initial begin
    $vcdplusmemon(_mem_bias);
  end
   
  
`endif // }}}

  // bias data to add
  assign _mem_data_bias_data ={_mem_bias[_mem_data_cur_ker_set +63], _mem_bias[_mem_data_cur_ker_set +62], _mem_bias[_mem_data_cur_ker_set +61], _mem_bias[_mem_data_cur_ker_set +60],
                               _mem_bias[_mem_data_cur_ker_set +59], _mem_bias[_mem_data_cur_ker_set +58], _mem_bias[_mem_data_cur_ker_set +57], _mem_bias[_mem_data_cur_ker_set +56],
                               _mem_bias[_mem_data_cur_ker_set +55], _mem_bias[_mem_data_cur_ker_set +54], _mem_bias[_mem_data_cur_ker_set +53], _mem_bias[_mem_data_cur_ker_set +52],
                               _mem_bias[_mem_data_cur_ker_set +51], _mem_bias[_mem_data_cur_ker_set +50], _mem_bias[_mem_data_cur_ker_set +49], _mem_bias[_mem_data_cur_ker_set +48],
                               _mem_bias[_mem_data_cur_ker_set +47], _mem_bias[_mem_data_cur_ker_set +46], _mem_bias[_mem_data_cur_ker_set +45], _mem_bias[_mem_data_cur_ker_set +44],
                               _mem_bias[_mem_data_cur_ker_set +43], _mem_bias[_mem_data_cur_ker_set +42], _mem_bias[_mem_data_cur_ker_set +41], _mem_bias[_mem_data_cur_ker_set +40],
                               _mem_bias[_mem_data_cur_ker_set +39], _mem_bias[_mem_data_cur_ker_set +38], _mem_bias[_mem_data_cur_ker_set +37], _mem_bias[_mem_data_cur_ker_set +36],
                               _mem_bias[_mem_data_cur_ker_set +35], _mem_bias[_mem_data_cur_ker_set +34], _mem_bias[_mem_data_cur_ker_set +33], _mem_bias[_mem_data_cur_ker_set +32],
                               _mem_bias[_mem_data_cur_ker_set +31], _mem_bias[_mem_data_cur_ker_set +30], _mem_bias[_mem_data_cur_ker_set +29], _mem_bias[_mem_data_cur_ker_set +28],
                               _mem_bias[_mem_data_cur_ker_set +27], _mem_bias[_mem_data_cur_ker_set +26], _mem_bias[_mem_data_cur_ker_set +25], _mem_bias[_mem_data_cur_ker_set +24],
                               _mem_bias[_mem_data_cur_ker_set +23], _mem_bias[_mem_data_cur_ker_set +22], _mem_bias[_mem_data_cur_ker_set +21], _mem_bias[_mem_data_cur_ker_set +20],
                               _mem_bias[_mem_data_cur_ker_set +19], _mem_bias[_mem_data_cur_ker_set +18], _mem_bias[_mem_data_cur_ker_set +17], _mem_bias[_mem_data_cur_ker_set +16],
                               _mem_bias[_mem_data_cur_ker_set +15], _mem_bias[_mem_data_cur_ker_set +14], _mem_bias[_mem_data_cur_ker_set +13], _mem_bias[_mem_data_cur_ker_set +12],
                               _mem_bias[_mem_data_cur_ker_set +11], _mem_bias[_mem_data_cur_ker_set +10], _mem_bias[_mem_data_cur_ker_set + 9], _mem_bias[_mem_data_cur_ker_set + 8],
                               _mem_bias[_mem_data_cur_ker_set + 7], _mem_bias[_mem_data_cur_ker_set + 6], _mem_bias[_mem_data_cur_ker_set + 5], _mem_bias[_mem_data_cur_ker_set + 4],
                               _mem_bias[_mem_data_cur_ker_set + 3], _mem_bias[_mem_data_cur_ker_set + 2], _mem_bias[_mem_data_cur_ker_set + 1], _mem_bias[_mem_data_cur_ker_set + 0]};
//  assign _mem_data_bias_data = {(K_C){29'h0000004b}};
  //----------------------------------------------bias--------------------------------------
 
  assign _mem_data_ker_set  = _mem_data_output_mode==2'd2 ? _mem_data_ofmem_portion : _mem_data_cur_ker_set[8:6];
  assign _mem_data_rd_x     = _mem_data_output_mode==2'd2 ? 4'd0 : mem_data_to_conv_x;
  assign _mem_data_rd_y     = _mem_data_output_mode==2'd2 ? 4'd0 : mem_data_to_conv_y;
`ifdef sim_
  assign _mem_data_wr_en    = _mem_data_conv_we || _mem_data_pooling_we; //write to output cache
`else
  assign _mem_data_wr_en    = _mem_data_conv_we || (_mem_data_pooling_we && (!mem_data_last_layer));
`endif
  assign mem_data_conv_partial_sum_valid = _mem_data_conv_rd_valid;

  // mode
  always@(mem_data_wr_data_re or mem_data_conv_valid or mem_data_pooling_en or mem_data_last_fm) begin
    if(mem_data_conv_valid) begin
      if(mem_data_pooling_en && mem_data_last_fm) begin // pooling
        _mem_data_output_mode = 2'd1;
      end else begin // normal
        _mem_data_output_mode = 2'd0;
      end
    end else if(mem_data_wr_data_re) begin // write data to ddr
      _mem_data_output_mode = 2'd2;
    end else begin
      _mem_data_output_mode = 2'd0;
    end
  end

  // buffer reading position
  // quarter number, 0 -- TL, 1 -- TR, 2 -- BL, 3 -- BR
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_data_quar_num <= 2'd0;
    end else begin
      if(mem_data_wr_data_re) begin // write data to ddr
        if(mem_data_wr_done || mem_data_pooling_en) begin
          _mem_data_quar_num <= 2'd0;
        end else if(mem_data_wr_next_quarter) begin
          _mem_data_quar_num <= _mem_data_quar_num + 2'd1;
        end
      end
    end
  end
  // channel index 0~63, portion number of ofmem 0~7
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_data_channel_idx   <= 6'd0;
      _mem_data_ofmem_portion <= 3'd0;
    end else begin
      if(mem_data_wr_data_re) begin // write data to ddr
        if(mem_data_wr_done) begin
        // reset
          _mem_data_channel_idx   <= 6'd0;
          _mem_data_ofmem_portion <= 3'd0;
        end else if(mem_data_wr_next_channel) begin
        // increment
          if(_mem_data_channel_idx==6'd63) begin
            _mem_data_channel_idx <= 6'd0;
            _mem_data_ofmem_portion <= _mem_data_ofmem_portion + 3'd1;
          end else begin
            _mem_data_channel_idx <= _mem_data_channel_idx + 6'd1;
          end
        end
      end
    end
  end

  //pooling, relu is included
  max_1x64 #(
    .MID_WIDTH(MID_WIDTH),
    .K_C(K_C)
  )pooling_relu(
    .clk(clk),
    .mem_max_v1(mem_data_conv_data_i),
    .mem_max_v2(_mem_data_max_op2),
//    .mem_max_en(1'b0), // disable pooling
    .mem_max_en(mem_data_last_fm),  //time to get the final top data
    .mem_max_o(_mem_data_max_o)
  );
  
  //2nd comparison operand
  assign _mem_data_max_op2 = _mem_data_output_mode == 2'd0 ? {(K_C*MID_WIDTH){1'b0}} :
                               (mem_data_conv_x[0] == 1'b1 ? _mem_data_max_reg :      //pooling 2x1, row direction
                               (mem_data_conv_y[0] == 1'b1 ? _mem_data_pooling_o : {(K_C*MID_WIDTH){1'b0}}) );  //pooling 1x2, column direction
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_data_max_reg <= {(K_C*MID_WIDTH){1'b0}};
    end else if(mem_data_conv_x[0] == 1'b0) begin
      _mem_data_max_reg <= _mem_data_max_o;
    end
  end
  
  // pooling result writing position
  always@(mem_data_conv_x) begin
    _mem_data_pooling_x = 4'd0;
    case(mem_data_conv_x)
      4'd0,
      4'd1: _mem_data_pooling_x = 4'd0;
      4'd2,
      4'd3: _mem_data_pooling_x = 4'd1;
      4'd4,
      4'd5: _mem_data_pooling_x = 4'd2;
      4'd6,
      4'd7: _mem_data_pooling_x = 4'd3;
      4'd8,
      4'd9: _mem_data_pooling_x = 4'd4;
      4'd10,
      4'd11: _mem_data_pooling_x = 4'd5;
      4'd12,
      4'd13: _mem_data_pooling_x = 4'd6;
    endcase
  end
  always@(mem_data_conv_y) begin
    _mem_data_pooling_y = 4'd0;
    case(mem_data_conv_y)
      4'd0,
      4'd1: _mem_data_pooling_y = 4'd0;
      4'd2,
      4'd3: _mem_data_pooling_y = 4'd1;
      4'd4,
      4'd5: _mem_data_pooling_y = 4'd2;
      4'd6,
      4'd7: _mem_data_pooling_y = 4'd3;
      4'd8,
      4'd9: _mem_data_pooling_y = 4'd4;
      4'd10,
      4'd11: _mem_data_pooling_y = 4'd5;
      4'd12,
      4'd13: _mem_data_pooling_y = 4'd6;
    endcase
  end
  
  // pooling result reading
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_data_pooling_rd_x <= 4'd0;
    end else begin
      if(_mem_data_pooling_re) begin
        if(_mem_data_pooling_rd_x==4'd6) begin
          _mem_data_pooling_rd_x <= 4'd0;
        end else begin
          _mem_data_pooling_rd_x <= _mem_data_pooling_rd_x + 4'd1;
        end
      end
    end
  end
  // pooling write/read enable
  assign _mem_data_pooling_we = (mem_data_pooling_en && mem_data_last_fm) && (mem_data_conv_x[0]==1'b1);
  assign _mem_data_pooling_re = (mem_data_pooling_en && mem_data_last_fm) &&
                            ((mem_data_conv_y[0]==1'b1 && mem_data_conv_x[0]==1'b0 && mem_data_conv_x!=4'd10 && mem_data_conv_x!=4'd12) ||
                             (mem_data_conv_y[0]==1'b0 && mem_data_conv_x==4'd10) || //why???
                             (mem_data_conv_y[0]==1'b0 && mem_data_conv_x==4'd12));
  // disable conv_we
  assign _mem_data_conv_we = (mem_data_pooling_en && mem_data_last_fm) ? 1'b0 : mem_data_conv_valid;
  // write x/y
  assign _mem_data_wr_x  = (mem_data_pooling_en && mem_data_last_fm) ? _mem_data_pooling_x : mem_data_conv_x;
  assign _mem_data_wr_y  = (mem_data_pooling_en && mem_data_last_fm) ? _mem_data_pooling_y : mem_data_conv_y;
  assign mem_data_pooling_last_pos = (mem_data_conv_x==4'd13 && mem_data_conv_y==4'd13 && mem_data_pooling_en && mem_data_last_fm) ? 1'b1 : 1'b0;
  assign _mem_data_pooling_first_pos = (mem_data_conv_x==4'd1 && mem_data_conv_y==4'd1 && mem_data_pooling_en && mem_data_last_fm) ? 1'b1 : 1'b0;

  // output buffer
  bram_data #(
    .MID_WIDTH(MID_WIDTH),
    .K_C(K_C),
    .PORT_ADDR_WIDTH(11)
  ) mem_bram_data (
    .rst_n(rst_n),
    .clk(clk),
    .bram_data_quarter_num(_mem_data_quar_num), // ddr related only
    .bram_data_ker_set(_mem_data_ker_set),
    .bram_data_channel_idx(_mem_data_channel_idx), // ddr related only
    .bram_data_wr_x(_mem_data_wr_x),
    .bram_data_wr_y(_mem_data_wr_y),
    .bram_data_rd_x(_mem_data_rd_x),
    .bram_data_rd_y(_mem_data_rd_y),
    .bram_data_pooling_rd_x(_mem_data_pooling_rd_x[2:0]),
    .bram_data_pooling_rd_y(_mem_data_pooling_y[2:0]),
    .bram_data_data_i(_mem_data_max_o),
    .bram_data_wr_en(_mem_data_wr_en),
    .bram_data_conv_rd_en(mem_data_conv_rd_partial_sum),
    .bram_data_pooling_rd_en(_mem_data_pooling_re),
    .bram_data_wr_ddr_rd_en(mem_data_wr_data_re),
    .bram_data_rd_top_buffer(mem_data_rd_buffer),
  //.bram_data_wr_ddr_rd_next_quar(_mem_data_wr_on_the_next_quar),
    .bram_data_wr_ddr_rd_next_quar(mem_data_wr_next_quarter),
    .bram_data_pre_data(_mem_data_pre_data),
    .bram_data_ddr_do(_mem_data_data),
    .bram_data_pooling_data(_mem_data_pooling_o),
    .bram_data_ddr_rd_valid(_mem_data_wr_data_valid),
    .bram_data_conv_rd_valid(_mem_data_conv_rd_valid),
    .bram_data_pooling_rd_valid()
  );
  
  //transform the bfp_top_data to fp_top_data
  reg   _mem_data_wr_data_valid_reg;
  reg   _mem_data_wr_data_valid_reg2;
  wire  _mem_data_wr_data_valid_rising_edge; //it requires a valid signal of 2-period at least
  reg   _mem_data_wr_data_ready;
//  reg [7*7*MID_WIDTH-1:0]   _mem_data_data_ready;
  always@(posedge clk) begin
    _mem_data_wr_data_valid_reg <= _mem_data_wr_data_valid;
    _mem_data_wr_data_valid_reg2 <= _mem_data_wr_data_valid_reg;
  end
  assign _mem_data_wr_data_valid_rising_edge = _mem_data_wr_data_valid && (!_mem_data_wr_data_valid_reg2);
  always@(posedge clk) begin
    _mem_data_wr_data_ready <= _mem_data_wr_data_valid_rising_edge;
//    _mem_data_data_ready <= _mem_data_data;
    mem_data_wr_data_valid <= _mem_data_wr_data_ready;
  end
  

  wire [8:0]    _mem_bias_exp_idx;
  reg  [8:0]    _mem_bias_exp_idx_1;
  reg  [8:0]    _mem_bias_exp_idx_2;
  reg  [EXP_WIDTH:0]  _mem_bias_exp_cur;
  reg  [EXP_WIDTH:0]  _mem_bias_exp_cur_1;
  assign _mem_bias_exp_idx = ({{6{1'b0}}, _mem_data_ker_set}<<6) + {{3{1'b0}}, _mem_data_channel_idx};
  always@(posedge clk) begin
    _mem_bias_exp_idx_1 <= _mem_bias_exp_idx;
    _mem_bias_exp_idx_2 <= _mem_bias_exp_idx_1;
    _mem_bias_exp_cur   <= _mem_bias_exp[_mem_bias_exp_idx_2];
    _mem_bias_exp_cur_1 <= _mem_bias_exp_cur;
  end
  genvar j;
  generate
    for(j=0; j<7*7; j=j+1)
    begin:wr_ddr
      fixed_to_float #(
        .FP_WIDTH(FP_WIDTH),
        .MID_WIDTH(MID_WIDTH),
        .EXP_WIDTH(EXP_WIDTH)
      )fixed2fp_top(
        .clk(clk),
        .datain(_mem_data_data[(j+1)*MID_WIDTH-1 : j*MID_WIDTH]), //positive after relu activation.
        .datain_valid(_mem_data_wr_data_valid_rising_edge),
        .exp_bias(_mem_bias_exp_cur_1), //exp_bottom+exp_ker, with and offset of 30, and is controlled by wr_ddr_data.v
        .dataout_valid(),                                                        
        .dataout(mem_data_data[(j+1)*FP_WIDTH-1 : j*FP_WIDTH]),
        .dataout_exp(_mem_data_data_exp[(j+1)*EXP_WIDTH-1 : j*EXP_WIDTH])
    );
    end  
  endgenerate


`ifdef sim_
  wire [MID_WIDTH-1:0]   _mem_data_data_sim[0:7*7-1];
  wire [FP_WIDTH-1:0]    mem_data_data_sim[0:7*7-1];
  wire [EXP_WIDTH-1:0]   _mem_data_data_exp_sim[0:7*7-1];
  wire [5:0]             _mem_bias_exp_sim;
  assign _mem_bias_exp_sim = _mem_bias_exp[(_mem_data_ker_set<<6) + _mem_data_channel_idx];
  genvar n;
  generate
    for(n=0; n<7*7; n=n+1)
    begin
      assign _mem_data_data_sim[n] = _mem_data_data[(n+1)*MID_WIDTH-1 : n*MID_WIDTH];
      assign mem_data_data_sim[n]  = mem_data_data[(n+1)*FP_WIDTH-1 : n*FP_WIDTH];
      assign _mem_data_data_exp_sim[n] = _mem_data_data_exp[(n+1)*EXP_WIDTH-1 : n*EXP_WIDTH];
    end
  endgenerate
`endif
  
  `ifdef sim_ //compare 7x7 output data {{{
  reg _mem_data_directC_cmp7x7NotPass;
  reg [9:0]   _mem_data_channel_index;
  reg [9:0]   _mem_data_channel_index_reg;
  integer fd_orig_top, fd_verilog_top;
  initial begin
    _mem_data_directC_cmp7x7NotPass = 0;
//    fd_orig_top = getFileDescriptor("../../../../../data/caffe_bfp/top_bfp/relu1_2.txt");
    fd_orig_top = getFileDescriptor("../../../../../data/caffe_bfp/conv5_3/pool5.txt");
    fd_verilog_top = wrFileDescriptor("./verilog_top.txt");
    if((fd_orig_top == (`NULL)) || (fd_verilog_top == (`NULL))) begin
      $display("top fd handle is NULL\n");
      $finish;
    end
  end
  
  //position
  reg  [8:0]  _mem_cmp7x7_posX;
  reg  [8:0]  _mem_cmp7x7_posY;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_cmp7x7_posX <= 9'd0;
      _mem_cmp7x7_posY <= 9'd0;
    end else begin
      if(mem_data_wr_done) begin
        if(_mem_cmp7x7_posX==`END_X) begin
          _mem_cmp7x7_posX <= 9'd0;
        end else begin
          _mem_cmp7x7_posX <= _mem_cmp7x7_posX+9'd1;
        end
        if(_mem_cmp7x7_posX==`END_X) begin
          if(_mem_cmp7x7_posY==`END_Y) begin
            _mem_cmp7x7_posY <= 9'd0;
          end else begin
            _mem_cmp7x7_posY <= _mem_cmp7x7_posY + 9'd1;
          end
        end 
      end
    end
  end
  // channel index
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_data_channel_index <= 10'd0;
    end else begin
      if(mem_data_wr_done) begin
        _mem_data_channel_index <= 10'd0;
      end else if(mem_data_wr_next_channel) begin
        _mem_data_channel_index <= _mem_data_channel_index + 10'd1;
      end
    end
  end
  always@(posedge clk or negedge rst_n) begin
    _mem_data_channel_index_reg <= _mem_data_channel_index;
  end
  always@(posedge clk or negedge rst_n) begin
    if(rst_n) begin
      if(mem_data_wr_data_re && mem_data_wr_next_quarter) begin
        _mem_data_directC_cmp7x7NotPass = cmp7x7output(mem_cmp_result && mem_cmp_top && mem_data_wr_next_quarter, mem_data_pooling_en, fd_orig_top, _mem_cmp7x7_posX, _mem_cmp7x7_posY, _mem_data_quar_num, _mem_data_channel_index, mem_data_data, _mem_data_data_exp);
//        _mem_data_directC_cmp7x7NotPass = cmp7x7output_bfp(mem_cmp_result && mem_cmp_top && mem_data_wr_next_quarter, mem_data_pooling_en, fd_orig_top, _mem_cmp7x7_posX, _mem_cmp7x7_posY, _mem_data_quar_num, _mem_data_channel_index, mem_data_data);
        $display("%t: check 7x7 data", $realtime);
        write2File(fd_verilog_top, mem_cmp_top, mem_data_pooling_en, _mem_cmp7x7_posX, _mem_cmp7x7_posY, _mem_data_quar_num, _mem_data_channel_index, mem_data_data);
      end
//      if(_mem_data_directC_cmp7x7NotPass) begin
//        $display("%t: 7x7 data check failed", $realtime);
//        _mem_data_directC_cmp7x7NotPass = 1'b0;
////        #100 $finish;
//      end
    end
  end
  
  //check mem_data_data in fixed29
  wire [7*7*32-1 : 0] _mem_data_data_fixed29;
  wire [8-1 : 0]      _mem_data_data_exp5;
  wire                _mem_data_data_valid_rising_edge1;
  integer fd_verilog_top_fixed29, fd_verilog_exp5;
  initial begin
    fd_verilog_top_fixed29 = wrFileDescriptor("./verilog_top_fixed29.txt");
    fd_verilog_exp5 = wrFileDescriptor("./verilog_exp5.txt");
    if((fd_verilog_top_fixed29 == (`NULL)) || (fd_verilog_exp5 == (`NULL))) begin
      $display("verilog_top_fixed29 fd handle is NULL\n");
      $finish;
    end
  end
  
  genvar kk;
  generate
    for(kk=0; kk<7*7; kk=kk+1)
    begin
      assign _mem_data_data_fixed29[(kk+1)*32-1 : kk*32] = {3'b0, _mem_data_data[(kk+1)*29-1 : kk*29]};
    end
  endgenerate
  assign _mem_data_data_exp5 = {2'b0, _mem_bias_exp[_mem_bias_exp_idx]}; ////exp_bottom+exp_ker, with an offset of 30
  
  assign _mem_data_data_valid_rising_edge1 = _mem_data_wr_data_valid && (!_mem_data_wr_data_valid_reg);
  always@(posedge clk) begin
    if(_mem_data_data_valid_rising_edge1 && mem_cmp_top) begin
      write2FileFixed29(fd_verilog_top_fixed29, 1'b1, mem_data_pooling_en, _mem_cmp7x7_posX, _mem_cmp7x7_posY, _mem_data_quar_num, _mem_data_channel_index, _mem_data_data_fixed29);
      write2FileExp5(fd_verilog_exp5, 1'b1, mem_data_pooling_en, _mem_cmp7x7_posX, _mem_cmp7x7_posY, _mem_data_quar_num, _mem_data_channel_index, _mem_data_data_exp5);
    end
  end
  
  `endif //}}}
  
  //update max_exp of fm
  //get max_exp of 7x7 wr_out data
  //version 1
  wire      _mem_data_data_exp_max_valid;
  max_1_49 #(
    .EXP_WIDTH(EXP_WIDTH)
  ) get_max_exp(
    .clk(clk),
    .data_1x49(_mem_data_data_exp),
    .max_en(mem_data_wr_data_valid),
    .data_max(_mem_data_data_exp_max),
    .data_max_valid(_mem_data_data_exp_max_valid)
  );
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_fm_max_exp_o <= 5'b0;
    end else begin
      if(mem_fm_max_exp_i_valid) // reset when a new layer starts
        _mem_fm_max_exp_o <= 5'b0;
      else if(_mem_data_data_exp_max_valid) begin
        if(_mem_fm_max_exp_o < _mem_data_data_exp_max)
          _mem_fm_max_exp_o <= _mem_data_data_exp_max;
      end
    end
  end
  
  //valid singal _mem_fm_max_exp_o_valid
  assign mem_fm_max_exp_o_valid = mem_data_wr_done && mem_data_wr_x_eq_end && mem_data_wr_y_eq_end;
  assign mem_fm_max_exp_o = _mem_fm_max_exp_o;
  

  // last layer pooling output, to fc input buffer
  //--------------------------------------------------------------------------------------
  wire                     _last_layer_valid;
  wire                     _last_layer_last_pos;
  wire                     _last_layer_first_pos;
  wire [3:0]               _last_layer_ker_set;
  assign _last_layer_valid      = _mem_data_pooling_we && (mem_data_conv_x[0]==1'b1);
  assign _last_layer_last_pos   = mem_data_pooling_last_pos && (_mem_data_cur_ker_set[9:6]==4'd7);
  assign _last_layer_first_pos  = _mem_data_pooling_first_pos;
  assign _last_layer_ker_set    = _mem_data_cur_ker_set[9:6];
 
  wire [K_C*FP_WIDTH-1:0]  _last_layer_o;
  reg                      _last_layer_o_valid;
  reg                      _last_layer_last_pos_reg;
  reg                      _last_layer_first_pos_reg;
  reg [3:0]                _last_layer_ker_set_reg;
  
  always@(posedge clk) begin
    _last_layer_o_valid <= _last_layer_valid;
    _last_layer_last_pos_reg  <= _last_layer_last_pos; 
    _last_layer_first_pos_reg <= _last_layer_first_pos;
    _last_layer_ker_set_reg <= _last_layer_ker_set;
  end
      
  always@(posedge clk) begin
    if(mem_data_last_layer) begin
      mem_data_last_layer_valid   <= _last_layer_o_valid;
      mem_data_last_layer_last_pos<= _last_layer_last_pos_reg;
      mem_data_last_layer_ker_set <= _last_layer_ker_set_reg;
      mem_data_last_layer_on      <= 1'b1;
      mem_data_last_layer_first_pos <= _last_layer_first_pos_reg;
      if(_mem_data_pooling_we) begin
        mem_data_conv_data_last_layer_o <= _last_layer_o;
      end
    end else begin
      mem_data_last_layer_on      <= 1'b0;
      mem_data_last_layer_valid   <= 1'd0;
      mem_data_last_layer_last_pos<= 1'd0;
      mem_data_last_layer_ker_set <= 4'd0;
      mem_data_last_layer_first_pos   <= 1'b0;
//      mem_data_conv_data_last_layer_o <= {(FP_WIDTH*K_C){1'b0}};
    end
  end
  
  genvar k;
  generate
    for(k=0; k<K_C; k=k+1)
    begin:wr_fc
      fixed_to_float #(
        .FP_WIDTH(FP_WIDTH),
        .MID_WIDTH(MID_WIDTH),
        .EXP_WIDTH(EXP_WIDTH)
      )fixed2fp_top(
        .clk(clk),
        .datain(_mem_data_max_o[(k+1)*MID_WIDTH-1 : k*MID_WIDTH]), //positive after relu activation.
        .datain_valid(_last_layer_valid && mem_data_last_layer),
        .exp_bias(_mem_bias_exp[_mem_data_cur_ker_set]), //exp_bottom+exp_ker, with and offset of 30, 
        .dataout_valid(),                                                        //<--idx maybe changed when _mem_data_data is readed
        .dataout(_last_layer_o[(k+1)*FP_WIDTH-1 : k*FP_WIDTH]),
        .dataout_exp()
    );
    end  
  endgenerate
  //--------------------------------------------------------------------------------------------------

  
endmodule
