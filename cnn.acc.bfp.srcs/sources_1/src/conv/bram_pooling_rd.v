`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:zhanghs 
// 
// Create Date: 2018/11/12 20:36:37
// Module Name: bram_conv_wr
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: reading pooling data from bram, through port A
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

////original
//module bram_pooling_rd#(
//  parameter MID_WIDTH = 29,
//  parameter K_C = 64,
//  parameter PORT_ADDR_WIDTH = 11
//)(
//  input  wire                                 clk,
//  input  wire                                 rst_n,
//  // addr
//  input  wire[2:0]                            bram_rd_pooling_ker_set,
//  input  wire[2:0]                            bram_rd_pooling_y,
//  input  wire[2:0]                            bram_rd_pooling_x,
//  output reg [64*PORT_ADDR_WIDTH-1 : 0]       bram_rd_pooling_addr,
//  // enable
//  input  wire                                 bram_rd_pooling_pre_en,   //in conv, port b read enable
//  output reg                                  bram_rd_pooling_en,
//  output reg                                  bram_rd_pooling_bram_valid,
//  // data
//  input  wire[64*MID_WIDTH-1:0]               bram_rd_pooling_pre,
//  output reg                                  bram_rd_pooling_data_valid,
//  output reg [64*MID_WIDTH-1:0]               bram_rd_pooling_data
//  );

//  wire[5:0]                   _bram_rd_pooling_quarter_addr;
//  reg [5:0]                   _bram_rd_pooling_shift;
//  reg [5:0]                   _bram_rd_pooling_shift1;
//  reg [5:0]                   _bram_rd_pooling_shift2;
//  reg                         _bram_rd_pooling_data_valid_0;
//  wire[PORT_ADDR_WIDTH-1 : 0] _bram_rd_pooling_addr;
//  reg [64*MID_WIDTH-1:0]      _bram_rd_pooling_pre_data;
//  reg [64*MID_WIDTH-1:0]      _bram_rd_pooling_data_0;
//  assign _bram_rd_pooling_quarter_addr = bram_rd_pooling_y*4'd7 + {1'b0,bram_rd_pooling_x};
//  assign _bram_rd_pooling_addr = {bram_rd_pooling_ker_set,2'd0}*6'd49 + _bram_rd_pooling_quarter_addr;

//  // enable
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_rd_pooling_en <= 1'b0;
//      bram_rd_pooling_bram_valid <= 1'b0;
//      _bram_rd_pooling_data_valid_0 <= 1'b0;
//      bram_rd_pooling_data_valid <= 1'b0;
//    end else begin
//      bram_rd_pooling_en            <= bram_rd_pooling_pre_en;
//      bram_rd_pooling_bram_valid    <= bram_rd_pooling_en;
//      _bram_rd_pooling_data_valid_0 <= bram_rd_pooling_bram_valid;
//      bram_rd_pooling_data_valid    <= _bram_rd_pooling_data_valid_0;
//    end
//  end
//  // address
//  always@(posedge clk) begin
//    bram_rd_pooling_addr <= {64{_bram_rd_pooling_addr}}; //address
//    _bram_rd_pooling_pre_data <= bram_rd_pooling_pre;
//    _bram_rd_pooling_shift1 <= _bram_rd_pooling_quarter_addr; //ctrl
//    _bram_rd_pooling_shift2 <= _bram_rd_pooling_shift1;
//    _bram_rd_pooling_shift  <= _bram_rd_pooling_shift2;
//    bram_rd_pooling_data    <= _bram_rd_pooling_data_0; //data read out
//  end

//  always@(_bram_rd_pooling_shift or _bram_rd_pooling_pre_data or _bram_rd_pooling_data_valid_0) begin
//    if(_bram_rd_pooling_data_valid_0) begin
//      _bram_rd_pooling_data_0 = {(64*MID_WIDTH){1'b0}};
//      case(_bram_rd_pooling_shift) //0~48
//        6'd0 : _bram_rd_pooling_data_0 =  _bram_rd_pooling_pre_data;                                                                                       
//        6'd1 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[1 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  1 *MID_WIDTH]};
//        6'd2 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[2 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  2 *MID_WIDTH]};
//        6'd3 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[3 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  3 *MID_WIDTH]};
//        6'd4 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[4 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  4 *MID_WIDTH]};
//        6'd5 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[5 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  5 *MID_WIDTH]};
//        6'd6 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[6 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  6 *MID_WIDTH]};
//        6'd7 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[7 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  7 *MID_WIDTH]};
//        6'd8 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[8 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  8 *MID_WIDTH]};
//        6'd9 : _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[9 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  9 *MID_WIDTH]};
//        6'd10: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[10*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  10*MID_WIDTH]};
//        6'd11: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[11*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  11*MID_WIDTH]};
//        6'd12: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[12*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  12*MID_WIDTH]};
//        6'd13: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[13*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  13*MID_WIDTH]};
//        6'd14: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[14*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  14*MID_WIDTH]};
//        6'd15: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[15*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  15*MID_WIDTH]};
//        6'd16: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[16*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  16*MID_WIDTH]};
//        6'd17: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[17*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  17*MID_WIDTH]};
//        6'd18: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[18*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  18*MID_WIDTH]};
//        6'd19: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[19*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  19*MID_WIDTH]};
//        6'd20: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[20*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  20*MID_WIDTH]};
//        6'd21: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[21*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  21*MID_WIDTH]};
//        6'd22: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[22*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  22*MID_WIDTH]};
//        6'd23: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[23*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  23*MID_WIDTH]};
//        6'd24: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[24*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  24*MID_WIDTH]};
//        6'd25: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[25*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  25*MID_WIDTH]};
//        6'd26: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[26*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  26*MID_WIDTH]};
//        6'd27: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[27*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  27*MID_WIDTH]};
//        6'd28: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[28*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  28*MID_WIDTH]};
//        6'd29: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[29*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  29*MID_WIDTH]};
//        6'd30: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[30*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  30*MID_WIDTH]};
//        6'd31: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[31*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  31*MID_WIDTH]};
//        6'd32: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[32*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  32*MID_WIDTH]};
//        6'd33: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[33*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  33*MID_WIDTH]};
//        6'd34: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[34*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  34*MID_WIDTH]};
//        6'd35: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[35*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  35*MID_WIDTH]};
//        6'd36: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[36*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  36*MID_WIDTH]};
//        6'd37: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[37*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  37*MID_WIDTH]};
//        6'd38: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[38*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  38*MID_WIDTH]};
//        6'd39: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[39*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  39*MID_WIDTH]};
//        6'd40: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[40*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  40*MID_WIDTH]};
//        6'd41: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[41*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  41*MID_WIDTH]};
//        6'd42: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[42*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  42*MID_WIDTH]};
//        6'd43: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[43*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  43*MID_WIDTH]};
//        6'd44: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[44*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  44*MID_WIDTH]};
//        6'd45: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[45*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  45*MID_WIDTH]};
//        6'd46: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[46*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  46*MID_WIDTH]};
//        6'd47: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[47*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  47*MID_WIDTH]};
//        6'd48: _bram_rd_pooling_data_0 = {_bram_rd_pooling_pre_data[48*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_pooling_pre_data[64*MID_WIDTH-1 :  48*MID_WIDTH]};
//      endcase
//    end else begin
//      _bram_rd_pooling_data_0 = {(64*MID_WIDTH){1'b0}};
//    end
//  end  
  
//endmodule


//avoid read at the same clock of portA writing
module bram_pooling_rd#(
  parameter MID_WIDTH = 29,
  parameter K_C = 64,
  parameter PORT_ADDR_WIDTH = 11
)(
  input  wire                                 clk,
  input  wire                                 rst_n,
  // addr
  input  wire[2:0]                            bram_rd_pooling_ker_set,
  input  wire[2:0]                            bram_rd_pooling_y,
  input  wire[2:0]                            bram_rd_pooling_x,
  output reg [64*PORT_ADDR_WIDTH-1 : 0]       bram_rd_pooling_addr,
  // enable
  input  wire                                 bram_rd_pooling_pre_en,   //in conv, port b read enable
  output reg                                  bram_rd_pooling_en,
  output reg                                  bram_rd_pooling_bram_valid,
  // data
  input  wire[64*MID_WIDTH-1:0]               bram_rd_pooling_pre,
  output reg                                  bram_rd_pooling_data_valid,
  output reg [64*MID_WIDTH-1:0]               bram_rd_pooling_data
  );

  wire[5:0]                   _bram_rd_pooling_quarter_addr;
  reg [5:0]                   _bram_rd_pooling_shift;
  reg [5:0]                   _bram_rd_pooling_shift1;
  reg [5:0]                   _bram_rd_pooling_shift2;
  reg                         _bram_rd_pooling_en_pre;
  wire[PORT_ADDR_WIDTH-1 : 0] _bram_rd_pooling_addr;
  reg [PORT_ADDR_WIDTH-1 : 0] _bram_rd_pooling_addr_reg;
    reg [64*MID_WIDTH-1:0]    _bram_rd_pooling_data_0;
  
  assign _bram_rd_pooling_quarter_addr = bram_rd_pooling_y*4'd7 + {1'b0,bram_rd_pooling_x};
  assign _bram_rd_pooling_addr = {bram_rd_pooling_ker_set,2'd0}*6'd49 + _bram_rd_pooling_quarter_addr;

  // enable
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _bram_rd_pooling_en_pre <= 1'b0;
      bram_rd_pooling_en <= 1'b0;
      bram_rd_pooling_bram_valid <= 1'b0;
      bram_rd_pooling_data_valid <= 1'b0;
    end else begin
      _bram_rd_pooling_en_pre       <= bram_rd_pooling_pre_en;
      bram_rd_pooling_en            <= _bram_rd_pooling_en_pre;
      bram_rd_pooling_bram_valid    <= bram_rd_pooling_en;
      bram_rd_pooling_data_valid    <= bram_rd_pooling_bram_valid;
    end
  end
  // address
  always@(posedge clk) begin
    _bram_rd_pooling_addr_reg <= _bram_rd_pooling_addr; //address
    bram_rd_pooling_addr <= {64{_bram_rd_pooling_addr_reg}}; 
    _bram_rd_pooling_shift1 <= _bram_rd_pooling_quarter_addr; //ctrl
    _bram_rd_pooling_shift2 <= _bram_rd_pooling_shift1;
    _bram_rd_pooling_shift  <= _bram_rd_pooling_shift2;
    bram_rd_pooling_data    <= _bram_rd_pooling_data_0; //data read out
  end

  always@(_bram_rd_pooling_shift or bram_rd_pooling_pre or bram_rd_pooling_bram_valid) begin
    if(bram_rd_pooling_bram_valid) begin
      _bram_rd_pooling_data_0 = {(64*MID_WIDTH){1'b0}};
      case(_bram_rd_pooling_shift) //0~48
        6'd0 : _bram_rd_pooling_data_0 =  bram_rd_pooling_pre;                                                                                       
        6'd1 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[1 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  1 *MID_WIDTH]};
        6'd2 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[2 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  2 *MID_WIDTH]};
        6'd3 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[3 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  3 *MID_WIDTH]};
        6'd4 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[4 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  4 *MID_WIDTH]};
        6'd5 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[5 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  5 *MID_WIDTH]};
        6'd6 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[6 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  6 *MID_WIDTH]};
        6'd7 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[7 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  7 *MID_WIDTH]};
        6'd8 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[8 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  8 *MID_WIDTH]};
        6'd9 : _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[9 *MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  9 *MID_WIDTH]};
        6'd10: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[10*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  10*MID_WIDTH]};
        6'd11: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[11*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  11*MID_WIDTH]};
        6'd12: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[12*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  12*MID_WIDTH]};
        6'd13: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[13*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  13*MID_WIDTH]};
        6'd14: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[14*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  14*MID_WIDTH]};
        6'd15: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[15*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  15*MID_WIDTH]};
        6'd16: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[16*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  16*MID_WIDTH]};
        6'd17: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[17*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  17*MID_WIDTH]};
        6'd18: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[18*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  18*MID_WIDTH]};
        6'd19: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[19*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  19*MID_WIDTH]};
        6'd20: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[20*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  20*MID_WIDTH]};
        6'd21: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[21*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  21*MID_WIDTH]};
        6'd22: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[22*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  22*MID_WIDTH]};
        6'd23: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[23*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  23*MID_WIDTH]};
        6'd24: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[24*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  24*MID_WIDTH]};
        6'd25: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[25*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  25*MID_WIDTH]};
        6'd26: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[26*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  26*MID_WIDTH]};
        6'd27: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[27*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  27*MID_WIDTH]};
        6'd28: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[28*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  28*MID_WIDTH]};
        6'd29: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[29*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  29*MID_WIDTH]};
        6'd30: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[30*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  30*MID_WIDTH]};
        6'd31: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[31*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  31*MID_WIDTH]};
        6'd32: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[32*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  32*MID_WIDTH]};
        6'd33: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[33*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  33*MID_WIDTH]};
        6'd34: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[34*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  34*MID_WIDTH]};
        6'd35: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[35*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  35*MID_WIDTH]};
        6'd36: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[36*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  36*MID_WIDTH]};
        6'd37: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[37*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  37*MID_WIDTH]};
        6'd38: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[38*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  38*MID_WIDTH]};
        6'd39: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[39*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  39*MID_WIDTH]};
        6'd40: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[40*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  40*MID_WIDTH]};
        6'd41: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[41*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  41*MID_WIDTH]};
        6'd42: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[42*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  42*MID_WIDTH]};
        6'd43: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[43*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  43*MID_WIDTH]};
        6'd44: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[44*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  44*MID_WIDTH]};
        6'd45: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[45*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  45*MID_WIDTH]};
        6'd46: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[46*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  46*MID_WIDTH]};
        6'd47: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[47*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  47*MID_WIDTH]};
        6'd48: _bram_rd_pooling_data_0 = {bram_rd_pooling_pre[48*MID_WIDTH-1 :  0*MID_WIDTH] , bram_rd_pooling_pre[64*MID_WIDTH-1 :  48*MID_WIDTH]};
      endcase
    end else begin
      _bram_rd_pooling_data_0 = {(64*MID_WIDTH){1'b0}};
    end
  end  
  
endmodule
