`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/26 09:03:11 
// Module Name: leading_zero_counter
// Description: counting the number of leading zeros.
//              normal scheme.         
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module LZC_v1 (
  input  wire [29-1:0]       data_in, //positive value
  input  wire                data_in_valid,
  output wire [4:0]          leading_zero_num
);

  reg  [4:0]         _leading_zero_num;
  assign leading_zero_num = _leading_zero_num;
  
  always@(data_in or data_in_valid) begin
    casex(data_in[27:0])
      28'b1xxxxxxxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd0;
      28'b01xxxxxxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd1;
      28'b001xxxxxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd2;
      28'b0001xxxxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd3;
      28'b00001xxxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd4;
      28'b000001xxxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd5;
      28'b0000001xxxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd6;
      28'b00000001xxxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd7;
      28'b000000001xxxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd8;
      28'b0000000001xxxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd9;
      28'b00000000001xxxxxxxxxxxxxxxxx: _leading_zero_num = 5'd10;
      28'b000000000001xxxxxxxxxxxxxxxx: _leading_zero_num = 5'd11;
      28'b0000000000001xxxxxxxxxxxxxxx: _leading_zero_num = 5'd12;
      28'b00000000000001xxxxxxxxxxxxxx: _leading_zero_num = 5'd13;
      28'b000000000000001xxxxxxxxxxxxx: _leading_zero_num = 5'd14;
      28'b0000000000000001xxxxxxxxxxxx: _leading_zero_num = 5'd15;
      28'b00000000000000001xxxxxxxxxxx: _leading_zero_num = 5'd16;
      28'b000000000000000001xxxxxxxxxx: _leading_zero_num = 5'd17;
      28'b0000000000000000001xxxxxxxxx: _leading_zero_num = 5'd18;
      28'b00000000000000000001xxxxxxxx: _leading_zero_num = 5'd19;
      28'b000000000000000000001xxxxxxx: _leading_zero_num = 5'd20;
      28'b0000000000000000000001xxxxxx: _leading_zero_num = 5'd21;
      28'b00000000000000000000001xxxxx: _leading_zero_num = 5'd22;
      28'b000000000000000000000001xxxx: _leading_zero_num = 5'd23;
      28'b0000000000000000000000001xxx: _leading_zero_num = 5'd24;
      28'b00000000000000000000000001xx: _leading_zero_num = 5'd25;
      28'b000000000000000000000000001x: _leading_zero_num = 5'd26;
      28'b0000000000000000000000000001: _leading_zero_num = 5'd27;
      28'b0000000000000000000000000000: _leading_zero_num = 5'd28;
    endcase 
  end

endmodule