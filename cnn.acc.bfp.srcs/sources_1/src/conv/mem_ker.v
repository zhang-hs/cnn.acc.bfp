`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////: 
// Engineer: zhanghs
// 
// Create Date: 2018/10/29 22:19:04
// Module Name: mem_ker
// Project Name: cnn.bfp.acc
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: read/write from/to param weight reg
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module mem_ker#(
  parameter DATA_WIDTH  = 8,
  parameter K_C      = 64,
  parameter K_H      = 3,
  parameter K_W      = 3  
)(
  input  wire                                           clk,
  input  wire                                           rst_n,
  input  wire                                           mem_ker_valid,      // kernel data valid
  input  wire                                           mem_ker_last,       // last kernel data burst
  //input  wire                                           mem_ker_burst_cnt,  // 
  input  wire[511:0]                                    mem_ker_i,          // kernel data burst from ddr
  output reg [K_C*K_H*K_W*DATA_WIDTH-1:0]               mem_ker_o           // ker_channels*ker_height*ker_width
);

  localparam BURST_LEN  = 8;
  localparam MAX_NUM_OF_CHANNELS  = 512;
  localparam DDR_BURST_DATA_WIDTH = 512;
  localparam NUM_OF_DATA_IN_1_BURST =  DDR_BURST_DATA_WIDTH / DATA_WIDTH; //64
  
  reg  [3:0]            _mem_ker_offset; // 0~3x3-1
  // kernel memory address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_ker_offset <= 4'h0;
    end else begin
      // increment
      if(mem_ker_valid) begin
        _mem_ker_offset <= _mem_ker_offset + 1'b1;
      end
      // reset
      if(mem_ker_last) begin
        _mem_ker_offset <= 4'h0;
      end
    end
  end
 
  // memory data
  always@(posedge clk) begin
    if(mem_ker_valid) begin
      case(_mem_ker_offset)
        4'd0: mem_ker_o[64 *DATA_WIDTH-1 :  0*DATA_WIDTH]  <= mem_ker_i;
        4'd1: mem_ker_o[128*DATA_WIDTH-1 : 64*DATA_WIDTH]  <= mem_ker_i;
        4'd2: mem_ker_o[192*DATA_WIDTH-1 : 128*DATA_WIDTH] <= mem_ker_i;
        4'd3: mem_ker_o[256*DATA_WIDTH-1 : 192*DATA_WIDTH] <= mem_ker_i;
        4'd4: mem_ker_o[320*DATA_WIDTH-1 : 256*DATA_WIDTH] <= mem_ker_i;
        4'd5: mem_ker_o[384*DATA_WIDTH-1 : 320*DATA_WIDTH] <= mem_ker_i;
        4'd6: mem_ker_o[448*DATA_WIDTH-1 : 384*DATA_WIDTH] <= mem_ker_i;
        4'd7: mem_ker_o[512*DATA_WIDTH-1 : 448*DATA_WIDTH] <= mem_ker_i;
        4'd8: mem_ker_o[576*DATA_WIDTH-1 : 512*DATA_WIDTH] <= mem_ker_i;
      endcase
    end
  end

endmodule




//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////: 
//// Engineer: zhanghs
//// 
//// Create Date: 2018/10/29 22:19:04
//// Module Name: mem_ker
//// Project Name: cnn.bfp.acc
//// Target Devices: vc709
//// Tool Versions: vivado 2018.1
//// Description: read/write from/to param weight reg
//// 
//// Revision 0.01 - File Created
////////////////////////////////////////////////////////////////////////////////////

//module mem_ker#(
//  parameter DATA_WIDTH  = 8,
//  parameter K_C      = 64,
//  parameter K_H      = 3,
//  parameter K_W      = 3  
//)(
//  input  wire                                           clk,
//  input  wire                                           rst_n,
//  input  wire                                           mem_ker_valid,      // kernel data valid
//  input  wire                                           mem_ker_last,       // last kernel data burst
//  //input  wire                                           mem_ker_burst_cnt,  // 
//  input  wire[511:0]                                    mem_ker_i,          // kernel data burst from ddr
//  output wire[K_C*K_H*K_W*DATA_WIDTH-1:0]               mem_ker_o           // ker_channels*ker_height*ker_width
//);

//  localparam BURST_LEN  = 8;
//  localparam MAX_NUM_OF_CHANNELS  = 512;
//  localparam DDR_BURST_DATA_WIDTH = 512;
//  localparam NUM_OF_DATA_IN_1_BURST =  DDR_BURST_DATA_WIDTH / DATA_WIDTH; //64
  
//  //scheme 1:
//  reg  [DATA_WIDTH-1:0] _mem_ker[0:K_C*K_H*K_W-1];
//  reg  [9:0]            _mem_ker_offset;
////  reg  [511:0]          _mem_ker_reg;
 
//  // kernel memory address
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _mem_ker_offset <= 10'h0;
//    end else begin
//      // increment
//      if(mem_ker_valid) begin
//        _mem_ker_offset <= _mem_ker_offset + NUM_OF_DATA_IN_1_BURST;
//      end
//      // reset
//      if(mem_ker_last) begin
//        _mem_ker_offset <= 10'h0;
//      end
//    end
//  end
 
//  // memory data
//  always@(posedge clk) begin
//    if(mem_ker_valid) begin
//      {_mem_ker[_mem_ker_offset+63],_mem_ker[_mem_ker_offset+62],_mem_ker[_mem_ker_offset+61],_mem_ker[_mem_ker_offset+60],
//       _mem_ker[_mem_ker_offset+59],_mem_ker[_mem_ker_offset+58],_mem_ker[_mem_ker_offset+57],_mem_ker[_mem_ker_offset+56],
//       _mem_ker[_mem_ker_offset+55],_mem_ker[_mem_ker_offset+54],_mem_ker[_mem_ker_offset+53],_mem_ker[_mem_ker_offset+52],
//       _mem_ker[_mem_ker_offset+51],_mem_ker[_mem_ker_offset+50],_mem_ker[_mem_ker_offset+49],_mem_ker[_mem_ker_offset+48],
//       _mem_ker[_mem_ker_offset+47],_mem_ker[_mem_ker_offset+46],_mem_ker[_mem_ker_offset+45],_mem_ker[_mem_ker_offset+44],
//       _mem_ker[_mem_ker_offset+43],_mem_ker[_mem_ker_offset+42],_mem_ker[_mem_ker_offset+41],_mem_ker[_mem_ker_offset+40],
//       _mem_ker[_mem_ker_offset+39],_mem_ker[_mem_ker_offset+38],_mem_ker[_mem_ker_offset+37],_mem_ker[_mem_ker_offset+36],
//       _mem_ker[_mem_ker_offset+35],_mem_ker[_mem_ker_offset+34],_mem_ker[_mem_ker_offset+33],_mem_ker[_mem_ker_offset+32],
//       _mem_ker[_mem_ker_offset+31],_mem_ker[_mem_ker_offset+30],_mem_ker[_mem_ker_offset+29],_mem_ker[_mem_ker_offset+28],
//       _mem_ker[_mem_ker_offset+27],_mem_ker[_mem_ker_offset+26],_mem_ker[_mem_ker_offset+25],_mem_ker[_mem_ker_offset+24],
//       _mem_ker[_mem_ker_offset+23],_mem_ker[_mem_ker_offset+22],_mem_ker[_mem_ker_offset+21],_mem_ker[_mem_ker_offset+20],
//       _mem_ker[_mem_ker_offset+19],_mem_ker[_mem_ker_offset+18],_mem_ker[_mem_ker_offset+17],_mem_ker[_mem_ker_offset+16],
//       _mem_ker[_mem_ker_offset+15],_mem_ker[_mem_ker_offset+14],_mem_ker[_mem_ker_offset+13],_mem_ker[_mem_ker_offset+12],
//       _mem_ker[_mem_ker_offset+11],_mem_ker[_mem_ker_offset+10],_mem_ker[_mem_ker_offset+9],_mem_ker[_mem_ker_offset+8],
//       _mem_ker[_mem_ker_offset+7],_mem_ker[_mem_ker_offset+6],_mem_ker[_mem_ker_offset+5],_mem_ker[_mem_ker_offset+4],
//       _mem_ker[_mem_ker_offset+3],_mem_ker[_mem_ker_offset+2],_mem_ker[_mem_ker_offset+1],_mem_ker[_mem_ker_offset+0]} <= mem_ker_i;
////      _mem_ker[_mem_ker_offset + 0] <= mem_ker_i[( 0+1)*DATA_WIDTH-1 :  0*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 1] <= mem_ker_i[( 1+1)*DATA_WIDTH-1 :  1*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 2] <= mem_ker_i[( 2+1)*DATA_WIDTH-1 :  2*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 3] <= mem_ker_i[( 3+1)*DATA_WIDTH-1 :  3*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 4] <= mem_ker_i[( 4+1)*DATA_WIDTH-1 :  4*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 5] <= mem_ker_i[( 5+1)*DATA_WIDTH-1 :  5*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 6] <= mem_ker_i[( 6+1)*DATA_WIDTH-1 :  6*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 7] <= mem_ker_i[( 7+1)*DATA_WIDTH-1 :  7*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 8] <= mem_ker_i[( 8+1)*DATA_WIDTH-1 :  8*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset + 9] <= mem_ker_i[( 9+1)*DATA_WIDTH-1 :  9*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +10] <= mem_ker_i[(10+1)*DATA_WIDTH-1 : 10*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +11] <= mem_ker_i[(11+1)*DATA_WIDTH-1 : 11*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +12] <= mem_ker_i[(12+1)*DATA_WIDTH-1 : 12*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +13] <= mem_ker_i[(13+1)*DATA_WIDTH-1 : 13*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +14] <= mem_ker_i[(14+1)*DATA_WIDTH-1 : 14*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +15] <= mem_ker_i[(15+1)*DATA_WIDTH-1 : 15*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +16] <= mem_ker_i[(16+1)*DATA_WIDTH-1 : 16*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +17] <= mem_ker_i[(17+1)*DATA_WIDTH-1 : 17*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +18] <= mem_ker_i[(18+1)*DATA_WIDTH-1 : 18*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +19] <= mem_ker_i[(19+1)*DATA_WIDTH-1 : 19*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +20] <= mem_ker_i[(20+1)*DATA_WIDTH-1 : 20*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +21] <= mem_ker_i[(21+1)*DATA_WIDTH-1 : 21*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +22] <= mem_ker_i[(22+1)*DATA_WIDTH-1 : 22*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +23] <= mem_ker_i[(23+1)*DATA_WIDTH-1 : 23*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +24] <= mem_ker_i[(24+1)*DATA_WIDTH-1 : 24*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +25] <= mem_ker_i[(25+1)*DATA_WIDTH-1 : 25*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +26] <= mem_ker_i[(26+1)*DATA_WIDTH-1 : 26*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +27] <= mem_ker_i[(27+1)*DATA_WIDTH-1 : 27*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +28] <= mem_ker_i[(28+1)*DATA_WIDTH-1 : 28*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +29] <= mem_ker_i[(29+1)*DATA_WIDTH-1 : 29*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +30] <= mem_ker_i[(30+1)*DATA_WIDTH-1 : 30*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +31] <= mem_ker_i[(31+1)*DATA_WIDTH-1 : 31*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +32] <= mem_ker_i[(32+1)*DATA_WIDTH-1 : 32*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +33] <= mem_ker_i[(33+1)*DATA_WIDTH-1 : 33*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +34] <= mem_ker_i[(34+1)*DATA_WIDTH-1 : 34*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +35] <= mem_ker_i[(35+1)*DATA_WIDTH-1 : 35*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +36] <= mem_ker_i[(36+1)*DATA_WIDTH-1 : 36*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +37] <= mem_ker_i[(37+1)*DATA_WIDTH-1 : 37*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +38] <= mem_ker_i[(38+1)*DATA_WIDTH-1 : 38*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +39] <= mem_ker_i[(39+1)*DATA_WIDTH-1 : 39*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +40] <= mem_ker_i[(40+1)*DATA_WIDTH-1 : 40*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +41] <= mem_ker_i[(41+1)*DATA_WIDTH-1 : 41*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +42] <= mem_ker_i[(42+1)*DATA_WIDTH-1 : 42*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +43] <= mem_ker_i[(43+1)*DATA_WIDTH-1 : 43*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +44] <= mem_ker_i[(44+1)*DATA_WIDTH-1 : 44*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +45] <= mem_ker_i[(45+1)*DATA_WIDTH-1 : 45*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +46] <= mem_ker_i[(46+1)*DATA_WIDTH-1 : 46*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +47] <= mem_ker_i[(47+1)*DATA_WIDTH-1 : 47*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +48] <= mem_ker_i[(48+1)*DATA_WIDTH-1 : 48*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +49] <= mem_ker_i[(49+1)*DATA_WIDTH-1 : 49*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +50] <= mem_ker_i[(50+1)*DATA_WIDTH-1 : 50*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +51] <= mem_ker_i[(51+1)*DATA_WIDTH-1 : 51*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +52] <= mem_ker_i[(52+1)*DATA_WIDTH-1 : 52*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +53] <= mem_ker_i[(53+1)*DATA_WIDTH-1 : 53*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +54] <= mem_ker_i[(54+1)*DATA_WIDTH-1 : 54*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +55] <= mem_ker_i[(55+1)*DATA_WIDTH-1 : 55*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +56] <= mem_ker_i[(56+1)*DATA_WIDTH-1 : 56*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +57] <= mem_ker_i[(57+1)*DATA_WIDTH-1 : 57*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +58] <= mem_ker_i[(58+1)*DATA_WIDTH-1 : 58*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +59] <= mem_ker_i[(59+1)*DATA_WIDTH-1 : 59*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +60] <= mem_ker_i[(60+1)*DATA_WIDTH-1 : 60*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +61] <= mem_ker_i[(61+1)*DATA_WIDTH-1 : 61*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +62] <= mem_ker_i[(62+1)*DATA_WIDTH-1 : 62*DATA_WIDTH];
////      _mem_ker[_mem_ker_offset +63] <= mem_ker_i[(63+1)*DATA_WIDTH-1 : 63*DATA_WIDTH];
//    end
//  end

//  // output
//  genvar i;
//  generate
//    for(i=0; i<K_C*K_H*K_W; i=i+1) begin
//      assign mem_ker_o[(i+1)*DATA_WIDTH-1: i*DATA_WIDTH] = _mem_ker[i];
//    end
//  endgenerate

//endmodule
