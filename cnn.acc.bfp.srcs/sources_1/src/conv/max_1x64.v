`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/11 21:31:42
// Module Name: max_1x64
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: compare two 1x64 float number vectors
//              relu is included
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module max_1x64 #(
  parameter MID_WIDTH = 29,
  parameter K_C       = 64
)(
//  input  wire                         clk,
  input  wire [MID_WIDTH*K_C-1:0]     mem_max_v1,
  input  wire [MID_WIDTH*K_C-1:0]     mem_max_v2,
  input  wire                         mem_max_en,
  output wire [MID_WIDTH*K_C-1:0]     mem_max_o
);
  genvar i;
  generate
    for(i=0; i<K_C; i=i+1)
    begin:a
      fixed_max #(
        .MID_WIDTH(MID_WIDTH)
      )max(
        .a1(mem_max_v1[(i+1)*MID_WIDTH-1 : i*MID_WIDTH]),
        .a2(mem_max_v2[(i+1)*MID_WIDTH-1 : i*MID_WIDTH]),
        .en(mem_max_en),
        .max_o(mem_max_o[(i+1)*MID_WIDTH-1 : i*MID_WIDTH])
      );
    end
  endgenerate
  

endmodule
