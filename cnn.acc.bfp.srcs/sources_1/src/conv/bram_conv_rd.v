`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:zhanghs 
// 
// Create Date: 2018/11/12 20:36:37
// Module Name: bram_conv_rd
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: rd partialsum form bram, through port B
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

////original
//module bram_conv_rd #(
//  parameter MID_WIDTH = 29,
//  parameter K_C = 64,
//  parameter PORT_ADDR_WIDTH = 11
//)(
//  input  wire                                 clk,
//  input  wire                                 rst_n,
//  // addr
//  input  wire[2:0]                            bram_rd_ker_set,
//  input  wire[3:0]                            bram_rd_x,
//  input  wire[3:0]                            bram_rd_y,
//  output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_rd_addr,
//  // enable
//  input  wire                                 bram_rd_conv_en,   //in conv, port b read enable
//  output reg                                  bram_rd_bram_valid,
//  output reg                                  bram_rd_en,
//  // data
//  input  wire[K_C*MID_WIDTH-1:0]              bram_rd_partial_sum,
//  output reg                                  bram_rd_data_valid,
//  output reg [K_C*MID_WIDTH-1:0]              bram_rd_data
//);

//  wire                                _bram_rd_x_quarter;
//  wire                                _bram_rd_y_quarter;
//  wire[3:0]                           _bram_rd_x_minux7;
//  wire[3:0]                           _bram_rd_y_minux7;
//  wire[2:0]                           _bram_rd_qpos_x; // x coordinate in 7x7
//  wire[2:0]                           _bram_rd_qpos_y; // y coordinate in 7x7
//  wire[5:0]                           _bram_rd_quarter_addr; // address in 7x7
//  reg [5:0]                           _bram_rd_shift1; // address in 7x7
//  reg [5:0]                           _bram_rd_shift2;
//  reg [5:0]                           _bram_rd_shift; // address in 7x7
//  wire[PORT_ADDR_WIDTH-1 : 0]         _bram_rd_addr;
//  reg [64*MID_WIDTH-1:0]              _bram_rd_data;

//  assign _bram_rd_x_minux7  = bram_rd_x - 4'd7;
//  assign _bram_rd_y_minux7  = bram_rd_y - 4'd7;
//  assign _bram_rd_x_quarter = _bram_rd_x_minux7[3] ? 1'b0 : 1'b1;
//  assign _bram_rd_y_quarter = _bram_rd_y_minux7[3] ? 1'b0 : 1'b1;
//  assign _bram_rd_qpos_x    = _bram_rd_x_quarter ? _bram_rd_x_minux7[2:0] : bram_rd_x[2:0];
//  assign _bram_rd_qpos_y    = _bram_rd_y_quarter ? _bram_rd_y_minux7[2:0] : bram_rd_y[2:0];
//  assign _bram_rd_quarter_addr  = _bram_rd_qpos_y*4'd7 + {1'd0,_bram_rd_qpos_x};
//  assign _bram_rd_addr      = {bram_rd_ker_set,_bram_rd_y_quarter,_bram_rd_x_quarter}*6'd49 + _bram_rd_quarter_addr;

//  // enable
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_rd_en <= 1'b0;
//      bram_rd_bram_valid <= 1'b0;
//      bram_rd_data_valid <= 1'b0;
//    end else begin
//      bram_rd_en          <= bram_rd_conv_en;
//      bram_rd_bram_valid  <= bram_rd_en;
//      bram_rd_data_valid  <= bram_rd_bram_valid;
//    end
//  end
//  // address
//  always@(posedge clk) begin
//    bram_rd_addr <= {64{_bram_rd_addr}};  //address
//    _bram_rd_data <= bram_rd_partial_sum; 
//    _bram_rd_shift1<= _bram_rd_quarter_addr;  //ctrl
//    _bram_rd_shift2<= _bram_rd_shift1;
//    _bram_rd_shift <= _bram_rd_shift2;    
//  end

//  always@(_bram_rd_shift or _bram_rd_data or bram_rd_data_valid) begin
//    if(bram_rd_data_valid) begin
//      bram_rd_data = {(64*MID_WIDTH){1'b0}};
//      case(_bram_rd_shift) //0~48
//        6'd0 : bram_rd_data = _bram_rd_data;
//        6'd1 : bram_rd_data = {_bram_rd_data[1 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  1 *MID_WIDTH]};
//        6'd2 : bram_rd_data = {_bram_rd_data[2 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  2 *MID_WIDTH]};
//        6'd3 : bram_rd_data = {_bram_rd_data[3 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  3 *MID_WIDTH]};
//        6'd4 : bram_rd_data = {_bram_rd_data[4 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  4 *MID_WIDTH]};
//        6'd5 : bram_rd_data = {_bram_rd_data[5 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  5 *MID_WIDTH]};
//        6'd6 : bram_rd_data = {_bram_rd_data[6 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  6 *MID_WIDTH]};
//        6'd7 : bram_rd_data = {_bram_rd_data[7 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  7 *MID_WIDTH]};
//        6'd8 : bram_rd_data = {_bram_rd_data[8 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  8 *MID_WIDTH]};
//        6'd9 : bram_rd_data = {_bram_rd_data[9 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  9 *MID_WIDTH]};
//        6'd10: bram_rd_data = {_bram_rd_data[10*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  10*MID_WIDTH]};
//        6'd11: bram_rd_data = {_bram_rd_data[11*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  11*MID_WIDTH]};
//        6'd12: bram_rd_data = {_bram_rd_data[12*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  12*MID_WIDTH]};
//        6'd13: bram_rd_data = {_bram_rd_data[13*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  13*MID_WIDTH]};
//        6'd14: bram_rd_data = {_bram_rd_data[14*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  14*MID_WIDTH]};
//        6'd15: bram_rd_data = {_bram_rd_data[15*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  15*MID_WIDTH]};
//        6'd16: bram_rd_data = {_bram_rd_data[16*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  16*MID_WIDTH]};
//        6'd17: bram_rd_data = {_bram_rd_data[17*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  17*MID_WIDTH]};
//        6'd18: bram_rd_data = {_bram_rd_data[18*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  18*MID_WIDTH]};
//        6'd19: bram_rd_data = {_bram_rd_data[19*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  19*MID_WIDTH]};
//        6'd20: bram_rd_data = {_bram_rd_data[20*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  20*MID_WIDTH]};
//        6'd21: bram_rd_data = {_bram_rd_data[21*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  21*MID_WIDTH]};
//        6'd22: bram_rd_data = {_bram_rd_data[22*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  22*MID_WIDTH]};
//        6'd23: bram_rd_data = {_bram_rd_data[23*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  23*MID_WIDTH]};
//        6'd24: bram_rd_data = {_bram_rd_data[24*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  24*MID_WIDTH]};
//        6'd25: bram_rd_data = {_bram_rd_data[25*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  25*MID_WIDTH]};
//        6'd26: bram_rd_data = {_bram_rd_data[26*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  26*MID_WIDTH]};
//        6'd27: bram_rd_data = {_bram_rd_data[27*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  27*MID_WIDTH]};
//        6'd28: bram_rd_data = {_bram_rd_data[28*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  28*MID_WIDTH]};
//        6'd29: bram_rd_data = {_bram_rd_data[29*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  29*MID_WIDTH]};
//        6'd30: bram_rd_data = {_bram_rd_data[30*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  30*MID_WIDTH]};
//        6'd31: bram_rd_data = {_bram_rd_data[31*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  31*MID_WIDTH]};
//        6'd32: bram_rd_data = {_bram_rd_data[32*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  32*MID_WIDTH]};
//        6'd33: bram_rd_data = {_bram_rd_data[33*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  33*MID_WIDTH]};
//        6'd34: bram_rd_data = {_bram_rd_data[34*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  34*MID_WIDTH]};
//        6'd35: bram_rd_data = {_bram_rd_data[35*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  35*MID_WIDTH]};
//        6'd36: bram_rd_data = {_bram_rd_data[36*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  36*MID_WIDTH]};
//        6'd37: bram_rd_data = {_bram_rd_data[37*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  37*MID_WIDTH]};
//        6'd38: bram_rd_data = {_bram_rd_data[38*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  38*MID_WIDTH]};
//        6'd39: bram_rd_data = {_bram_rd_data[39*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  39*MID_WIDTH]};
//        6'd40: bram_rd_data = {_bram_rd_data[40*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  40*MID_WIDTH]};
//        6'd41: bram_rd_data = {_bram_rd_data[41*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  41*MID_WIDTH]};
//        6'd42: bram_rd_data = {_bram_rd_data[42*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  42*MID_WIDTH]};
//        6'd43: bram_rd_data = {_bram_rd_data[43*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  43*MID_WIDTH]};
//        6'd44: bram_rd_data = {_bram_rd_data[44*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  44*MID_WIDTH]};
//        6'd45: bram_rd_data = {_bram_rd_data[45*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  45*MID_WIDTH]};
//        6'd46: bram_rd_data = {_bram_rd_data[46*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  46*MID_WIDTH]};
//        6'd47: bram_rd_data = {_bram_rd_data[47*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  47*MID_WIDTH]};
//        6'd48: bram_rd_data = {_bram_rd_data[48*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_data[64*MID_WIDTH-1 :  48*MID_WIDTH]};
//      endcase                                                 
//    end else begin
//      bram_rd_data = {(64*MID_WIDTH){1'b0}};
//    end
//  end
  
//endmodule


// delay for one clk
module bram_conv_rd #(
  parameter MID_WIDTH = 29,
  parameter K_C = 64,
  parameter PORT_ADDR_WIDTH = 11
)(
  input  wire                                 clk,
  input  wire                                 rst_n,
  // addr
  input  wire[2:0]                            bram_rd_ker_set,
  input  wire[3:0]                            bram_rd_x,
  input  wire[3:0]                            bram_rd_y,
  output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_rd_addr,
  // enable
  input  wire                                 bram_rd_conv_en,   //in conv, port b read enable
  output reg                                  bram_rd_bram_valid,
  output reg                                  bram_rd_en,
  // data
  input  wire[K_C*MID_WIDTH-1:0]              bram_rd_partial_sum,
  output reg                                  bram_rd_data_valid,
  output reg [K_C*MID_WIDTH-1:0]              bram_rd_data
);

  wire                                _bram_rd_x_quarter;
  wire                                _bram_rd_y_quarter;
  wire[3:0]                           _bram_rd_x_minux7;
  wire[3:0]                           _bram_rd_y_minux7;
  wire[2:0]                           _bram_rd_qpos_x; // x coordinate in 7x7
  wire[2:0]                           _bram_rd_qpos_y; // y coordinate in 7x7
  wire[5:0]                           _bram_rd_quarter_addr; // address in 7x7
  reg [5:0]                           _bram_rd_shift1; // address in 7x7
  reg [5:0]                           _bram_rd_shift2;
  reg [5:0]                           _bram_rd_shift; // address in 7x7
  wire[PORT_ADDR_WIDTH-1 : 0]         _bram_rd_addr;
  reg [K_C*MID_WIDTH-1:0]             _bram_rd_partial_sum;
  reg                                 _bram_rd_bram_valid_reg;
  reg [64*MID_WIDTH-1:0]              _bram_rd_data;

  assign _bram_rd_x_minux7  = bram_rd_x - 4'd7;
  assign _bram_rd_y_minux7  = bram_rd_y - 4'd7;
  assign _bram_rd_x_quarter = _bram_rd_x_minux7[3] ? 1'b0 : 1'b1;
  assign _bram_rd_y_quarter = _bram_rd_y_minux7[3] ? 1'b0 : 1'b1;
  assign _bram_rd_qpos_x    = _bram_rd_x_quarter ? _bram_rd_x_minux7[2:0] : bram_rd_x[2:0];
  assign _bram_rd_qpos_y    = _bram_rd_y_quarter ? _bram_rd_y_minux7[2:0] : bram_rd_y[2:0];
  assign _bram_rd_quarter_addr  = _bram_rd_qpos_y*4'd7 + {1'd0,_bram_rd_qpos_x};
  assign _bram_rd_addr      = {bram_rd_ker_set,_bram_rd_y_quarter,_bram_rd_x_quarter}*6'd49 + _bram_rd_quarter_addr;

  // enable
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bram_rd_en <= 1'b0;
      bram_rd_bram_valid <= 1'b0;
      _bram_rd_bram_valid_reg <= 1'b0;
      bram_rd_data_valid <= 1'b0;
    end else begin
      bram_rd_en          <= bram_rd_conv_en;
      bram_rd_bram_valid  <= bram_rd_en;
      _bram_rd_bram_valid_reg <= bram_rd_bram_valid;
      bram_rd_data_valid  <= _bram_rd_bram_valid_reg;
    end
  end
  // address
  always@(posedge clk) begin
    bram_rd_addr <= {64{_bram_rd_addr}};  //address
    _bram_rd_partial_sum <= bram_rd_partial_sum; 
    _bram_rd_shift1<= _bram_rd_quarter_addr;  //ctrl
    _bram_rd_shift2<= _bram_rd_shift1;
    _bram_rd_shift <= _bram_rd_shift2;
    bram_rd_data <= _bram_rd_data;    
  end

  always@(_bram_rd_shift or _bram_rd_partial_sum or _bram_rd_bram_valid_reg) begin
    if(_bram_rd_bram_valid_reg) begin
      _bram_rd_data = {(64*MID_WIDTH){1'b0}};
      case(_bram_rd_shift) //0~48
        6'd0 : _bram_rd_data =  _bram_rd_partial_sum;
        6'd1 : _bram_rd_data = {_bram_rd_partial_sum[1 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  1 *MID_WIDTH]};
        6'd2 : _bram_rd_data = {_bram_rd_partial_sum[2 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  2 *MID_WIDTH]};
        6'd3 : _bram_rd_data = {_bram_rd_partial_sum[3 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  3 *MID_WIDTH]};
        6'd4 : _bram_rd_data = {_bram_rd_partial_sum[4 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  4 *MID_WIDTH]};
        6'd5 : _bram_rd_data = {_bram_rd_partial_sum[5 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  5 *MID_WIDTH]};
        6'd6 : _bram_rd_data = {_bram_rd_partial_sum[6 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  6 *MID_WIDTH]};
        6'd7 : _bram_rd_data = {_bram_rd_partial_sum[7 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  7 *MID_WIDTH]};
        6'd8 : _bram_rd_data = {_bram_rd_partial_sum[8 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  8 *MID_WIDTH]};
        6'd9 : _bram_rd_data = {_bram_rd_partial_sum[9 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  9 *MID_WIDTH]};
        6'd10: _bram_rd_data = {_bram_rd_partial_sum[10*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  10*MID_WIDTH]};
        6'd11: _bram_rd_data = {_bram_rd_partial_sum[11*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  11*MID_WIDTH]};
        6'd12: _bram_rd_data = {_bram_rd_partial_sum[12*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  12*MID_WIDTH]};
        6'd13: _bram_rd_data = {_bram_rd_partial_sum[13*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  13*MID_WIDTH]};
        6'd14: _bram_rd_data = {_bram_rd_partial_sum[14*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  14*MID_WIDTH]};
        6'd15: _bram_rd_data = {_bram_rd_partial_sum[15*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  15*MID_WIDTH]};
        6'd16: _bram_rd_data = {_bram_rd_partial_sum[16*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  16*MID_WIDTH]};
        6'd17: _bram_rd_data = {_bram_rd_partial_sum[17*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  17*MID_WIDTH]};
        6'd18: _bram_rd_data = {_bram_rd_partial_sum[18*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  18*MID_WIDTH]};
        6'd19: _bram_rd_data = {_bram_rd_partial_sum[19*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  19*MID_WIDTH]};
        6'd20: _bram_rd_data = {_bram_rd_partial_sum[20*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  20*MID_WIDTH]};
        6'd21: _bram_rd_data = {_bram_rd_partial_sum[21*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  21*MID_WIDTH]};
        6'd22: _bram_rd_data = {_bram_rd_partial_sum[22*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  22*MID_WIDTH]};
        6'd23: _bram_rd_data = {_bram_rd_partial_sum[23*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  23*MID_WIDTH]};
        6'd24: _bram_rd_data = {_bram_rd_partial_sum[24*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  24*MID_WIDTH]};
        6'd25: _bram_rd_data = {_bram_rd_partial_sum[25*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  25*MID_WIDTH]};
        6'd26: _bram_rd_data = {_bram_rd_partial_sum[26*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  26*MID_WIDTH]};
        6'd27: _bram_rd_data = {_bram_rd_partial_sum[27*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  27*MID_WIDTH]};
        6'd28: _bram_rd_data = {_bram_rd_partial_sum[28*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  28*MID_WIDTH]};
        6'd29: _bram_rd_data = {_bram_rd_partial_sum[29*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  29*MID_WIDTH]};
        6'd30: _bram_rd_data = {_bram_rd_partial_sum[30*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  30*MID_WIDTH]};
        6'd31: _bram_rd_data = {_bram_rd_partial_sum[31*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  31*MID_WIDTH]};
        6'd32: _bram_rd_data = {_bram_rd_partial_sum[32*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  32*MID_WIDTH]};
        6'd33: _bram_rd_data = {_bram_rd_partial_sum[33*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  33*MID_WIDTH]};
        6'd34: _bram_rd_data = {_bram_rd_partial_sum[34*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  34*MID_WIDTH]};
        6'd35: _bram_rd_data = {_bram_rd_partial_sum[35*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  35*MID_WIDTH]};
        6'd36: _bram_rd_data = {_bram_rd_partial_sum[36*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  36*MID_WIDTH]};
        6'd37: _bram_rd_data = {_bram_rd_partial_sum[37*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  37*MID_WIDTH]};
        6'd38: _bram_rd_data = {_bram_rd_partial_sum[38*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  38*MID_WIDTH]};
        6'd39: _bram_rd_data = {_bram_rd_partial_sum[39*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  39*MID_WIDTH]};
        6'd40: _bram_rd_data = {_bram_rd_partial_sum[40*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  40*MID_WIDTH]};
        6'd41: _bram_rd_data = {_bram_rd_partial_sum[41*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  41*MID_WIDTH]};
        6'd42: _bram_rd_data = {_bram_rd_partial_sum[42*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  42*MID_WIDTH]};
        6'd43: _bram_rd_data = {_bram_rd_partial_sum[43*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  43*MID_WIDTH]};
        6'd44: _bram_rd_data = {_bram_rd_partial_sum[44*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  44*MID_WIDTH]};
        6'd45: _bram_rd_data = {_bram_rd_partial_sum[45*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  45*MID_WIDTH]};
        6'd46: _bram_rd_data = {_bram_rd_partial_sum[46*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  46*MID_WIDTH]};
        6'd47: _bram_rd_data = {_bram_rd_partial_sum[47*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  47*MID_WIDTH]};
        6'd48: _bram_rd_data = {_bram_rd_partial_sum[48*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_partial_sum[64*MID_WIDTH-1 :  48*MID_WIDTH]};
      endcase                                                 
    end else begin
      _bram_rd_data = {(64*MID_WIDTH){1'b0}};
    end
  end
  
endmodule