`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/23 19:42:49
// Module Name: pe_array3x3
// Description: PPMAC structure
//              2 dim(3x3) processing element array
//              add partial summation
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module pe_array3x3#(
  parameter DATA_WIDTH  = 8,
  parameter MID_WIDTH   = 29
)(
  input  wire                           clk,
  input  wire                           pe3_array0_valid, // data valid, enable pe_array
  input  wire                           pe3_array1_valid,
  input  wire                           pe3_array2_valid,
  input  wire [3*DATA_WIDTH-1:0]        pe3_array0_data3, // 3 data
  input  wire [3*DATA_WIDTH-1:0]        pe3_array1_data3,
  input  wire [3*DATA_WIDTH-1:0]        pe3_array2_data3,
  input  wire [3*DATA_WIDTH-1:0]        pe3_array0_ker3,  // 3 weight
  input  wire [3*DATA_WIDTH-1:0]        pe3_array1_ker3,
  input  wire [3*DATA_WIDTH-1:0]        pe3_array2_ker3,
  input  wire [MID_WIDTH-1:0]           pe3_partial_value,
  output wire [MID_WIDTH-1:0]           pe3_o,
  output wire                           pe3_valid,
//`ifdef sim_
//  output wire                           pe3_add_partial_sum,
//`endif
  output wire                           pe3_next_partial_sum
);
  //data width needs to adjusted
  wire [MID_WIDTH-1:0]       _pe_array0_o;
  wire [MID_WIDTH-1:0]       _pe_array1_o;
  wire [MID_WIDTH-1:0]       _pe_array2_o;
  
  assign pe3_o = _pe_array2_o;
  
  //adder:
  //adder_1: 16'b+16'b=17'b
  //adder_2: (16'b+16'b)+16'b=17'b+16'b=18'b
  //adder_3: 29'b+18'b=29'b
  
  pe_array1x3#(
    .DATA_WIDTH(DATA_WIDTH),
    .MID_WIDTH(MID_WIDTH)
    ) pe3_0(
      .clk(clk),
      .pe_ker3_i(pe3_array0_ker3),
      .pe_bias_i(pe3_partial_value),
      .pe_data3_i(pe3_array0_data3),
      .pe_en(pe3_array0_valid),
      .pe_next_partial_sum(pe3_next_partial_sum),
//`ifdef sim_
//      .pe_add_partial_sum(pe3_add_partial_sum),
//`endif
      .pe_data_valid(),
      .pe_data_o(_pe_array0_o)
    );

  pe_array1x3#(
    .DATA_WIDTH(DATA_WIDTH),
    .MID_WIDTH(MID_WIDTH)
    ) pe3_1(
      .clk(clk),
      .pe_ker3_i(pe3_array1_ker3),
      .pe_bias_i(_pe_array0_o),
      .pe_data3_i(pe3_array1_data3),
      .pe_en(pe3_array1_valid),
      .pe_next_partial_sum(),
      .pe_data_valid(),
      .pe_data_o(_pe_array1_o)
    );

  pe_array1x3#(
    .DATA_WIDTH(DATA_WIDTH),
    .MID_WIDTH(MID_WIDTH)
    ) pe3_2(
      .clk(clk),
      .pe_ker3_i(pe3_array2_ker3),
      .pe_bias_i(_pe_array1_o),
      .pe_data3_i(pe3_array2_data3),
      .pe_en(pe3_array2_valid),
      .pe_next_partial_sum(),
      .pe_data_valid(pe3_valid),
      .pe_data_o(_pe_array2_o)
    );

endmodule
