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

module LZC_v2(
  input  wire [29-1:0]       data_in,
  input  wire                data_in_valid,
  output wire [4:0]          leading_zero_num
);

  //leading zero counter
  wire [6:0]    data_in_hh;
  wire [6:0]    data_in_h;
  wire [6:0]    data_in_l;
  wire [6:0]    data_in_ll;
  reg  [2:0]    leading_zero_num_hh;
  reg  [2:0]    leading_zero_num_h;
  reg  [2:0]    leading_zero_num_l;
  reg  [2:0]    leading_zero_num_ll;
  reg  [4:0]    _leading_zero_num;

  assign data_in_hh = data_in[27:21]; 
  assign data_in_h  = data_in[20:14];
  assign data_in_l  = data_in[13:7];
  assign data_in_ll = data_in[6:0];
  
  assign leading_zero_num = _leading_zero_num;
     
  always@(data_in or data_in_valid) begin
    casex(data_in_hh)
      7'b1xxxxxx: leading_zero_num_hh = 3'd0;
      7'b01xxxxx: leading_zero_num_hh = 3'd1;
      7'b001xxxx: leading_zero_num_hh = 3'd2;
      7'b0001xxx: leading_zero_num_hh = 3'd3;
      7'b00001xx: leading_zero_num_hh = 3'd4;
      7'b000001x: leading_zero_num_hh = 3'd5;
      7'b0000001: leading_zero_num_hh = 3'd6;
      7'b0000000: leading_zero_num_hh = 3'd7;
    endcase
    casex(data_in_h)
      7'b1xxxxxx: leading_zero_num_h = 3'd0;
      7'b01xxxxx: leading_zero_num_h = 3'd1;
      7'b001xxxx: leading_zero_num_h = 3'd2;
      7'b0001xxx: leading_zero_num_h = 3'd3;
      7'b00001xx: leading_zero_num_h = 3'd4;
      7'b000001x: leading_zero_num_h = 3'd5;
      7'b0000001: leading_zero_num_h = 3'd6;
      7'b0000000: leading_zero_num_h = 3'd7;
    endcase
    casex(data_in_l)
      7'b1xxxxxx: leading_zero_num_l = 3'd0;
      7'b01xxxxx: leading_zero_num_l = 3'd1;
      7'b001xxxx: leading_zero_num_l = 3'd2;
      7'b0001xxx: leading_zero_num_l = 3'd3;
      7'b00001xx: leading_zero_num_l = 3'd4;
      7'b000001x: leading_zero_num_l = 3'd5;
      7'b0000001: leading_zero_num_l = 3'd6;
      7'b0000000: leading_zero_num_l = 3'd7;
    endcase
    casex(data_in_ll)
      7'b1xxxxxx: leading_zero_num_ll = 3'd0;
      7'b01xxxxx: leading_zero_num_ll = 3'd1;
      7'b001xxxx: leading_zero_num_ll = 3'd2;
      7'b0001xxx: leading_zero_num_ll = 3'd3;
      7'b00001xx: leading_zero_num_ll = 3'd4;
      7'b000001x: leading_zero_num_ll = 3'd5;
      7'b0000001: leading_zero_num_ll = 3'd6;
      7'b0000000: leading_zero_num_ll = 3'd7;
    endcase
  end
  
  always@(leading_zero_num_hh or leading_zero_num_h or leading_zero_num_l or leading_zero_num_ll) begin
    if(leading_zero_num_hh == 3'd7) begin
      if(leading_zero_num_h == 3'd7) begin
        if(leading_zero_num_l == 3'd7) begin
            _leading_zero_num = leading_zero_num_hh + leading_zero_num_h + leading_zero_num_l + leading_zero_num_ll;
        end else begin
          _leading_zero_num = leading_zero_num_hh + leading_zero_num_h + leading_zero_num_l;
        end
      end else begin
        _leading_zero_num = leading_zero_num_hh + leading_zero_num_h;
      end
    end else begin
      _leading_zero_num = leading_zero_num_hh;
    end
  end

endmodule
