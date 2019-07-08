`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/26 09:03:11 
// Module Name: leading_zero_counter
// Description: counting the number of leading zeros.
//              dichotomy.
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module LZC(
//  input  wire               clk,
  input  wire [28:0]        data_in, //positive num
//  input  wire               data_in_valid,
//  output reg                lzc_valid,
//  output reg [4:0]          leading_zero_num
  output wire [4:0]         leading_zero_num
);

//scheme 2
//  wire [5:0] _lzc;
  wire [3:0] _data_7, _data_6, _data_5, _data_4, _data_3, _data_2, _data_1;
  reg  [2:0] _cnt_7, _cnt_6, _cnt_5, _cnt_4, _cnt_3, _cnt_2, _cnt_1;
  assign {_data_7, _data_6, _data_5, _data_4, _data_3, _data_2, _data_1} = data_in[27:0];
  
  always@(_data_7) begin
    if(_data_7 == 4'b0) begin
      _cnt_7 = 3'd4;
    end else begin
      _cnt_7[2] = 1'b0;
      _cnt_7[1] = _data_7[3:2] == 2'b0;
      _cnt_7[0] = _cnt_7[1] ? ~_data_7[1] : ~_data_7[3];
    end
  end
  always@(_data_6) begin
    if(_data_6 == 4'b0) begin
      _cnt_6 = 3'd4;
    end else begin
      _cnt_6[2] = 1'b0;
      _cnt_6[1] = _data_6[3:2] == 2'b0;
      _cnt_6[0] = _cnt_6[1] ? ~_data_6[1] : ~_data_6[3];
    end
  end
  always@(_data_5) begin
    if(_data_5 == 4'b0) begin
      _cnt_5 = 3'd4;
    end else begin
      _cnt_5[2] = 1'b0;
      _cnt_5[1] = _data_5[3:2] == 2'b0;
      _cnt_5[0] = _cnt_5[1] ? ~_data_5[1] : ~_data_5[3];
    end
  end
  always@(_data_4) begin
    if(_data_4 == 4'b0) begin
      _cnt_4 = 3'd4;
    end else begin
      _cnt_4[2] = 1'b0;
      _cnt_4[1] = _data_4[3:2] == 2'b0;
      _cnt_4[0] = _cnt_4[1] ? ~_data_4[1] : ~_data_4[3];
    end
  end
  always@(_data_3) begin
    if(_data_3 == 4'b0) begin
      _cnt_3 = 3'd4;
    end else begin
      _cnt_3[2] = 1'b0;
      _cnt_3[1] = _data_3[3:2] == 2'b0;
      _cnt_3[0] = _cnt_3[1] ? ~_data_3[1] : ~_data_3[3];
    end
  end
  always@(_data_2) begin
    if(_data_2 == 4'b0) begin
      _cnt_2 = 3'd4;
    end else begin
      _cnt_2[2] = 1'b0;
      _cnt_2[1] = _data_2[3:2] == 2'b0;
      _cnt_2[0] = _cnt_2[1] ? ~_data_2[1] : ~_data_2[3];
    end
  end
  always@(_data_1) begin
    if(_data_1 == 4'b0) begin
      _cnt_1 = 3'd4;
    end else begin
      _cnt_1[2] = 1'b0;
      _cnt_1[1] = _data_1[3:2] == 2'b0;
      _cnt_1[0] = _cnt_1[1] ? ~_data_1[1] : ~_data_1[3];
    end
  end
  
  wire [2:0] _cnt_6_valid, _cnt_5_valid, _cnt_4_valid, _cnt_3_valid, _cnt_2_valid, _cnt_1_valid;
  assign _cnt_6_valid = _cnt_7[2] ? _cnt_6 : 3'd0;
  assign _cnt_5_valid = (_cnt_6[2] && _cnt_7[2]) ? _cnt_5 : 3'd0;
  assign _cnt_4_valid = (_cnt_5[2] && _cnt_6[2] && _cnt_7[2]) ? _cnt_4 : 3'd0;
  assign _cnt_3_valid = (_cnt_4[2] && _cnt_5[2] && _cnt_6[2] && _cnt_7[2]) ? _cnt_3 : 3'd0;
  assign _cnt_2_valid = (_cnt_3[2] && _cnt_4[2] && _cnt_5[2] && _cnt_6[2] && _cnt_7[2]) ? _cnt_2 : 3'd0;
  assign _cnt_1_valid = (_cnt_2[2] && _cnt_3[2] && _cnt_4[2] && _cnt_5[2] && _cnt_6[2] && _cnt_7[2]) ? _cnt_1 : 3'd0;
  
  assign leading_zero_num = _cnt_7 + _cnt_6_valid + _cnt_5_valid + _cnt_4_valid + _cnt_3_valid + _cnt_2_valid + _cnt_1_valid;
  
  
////scheme 1
//  reg  [5:0]     tmp_cnt;
//  reg  [15:0]    val16;
//  reg  [7:0]     val8;
//  reg  [3:0]     val4;
//  wire [31:0]    data_tmp;
  
//  assign data_tmp = {4'b0,data_in[27:0]};
//  always@(data_in_valid or data_tmp) begin
//    if(data_in_valid) begin
//      tmp_cnt = 6'd32;
//    end else begin
//      if(data_tmp == 32'b0) begin
//        tmp_cnt = 6'd32;
//      end else begin
//        tmp_cnt[5] = 1'b0;
//        tmp_cnt[4] = data_tmp[31:16] == 16'b0;
//        val16      = tmp_cnt[4]? data_tmp[15:0] : data_tmp[31:16];
//        tmp_cnt[3] = val16[15:8] == 8'b0;
//        val8       = tmp_cnt[3]? val16[7:0] : val16[15:8];
//        tmp_cnt[2] = val8[7:4] == 4'b0;
//        val4       = tmp_cnt[2]? val8[3:0] : val8[7:4];
//        tmp_cnt[1] = val4[3:2] == 2'b0;
//        tmp_cnt[0] = tmp_cnt[1]? ~val4[1] : ~val4[3];
//      end
//    end
//  end

//  assign leading_zero_num = tmp_cnt - 6'd4;
  

endmodule
