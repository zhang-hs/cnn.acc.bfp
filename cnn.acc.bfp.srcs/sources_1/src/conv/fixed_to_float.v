`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/25 21:14:10 
// Module Name: fixed_to_float 
// Description: Convert fixed point numbers to floating point numbers.
//              "datain" is in the form of complements, and there is no negative number, 
//              all numbers input are positive after relu activation.
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

//module fixed_to_float #( //period(pipeline stage):2 clks
//  parameter FP_WIDTH  = 16,
//  parameter MID_WIDTH = 29,
//  parameter EXP_WIDTH = 5
//)(
//  input  wire                     clk,
//  input  wire [MID_WIDTH-1:0]     datain, 
//  input  wire [EXP_WIDTH:0]       exp_bias, //exp_bottom+exp_ker, with and offset of 30
//  output reg [FP_WIDTH-1:0]       dataout,
//  output reg [EXP_WIDTH-1:0]      dataout_exp
//);

//  wire [4:0]        _lzn; //leading zero number
//  LZC lzc_u(
//    .data_in(datain),
//    .leading_zero_num(_lzn)
//  );
  
//  reg  [4:0]        _exp;
//  wire [5:0]        _exp_tmp;
//  assign _exp_tmp = exp_bias - {1'b0,_lzn};
//  always@(exp_bias or _lzn or _exp_tmp) begin
//    if(_lzn == 5'd28) begin //if((_leading_zero_num == 5'd28) || (_exp_bias < _leading_zero_num)) begin
//      _exp = 5'd0;
//    end else if(_exp_tmp > 6'd31) begin
//      _exp = 5'd31;
//    end else begin
//      _exp = _exp_tmp[4:0]; //5'd30 - _leading_zero_num + (exp_bias - 6'd30);
//    end
//  end
  
//  wire [26:0]    _content; 
//  assign _content = datain[26:0] << _lzn; //datain[27:0] << (_lzn+1)
    
//  wire [12:0]    _mant_tmp;
//  wire [9:0]     _mant;
//  assign _mant_tmp = _content[26:15] + _content[17] + 1'b1;
//  assign _mant = _mant_tmp[12] ? _content[26:17] : _mant_tmp[11:2];
  
//  always@(posedge clk) begin
//    dataout <= {1'b0, _exp, _mant};
//    dataout_exp <= _exp;
//  end
  
//endmodule


module fixed_to_float #( //period(pipeline stage):2 clks
  parameter FP_WIDTH  = 16,
  parameter MID_WIDTH = 29,
  parameter EXP_WIDTH = 5
)(
  input  wire                     clk,
  input  wire [MID_WIDTH-1:0]     datain, 
//  input  wire                     datain_valid,
  input  wire [EXP_WIDTH:0]       exp_bias, //exp_bottom+exp_ker, with and offset of 30
//  output reg                      dataout_valid,
  output reg [FP_WIDTH-1:0]       dataout,
  output reg [EXP_WIDTH-1:0]      dataout_exp
);

  //scheme 1: with leading_zero_counter
  //--------------------------------------------------------------
  reg  [MID_WIDTH-1:0]      _datain;
  reg  [EXP_WIDTH:0]        _exp_bias;
  always@(posedge clk) begin
      _datain <= datain;
      _exp_bias <= exp_bias;
//      _datain_valid_reg <= datain_valid;
  end

  wire [4:0]        _lzn; //leading zero number
  LZC lzc_u(
    .data_in(_datain),
    .leading_zero_num(_lzn)
  );
  
  reg  [4:0]        _exp;
  wire [5:0]        _exp_tmp;
  assign _exp_tmp = _exp_bias - {1'b0,_lzn};
  always@(_exp_bias or _lzn or _exp_tmp) begin
    if(_lzn == 5'd28) begin //if((_leading_zero_num == 5'd28) || (_exp_bias < _leading_zero_num)) begin
      _exp = 5'd0;
    end else if(_exp_tmp > 6'd31) begin
      _exp = 5'd31;
    end else begin
      _exp = _exp_tmp[4:0]; //5'd30 - _leading_zero_num + (exp_bias - 6'd30);
    end
  end
  
  wire [26:0]    _content; 
  assign _content = _datain[26:0] << _lzn; //datain[27:0] << (_lzn+1)
    
  wire [12:0]    _mant_tmp;
  wire [9:0]     _mant;
  assign _mant_tmp = _content[26:15] + _content[17] + 1'b1;
  assign _mant = _mant_tmp[12] ? _content[26:17] : _mant_tmp[11:2];
  
  always@(posedge clk) begin
      dataout <= {1'b0, _exp, _mant};
      dataout_exp <= _exp;
//      dataout_valid <= _datain_valid_reg;
  end
  //-------------------------------------------------------------------------

  
endmodule
