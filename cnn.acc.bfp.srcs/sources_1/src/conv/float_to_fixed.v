`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: zhanghs
// 
// Create Date: 2018/08/27 10:36:16
// Module Name: float_to_fixed
// Description: Convert floating point numbers to fixed-point numbers.
//
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module float_to_fixed(
  input  wire          clk,
//  input  wire          rst_n,
  input  wire [15:0]   datain,
  input  wire [4:0]    expin,
//  input  wire          datain_valid,
//  output reg           dataout_valid,
//  output reg  [7:0]    dataout_reg,
  output reg [7:0]    dataout
);

  wire [4:0]   _exp_diff;
  wire [10:0]  _content;
  reg  [10:0]  _content_tmp;
  assign _exp_diff = expin - datain[14:10];
  assign _content = (datain[14:0]==15'd0) ? 11'd0 : {1'b1, datain[9:0]}; 
  always@(_content or _exp_diff) begin
      case(_exp_diff) 
        5'd0:  _content_tmp = _content;
        5'd1:  _content_tmp = {1'b0, _content[10:1]};
        5'd2:  _content_tmp = {2'b0, _content[10:2]};
        5'd3:  _content_tmp = {3'b0, _content[10:3]};
        5'd4:  _content_tmp = {4'b0, _content[10:4]};
        5'd5:  _content_tmp = {5'b0, _content[10:5]};
        5'd6:  _content_tmp = {6'b0, _content[10:6]};
        5'd7:  _content_tmp = {7'b0, _content[10:7]};
        5'd8:  _content_tmp = {8'b0, _content[10:8]};
        5'd9:  _content_tmp = {9'b0, _content[10:9]};
        5'd10: _content_tmp = {10'b0, _content[10]};
        default: _content_tmp = {11'b0};
      endcase
    end
  
  wire [9:0]    _data_orig_tmp;
  wire [7:0]    _data_orig;
  wire [7:0]    _dataout;
  assign _data_orig_tmp = _content_tmp[10:2] + _content_tmp[4] + 1'b1;
  assign _data_orig = _data_orig_tmp[9] ? {1'b0, _content_tmp[10:4]} : {1'b0, _data_orig_tmp[8:2]};
  assign _dataout = datain[15] ? (~_data_orig + 1'b1) : _data_orig;
  
//  always@(posedge clk) begin
//    if(datain_valid) begin
//      dataout <= _dataout;
//      dataout_valid <= 1'b1;
//    end else begin
//      dataout <= 8'b0;
//      dataout_valid <= 1'b0;
//    end
//  end
  always@(posedge clk) begin
//    dataout_valid <= datain_valid;
    dataout <= _dataout;
  end
 
endmodule




