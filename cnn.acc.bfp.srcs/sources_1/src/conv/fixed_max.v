`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/11/11 21:46:54
// Module Name: fixed_max
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: compare two fixed number
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module fixed_max #(
  parameter MID_WIDTH = 29
)(
  // input data
  input  wire [MID_WIDTH-1 : 0]     a1,
  input  wire [MID_WIDTH-1 : 0]     a2,
  input  wire                       en,
  // output data
  output wire [MID_WIDTH-1 : 0]     max_o
);
  reg  _m; // larger data index, 0 -- a1, 1 -- a2
  assign max_o = _m ? a2 : a1;
  wire [MID_WIDTH-1:0] _diff; // result of a minus b
  assign _diff = {1'b0,a1[MID_WIDTH-2:0]} - {1'b0,a2[MID_WIDTH-2:0]};
  
  always@(a1 or a2 or _diff or en) begin
    if(en) begin
      if(a1[MID_WIDTH-1] == a2[MID_WIDTH-1]) begin
        if(a1[MID_WIDTH-1] == 1'b0) begin
        // positive values
          if(_diff[MID_WIDTH-1] == 1'b0) begin
            _m = 1'b0;
          end else begin
            _m = 1'b1;
          end
        end else begin
        // negative values
          if(_diff[MID_WIDTH-1] == 1'b1) begin
            _m = 1'b0;
          end else begin
            _m = 1'b1;
          end
        end
      end else begin
        if(a1[MID_WIDTH-1] == 1'b0) begin
        // a1 is positive
          _m = 1'b0;
        end else begin
          _m = 1'b1; //relu
//          _m = 1'b0; //no relu
        end
      end
    end else begin
      _m = 1'b0;
    end
  end 

endmodule
