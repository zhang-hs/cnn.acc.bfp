`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/20 20:17:13
// Module Name: max_1x49
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: get maximum exp of 7*7 top feather map that is written to ddr.
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module max_1_49 #( 
  parameter EXP_WIDTH = 5
)(
  input  wire                         clk,
  input  wire [7*7*EXP_WIDTH-1:0]     data_1x49, //the value is between 0 and 31
//  input  wire [EXP_WIDTH-1:0]         data_v2,
  input  wire                         max_en,
  output reg [EXP_WIDTH-1:0]         data_max,
  output reg                          data_max_valid 
);
  
  wire [32-1:0]     data_value[7*7-1:0];
//  wire [32-1:0]     data_value_v2;
  wire [32-1:0]     _data_value_sum;
  reg  [15:0]       val16;
  reg  [7:0]        val8;
  reg  [3:0]        val4;
  reg  [4:0]        cnt0; 
  reg  [4:0]        max_value;
  
  assign data_value[0 ] = 32'h0000_0001 << data_1x49[1 *EXP_WIDTH-1 : 0];
  assign data_value[1 ] = 32'h0000_0001 << data_1x49[2 *EXP_WIDTH-1 : 1 *EXP_WIDTH]; 
  assign data_value[2 ] = 32'h0000_0001 << data_1x49[3 *EXP_WIDTH-1 : 2 *EXP_WIDTH]; 
  assign data_value[3 ] = 32'h0000_0001 << data_1x49[4 *EXP_WIDTH-1 : 3 *EXP_WIDTH]; 
  assign data_value[4 ] = 32'h0000_0001 << data_1x49[5 *EXP_WIDTH-1 : 4 *EXP_WIDTH]; 
  assign data_value[5 ] = 32'h0000_0001 << data_1x49[6 *EXP_WIDTH-1 : 5 *EXP_WIDTH]; 
  assign data_value[6 ] = 32'h0000_0001 << data_1x49[7 *EXP_WIDTH-1 : 6 *EXP_WIDTH]; 
  assign data_value[7 ] = 32'h0000_0001 << data_1x49[8 *EXP_WIDTH-1 : 7 *EXP_WIDTH]; 
  assign data_value[8 ] = 32'h0000_0001 << data_1x49[9 *EXP_WIDTH-1 : 8 *EXP_WIDTH]; 
  assign data_value[9 ] = 32'h0000_0001 << data_1x49[10*EXP_WIDTH-1 : 9 *EXP_WIDTH]; 
  assign data_value[10] = 32'h0000_0001 << data_1x49[11*EXP_WIDTH-1 : 10*EXP_WIDTH]; 
  assign data_value[11] = 32'h0000_0001 << data_1x49[12*EXP_WIDTH-1 : 11*EXP_WIDTH]; 
  assign data_value[12] = 32'h0000_0001 << data_1x49[13*EXP_WIDTH-1 : 12*EXP_WIDTH]; 
  assign data_value[13] = 32'h0000_0001 << data_1x49[14*EXP_WIDTH-1 : 13*EXP_WIDTH]; 
  assign data_value[14] = 32'h0000_0001 << data_1x49[15*EXP_WIDTH-1 : 14*EXP_WIDTH]; 
  assign data_value[15] = 32'h0000_0001 << data_1x49[16*EXP_WIDTH-1 : 15*EXP_WIDTH]; 
  assign data_value[16] = 32'h0000_0001 << data_1x49[17*EXP_WIDTH-1 : 16*EXP_WIDTH]; 
  assign data_value[17] = 32'h0000_0001 << data_1x49[18*EXP_WIDTH-1 : 17*EXP_WIDTH]; 
  assign data_value[18] = 32'h0000_0001 << data_1x49[19*EXP_WIDTH-1 : 18*EXP_WIDTH]; 
  assign data_value[19] = 32'h0000_0001 << data_1x49[20*EXP_WIDTH-1 : 19*EXP_WIDTH]; 
  assign data_value[20] = 32'h0000_0001 << data_1x49[21*EXP_WIDTH-1 : 20*EXP_WIDTH]; 
  assign data_value[21] = 32'h0000_0001 << data_1x49[22*EXP_WIDTH-1 : 21*EXP_WIDTH]; 
  assign data_value[22] = 32'h0000_0001 << data_1x49[23*EXP_WIDTH-1 : 22*EXP_WIDTH]; 
  assign data_value[23] = 32'h0000_0001 << data_1x49[24*EXP_WIDTH-1 : 23*EXP_WIDTH]; 
  assign data_value[24] = 32'h0000_0001 << data_1x49[25*EXP_WIDTH-1 : 24*EXP_WIDTH]; 
  assign data_value[25] = 32'h0000_0001 << data_1x49[26*EXP_WIDTH-1 : 25*EXP_WIDTH]; 
  assign data_value[26] = 32'h0000_0001 << data_1x49[27*EXP_WIDTH-1 : 26*EXP_WIDTH]; 
  assign data_value[27] = 32'h0000_0001 << data_1x49[28*EXP_WIDTH-1 : 27*EXP_WIDTH]; 
  assign data_value[28] = 32'h0000_0001 << data_1x49[29*EXP_WIDTH-1 : 28*EXP_WIDTH]; 
  assign data_value[29] = 32'h0000_0001 << data_1x49[30*EXP_WIDTH-1 : 29*EXP_WIDTH]; 
  assign data_value[30] = 32'h0000_0001 << data_1x49[31*EXP_WIDTH-1 : 30*EXP_WIDTH]; 
  assign data_value[31] = 32'h0000_0001 << data_1x49[32*EXP_WIDTH-1 : 31*EXP_WIDTH]; 
  assign data_value[32] = 32'h0000_0001 << data_1x49[33*EXP_WIDTH-1 : 32*EXP_WIDTH]; 
  assign data_value[33] = 32'h0000_0001 << data_1x49[34*EXP_WIDTH-1 : 33*EXP_WIDTH]; 
  assign data_value[34] = 32'h0000_0001 << data_1x49[35*EXP_WIDTH-1 : 34*EXP_WIDTH]; 
  assign data_value[35] = 32'h0000_0001 << data_1x49[36*EXP_WIDTH-1 : 35*EXP_WIDTH]; 
  assign data_value[36] = 32'h0000_0001 << data_1x49[37*EXP_WIDTH-1 : 36*EXP_WIDTH]; 
  assign data_value[37] = 32'h0000_0001 << data_1x49[38*EXP_WIDTH-1 : 37*EXP_WIDTH]; 
  assign data_value[38] = 32'h0000_0001 << data_1x49[39*EXP_WIDTH-1 : 38*EXP_WIDTH]; 
  assign data_value[39] = 32'h0000_0001 << data_1x49[40*EXP_WIDTH-1 : 39*EXP_WIDTH]; 
  assign data_value[40] = 32'h0000_0001 << data_1x49[41*EXP_WIDTH-1 : 40*EXP_WIDTH]; 
  assign data_value[41] = 32'h0000_0001 << data_1x49[42*EXP_WIDTH-1 : 41*EXP_WIDTH]; 
  assign data_value[42] = 32'h0000_0001 << data_1x49[43*EXP_WIDTH-1 : 42*EXP_WIDTH]; 
  assign data_value[43] = 32'h0000_0001 << data_1x49[44*EXP_WIDTH-1 : 43*EXP_WIDTH]; 
  assign data_value[44] = 32'h0000_0001 << data_1x49[45*EXP_WIDTH-1 : 44*EXP_WIDTH]; 
  assign data_value[45] = 32'h0000_0001 << data_1x49[46*EXP_WIDTH-1 : 45*EXP_WIDTH]; 
  assign data_value[46] = 32'h0000_0001 << data_1x49[47*EXP_WIDTH-1 : 46*EXP_WIDTH]; 
  assign data_value[47] = 32'h0000_0001 << data_1x49[48*EXP_WIDTH-1 : 47*EXP_WIDTH]; 
  assign data_value[48] = 32'h0000_0001 << data_1x49[49*EXP_WIDTH-1 : 48*EXP_WIDTH]; 
//  assign data_value_v2  = 32'h0000_0001 << data_v2;
  
  assign _data_value_sum = data_value[0 ] | data_value[1 ] | data_value[2 ] | data_value[3 ] | data_value[4 ] | data_value[5 ] | data_value[6 ] |  
                          data_value[7 ] | data_value[8 ] | data_value[9 ] | data_value[10] | data_value[11] | data_value[12] | data_value[13] |  
                          data_value[14] | data_value[15] | data_value[16] | data_value[17] | data_value[18] | data_value[19] | data_value[20] |  
                          data_value[21] | data_value[22] | data_value[23] | data_value[24] | data_value[25] | data_value[26] | data_value[27] |  
                          data_value[28] | data_value[29] | data_value[30] | data_value[31] | data_value[32] | data_value[33] | data_value[34] |  
                          data_value[35] | data_value[36] | data_value[37] | data_value[38] | data_value[39] | data_value[40] | data_value[41] |  
                          data_value[42] | data_value[43] | data_value[44] | data_value[45] | data_value[46] | data_value[47] | data_value[48];
//                          | data_value_v2 ;  
  reg [32-1:0]  data_value_sum;
  reg           _data_max_valid;  
  always@(posedge clk) begin
    if(max_en) begin
      data_value_sum <= _data_value_sum;
      _data_max_valid <= 1'b1;
    end else begin
      data_value_sum <= 30'b0;
      _data_max_valid <= 1'b0;
    end
  end
  //leading zero counter
  always@(data_value_sum) begin
    cnt0[4] = data_value_sum[31:16] == 16'b0;
    val16   = cnt0[4]? data_value_sum[15:0] : data_value_sum[31:16];
    cnt0[3] = val16[15:8] == 8'b0;
    val8    = cnt0[3]? val16[7:0] : val16[15:8];
    cnt0[2] = val8[7:4] == 4'b0;
    val4    = cnt0[2]? val8[3:0] : val8[7:4];
    cnt0[1] = val4[3:2] == 2'b0;
    cnt0[0] = cnt0[1]? ~val4[1] : ~val4[3];
  end
  
//  always@(max_en or cnt0) begin
//    if(max_en) begin
//      data_max = {5'd31 - cnt0};
//    end else begin
//      data_max = 5'd0;
//    end
//  end

  always@(posedge clk) begin
    data_max <= {5'd31 - cnt0};
    data_max_valid <= _data_max_valid;
  end
  
endmodule
