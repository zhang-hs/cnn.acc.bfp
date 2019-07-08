`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: zhanghs
// 
// Create Date: 2018/11/09 10:36:16
// Module Name: float_to_fixed_bias
// Description: Convert floating point numbers to fixed-point numbers.
//
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

//module float_to_fixed_bias(
//  input  wire          clk,
//  input  wire [15:0]   datain,
//  input  wire [5:0]    expin, //with an offsete of 30
//  output reg  [28:0]   dataout
//);
  
//  wire [10:0]   _content;
//  wire [5:0]    _exp_diff;
//  assign _content = (datain[14:0]==15'd0) ? 11'd0 : {1'b1, datain[9:0]};//<--mark, this could be time-consuming 
//  assign _exp_diff = expin - ({1'b0,datain[14:10]} + 6'd15); //exp of bias(<=3) is no bigger than exp_bottom+exp_ker
  
//  reg  [14:0]   _content_tmp;
//  always@(_content or _exp_diff) begin
//      case(_exp_diff) //Execute the shift operation before rounding
//        6'd0:  _content_tmp = {_content, 4'b0}; //Move the first 1 to the position of the 13th bit, and exp has an offset of 12.The last 2bits are for round to even
//        6'd1:  _content_tmp = {1'b0, _content, 3'b0};
//        6'd2:  _content_tmp = {2'b0, _content, 2'b0};
//        6'd3:  _content_tmp = {3'b0, _content, 1'b0};
//        6'd4:  _content_tmp = {4'b0, _content};
//        6'd5:  _content_tmp = {5'b0, _content[10:1]};
//        6'd6:  _content_tmp = {6'b0, _content[10:2]};
//        6'd7:  _content_tmp = {7'b0, _content[10:3]};
//        6'd8:  _content_tmp = {8'b0, _content[10:4]};
//        6'd9:  _content_tmp = {9'b0, _content[10:5]};
//        6'd10: _content_tmp = {10'b0,_content[10:6]};
//        6'd11: _content_tmp = {11'b0,_content[10:7]};
//        6'd12: _content_tmp = {12'b0,_content[10:8]};
//        6'd13: _content_tmp = {13'b0,_content[10:9]};
//        6'd14: _content_tmp = {14'b0,_content[10]};
//        default: _content_tmp = {15'b0};
//      endcase
//   end
  
//  wire [15:0]    _data_orig_tmp;
//  wire [28:0]    _data_orig;
//  wire [28:0]    _dataout;
//  assign _data_orig_tmp = {1'b0, _content_tmp} + {15'b0, _content_tmp[2]} + 16'b1;
//  assign _data_orig = {15'b0, _data_orig_tmp[15:2]};
//  assign _dataout = datain[15] ? (~_data_orig + 1'b1) : _data_orig;
  
//  always@(posedge clk) begin
//    dataout <= _dataout;
//  end

//endmodule


module float_to_fixed_bias(
  input  wire          clk,
  input  wire [15:0]   datain,
  input  wire [5:0]    expin, //with an offsete of 30
//  input  wire          datain_valid,
//  output reg           dataout_valid,
  output reg  [28:0]   dataout
//  output wire [28:0]   dataout
);
  
  wire [10:0]   _content;
  wire [5:0]    _exp_diff;
  assign _content = (datain[14:0]==15'd0) ? 11'd0 : {1'b1, datain[9:0]};//<--mark, this could be time-consuming 
  assign _exp_diff = expin - ({1'b0,datain[14:10]} + 6'd15); //exp of bias(<=3) is no bigger than exp_bottom+exp_ker
  
  reg [10:0]  _content_reg;
  reg [5:0]   _exp_diff_reg;
  reg         _sign_reg;
//  reg         _datain_valid_reg;
  always@(posedge clk) begin
//     _datain_valid_reg <= datain_valid;
     _content_reg <= _content;
     _exp_diff_reg <= _exp_diff;
     _sign_reg <= datain[15];
  end
  
  reg  [14:0]   _content_tmp;
  always@(_content_reg or _exp_diff_reg) begin
      case(_exp_diff_reg) //Execute the shift operation before rounding
        6'd0:  _content_tmp = {_content_reg, 4'b0}; //Move the first 1 to the position of the 13th bit, and exp has an offset of 12.The last 2bits are for round to even
        6'd1:  _content_tmp = {1'b0, _content_reg, 3'b0};
        6'd2:  _content_tmp = {2'b0, _content_reg, 2'b0};
        6'd3:  _content_tmp = {3'b0, _content_reg, 1'b0};
        6'd4:  _content_tmp = {4'b0, _content_reg};
        6'd5:  _content_tmp = {5'b0, _content_reg[10:1]};
        6'd6:  _content_tmp = {6'b0, _content_reg[10:2]};
        6'd7:  _content_tmp = {7'b0, _content_reg[10:3]};
        6'd8:  _content_tmp = {8'b0, _content_reg[10:4]};
        6'd9:  _content_tmp = {9'b0, _content_reg[10:5]};
        6'd10: _content_tmp = {10'b0,_content_reg[10:6]};
        6'd11: _content_tmp = {11'b0,_content_reg[10:7]};
        6'd12: _content_tmp = {12'b0,_content_reg[10:8]};
        6'd13: _content_tmp = {13'b0,_content_reg[10:9]};
        6'd14: _content_tmp = {14'b0,_content_reg[10]};
        default: _content_tmp = {15'b0};
      endcase
   end
  
  wire [15:0]    _data_orig_tmp;
  wire [28:0]    _data_orig;
  wire [28:0]    _dataout;
  assign _data_orig_tmp = {1'b0, _content_tmp} + {15'b0, _content_tmp[2]} + 16'b1;
  assign _data_orig = {15'b0, _data_orig_tmp[15:2]};
  assign _dataout = _sign_reg ? (~_data_orig + 1'b1) : _data_orig;
  
  always@(posedge clk) begin
//    dataout_valid <= _datain_valid_reg;
    dataout <= _dataout;
  end

endmodule



//module float_to_fixed_bias(
//  input  wire          clk,
//  input  wire [15:0]   datain,
//  input  wire [5:0]    expin, //with an offsete of 30
//  input  wire          datain_valid,
//  output reg           dataout_valid,
//  output reg  [28:0]   dataout
////  output wire [28:0]   dataout
//);
  
//  wire [10:0]   _content;
//  wire [5:0]    _exp_diff;
//  wire [4:0]    _exp;
//  assign _content = (datain[14:0]==15'd0) ? 11'd0 : {1'b1, datain[9:0]};//<--mark, this could be time-consuming 
//  assign _exp_diff = expin - ({1'b0,datain[14:10]} + 6'd15); //exp of bias(<=3) is no bigger than exp_bottom+exp_ker
//  assign _exp = datain[14:10];
  
//  reg  [14:0]   _content_tmp;
//  always@(_content or _exp_diff) begin
//      case(_exp_diff) //Execute the shift operation before rounding
//        6'd0:  _content_tmp = {_content, 4'b0}; //Move the first 1 to the position of the 13th bit, and exp has an offset of 12.The last 2bits are for round to even
//        6'd1:  _content_tmp = {1'b0, _content, 3'b0};
//        6'd2:  _content_tmp = {2'b0, _content, 2'b0};
//        6'd3:  _content_tmp = {3'b0, _content, 1'b0};
//        6'd4:  _content_tmp = {4'b0, _content};
//        6'd5:  _content_tmp = {5'b0, _content[10:1]};
//        6'd6:  _content_tmp = {6'b0, _content[10:2]};
//        6'd7:  _content_tmp = {7'b0, _content[10:3]};
//        6'd8:  _content_tmp = {8'b0, _content[10:4]};
//        6'd9:  _content_tmp = {9'b0, _content[10:5]};
//        6'd10: _content_tmp = {10'b0,_content[10:6]};
//        6'd11: _content_tmp = {11'b0,_content[10:7]};
//        6'd12: _content_tmp = {12'b0,_content[10:8]};
//        6'd13: _content_tmp = {13'b0,_content[10:9]};
//        6'd14: _content_tmp = {14'b0,_content[10]};
//        default: _content_tmp = {15'b0};
//      endcase
//   end
   
//  reg [14:0]  _content_tmp_reg;
//  reg         _sign_reg;
//  reg         _datain_valid_reg;
//  always@(posedge clk) begin
//     _datain_valid_reg <= datain_valid;
//     _content_tmp_reg <= _content_tmp;
//     _sign_reg <= datain[15];
//  end
  
//  wire [15:0]    _data_orig_tmp;
//  wire [28:0]    _data_orig;
//  wire [28:0]    _dataout;
//  assign _data_orig_tmp = {1'b0, _content_tmp_reg} + {15'b0, _content_tmp_reg[2]} + 16'b1;
//  assign _data_orig = {15'b0, _data_orig_tmp[15:2]};
//  assign _dataout = _sign_reg ? (~_data_orig + 1'b1) : _data_orig;
  
//  always@(posedge clk) begin
//    dataout_valid <= _datain_valid_reg;
//    dataout <= _dataout;
//  end

//endmodule


