`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:zhanghs 
// 
// Create Date: 2018/09/23 22:05:40
// Module Name: adder3
// Description: 
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module adder3 #(
  parameter DATA_WIDTH = 8,
  parameter MID_WIDTH = 29
)(
  input  wire                         clk,
  // input data
  input  wire                         en,
  input  wire [DATA_WIDTH-1 : 0]      a1,
  input  wire [DATA_WIDTH-1 : 0]      a2,
  input  wire [DATA_WIDTH-1 : 0]      a3,
  // output data
  output wire                         valid,
  output wire [18-1 : 0]              adder_o
);
  assign valid = en;
  
  wire[17-1 : 0]        _sum2;
  wire[18-1 : 0]        _sum3;

  adder_1 sum_2_value (
    .A(a1),
    .B(a2),
    .S(_sum2)
  );

  adder_2 sum_3rd (
    .A(_sum2),
    .B(a3),
    .S(adder_o)
  );
endmodule
