//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Engineer:zhanghs 
//// 
//// Create Date: 2018/11/12 20:36:37
//// Module Name: bram_conv_wr
//// Project Name: vgg.acc.bfp
//// Target Devices: vc709
//// Tool Versions: vivado 2018.1
//// Description: write conv results into bram, through port A
//// 
//// Revision 0.01 - File Created
////////////////////////////////////////////////////////////////////////////////////


////original
//module bram_conv_wr #(
//  parameter MID_WIDTH = 29,
//  parameter K_C = 64,
//  parameter PORT_ADDR_WIDTH = 11
//)(
//  input  wire                                 clk,
//  input  wire                                 rst_n,
//  // addr
//  input  wire[2:0]                            bram_wr_ker_set,
//  input  wire[3:0]                            bram_wr_y,//conv_y in [0:14]
//  input  wire[3:0]                            bram_wr_x,//conv_x in [0:14]
//  output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_wr_addr,
//  // enable
//  input  wire                                 bram_wr_conv_valid,   //in conv, port a write enable
//  output reg                                  bram_wr_en,
//  // data
//  input  wire[K_C*MID_WIDTH-1:0]              bram_wr_conv_i,
//  output reg [K_C*MID_WIDTH-1:0]              bram_wr_data
//  );

//  wire                                _bram_wr_x_quarter; // 0~1
//  wire                                _bram_wr_y_quarter; // 0~1
//  wire[2:0]                           _bram_wr_qpos_x; // x coordinate in 7x7
//  wire[2:0]                           _bram_wr_qpos_y; // y coordinate in 7x7
//  wire[3:0]                           _bram_wr_x_minus7;
//  wire[3:0]                           _bram_wr_y_minus7;
//  wire[5:0]                           _bram_wr_quarter_addr; // address in 7x7
//  reg [5:0]                           _bram_wr_shift;
//  wire[PORT_ADDR_WIDTH-1 : 0]         _bram_wr_addr;
//  reg [K_C*MID_WIDTH-1:0]             _bram_wr_conv_i;

//  assign _bram_wr_x_minus7  = bram_wr_x - 4'd7;
//  assign _bram_wr_y_minus7  = bram_wr_y - 4'd7;
//  assign _bram_wr_x_quarter = _bram_wr_x_minus7[3] ? 1'b0 : 1'b1; //0 while x<7, 1 while x>=7
//  assign _bram_wr_y_quarter = _bram_wr_y_minus7[3] ? 1'b0 : 1'b1;
//  assign _bram_wr_qpos_x    = _bram_wr_x_quarter ? _bram_wr_x_minus7[2:0] : bram_wr_x[2:0]; //0~6
//  assign _bram_wr_qpos_y    = _bram_wr_y_quarter ? _bram_wr_y_minus7[2:0] : bram_wr_y[2:0];
//  assign _bram_wr_quarter_addr  = _bram_wr_qpos_y*4'd7 + {1'b0,_bram_wr_qpos_x}; //0~48
//  assign _bram_wr_addr          = {bram_wr_ker_set, _bram_wr_y_quarter, _bram_wr_x_quarter}*6'd49 + _bram_wr_quarter_addr; //address: quarter 00, 01, 10, 11

//  // enable
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_wr_en <= 1'b0;
//    end else begin
//      bram_wr_en <= bram_wr_conv_valid;
//    end
//  end
  
//  always@(posedge clk) begin
//    _bram_wr_conv_i <= bram_wr_conv_i; //register data
//    bram_wr_addr  <= {K_C{_bram_wr_addr}}; //address
//    _bram_wr_shift <= _bram_wr_quarter_addr; //ctrl
//  end
  
//  always@(_bram_wr_shift or _bram_wr_conv_i or bram_wr_en) begin
//    if(bram_wr_en) begin
//      bram_wr_data = {(64*MID_WIDTH){1'b0}};
//      case(_bram_wr_shift) //synopsys full_case parallel_case
//        6'd0 : bram_wr_data =  _bram_wr_conv_i;
//        6'd1 : bram_wr_data = {_bram_wr_conv_i[63*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 63*MID_WIDTH]};
//        6'd2 : bram_wr_data = {_bram_wr_conv_i[62*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 62*MID_WIDTH]};
//        6'd3 : bram_wr_data = {_bram_wr_conv_i[61*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 61*MID_WIDTH]};
//        6'd4 : bram_wr_data = {_bram_wr_conv_i[60*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 60*MID_WIDTH]};
//        6'd5 : bram_wr_data = {_bram_wr_conv_i[59*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 59*MID_WIDTH]};
//        6'd6 : bram_wr_data = {_bram_wr_conv_i[58*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 58*MID_WIDTH]};
//        6'd7 : bram_wr_data = {_bram_wr_conv_i[57*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 57*MID_WIDTH]};
//        6'd8 : bram_wr_data = {_bram_wr_conv_i[56*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 56*MID_WIDTH]};
//        6'd9 : bram_wr_data = {_bram_wr_conv_i[55*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 55*MID_WIDTH]};
//        6'd10: bram_wr_data = {_bram_wr_conv_i[54*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 54*MID_WIDTH]};
//        6'd11: bram_wr_data = {_bram_wr_conv_i[53*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 53*MID_WIDTH]};
//        6'd12: bram_wr_data = {_bram_wr_conv_i[52*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 52*MID_WIDTH]};
//        6'd13: bram_wr_data = {_bram_wr_conv_i[51*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 51*MID_WIDTH]};
//        6'd14: bram_wr_data = {_bram_wr_conv_i[50*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 50*MID_WIDTH]};
//        6'd15: bram_wr_data = {_bram_wr_conv_i[49*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 49*MID_WIDTH]};
//        6'd16: bram_wr_data = {_bram_wr_conv_i[48*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 48*MID_WIDTH]};
//        6'd17: bram_wr_data = {_bram_wr_conv_i[47*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 47*MID_WIDTH]};
//        6'd18: bram_wr_data = {_bram_wr_conv_i[46*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 46*MID_WIDTH]};
//        6'd19: bram_wr_data = {_bram_wr_conv_i[45*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 45*MID_WIDTH]};
//        6'd20: bram_wr_data = {_bram_wr_conv_i[44*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 44*MID_WIDTH]};
//        6'd21: bram_wr_data = {_bram_wr_conv_i[43*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 43*MID_WIDTH]};
//        6'd22: bram_wr_data = {_bram_wr_conv_i[42*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 42*MID_WIDTH]};
//        6'd23: bram_wr_data = {_bram_wr_conv_i[41*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 41*MID_WIDTH]};
//        6'd24: bram_wr_data = {_bram_wr_conv_i[40*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 40*MID_WIDTH]};
//        6'd25: bram_wr_data = {_bram_wr_conv_i[39*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 39*MID_WIDTH]};
//        6'd26: bram_wr_data = {_bram_wr_conv_i[38*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 38*MID_WIDTH]};
//        6'd27: bram_wr_data = {_bram_wr_conv_i[37*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 37*MID_WIDTH]};
//        6'd28: bram_wr_data = {_bram_wr_conv_i[36*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 36*MID_WIDTH]};
//        6'd29: bram_wr_data = {_bram_wr_conv_i[35*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 35*MID_WIDTH]};
//        6'd30: bram_wr_data = {_bram_wr_conv_i[34*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 34*MID_WIDTH]};
//        6'd31: bram_wr_data = {_bram_wr_conv_i[33*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 33*MID_WIDTH]};
//        6'd32: bram_wr_data = {_bram_wr_conv_i[32*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 32*MID_WIDTH]};
//        6'd33: bram_wr_data = {_bram_wr_conv_i[31*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 31*MID_WIDTH]};
//        6'd34: bram_wr_data = {_bram_wr_conv_i[30*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 30*MID_WIDTH]};
//        6'd35: bram_wr_data = {_bram_wr_conv_i[29*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 29*MID_WIDTH]};
//        6'd36: bram_wr_data = {_bram_wr_conv_i[28*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 28*MID_WIDTH]};
//        6'd37: bram_wr_data = {_bram_wr_conv_i[27*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 27*MID_WIDTH]};
//        6'd38: bram_wr_data = {_bram_wr_conv_i[26*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 26*MID_WIDTH]};
//        6'd39: bram_wr_data = {_bram_wr_conv_i[25*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 25*MID_WIDTH]};
//        6'd40: bram_wr_data = {_bram_wr_conv_i[24*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 24*MID_WIDTH]};
//        6'd41: bram_wr_data = {_bram_wr_conv_i[23*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 23*MID_WIDTH]};
//        6'd42: bram_wr_data = {_bram_wr_conv_i[22*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 22*MID_WIDTH]};
//        6'd43: bram_wr_data = {_bram_wr_conv_i[21*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 21*MID_WIDTH]};
//        6'd44: bram_wr_data = {_bram_wr_conv_i[20*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 20*MID_WIDTH]};
//        6'd45: bram_wr_data = {_bram_wr_conv_i[19*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 19*MID_WIDTH]};
//        6'd46: bram_wr_data = {_bram_wr_conv_i[18*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 18*MID_WIDTH]};
//        6'd47: bram_wr_data = {_bram_wr_conv_i[17*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 17*MID_WIDTH]};
//        6'd48: bram_wr_data = {_bram_wr_conv_i[16*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 16*MID_WIDTH]};
//      endcase
//    end else begin
//      bram_wr_data = {(64*MID_WIDTH){1'b0}};
//    end
//  end
  
//endmodule



//register output
module bram_conv_wr #(
  parameter MID_WIDTH = 29,
  parameter K_C = 64,
  parameter PORT_ADDR_WIDTH = 11
)(
  input  wire                                 clk,
  input  wire                                 rst_n,
  // addr
  input  wire[2:0]                            bram_wr_ker_set,
  input  wire[3:0]                            bram_wr_y,//conv_y in [0:14]
  input  wire[3:0]                            bram_wr_x,//conv_x in [0:14]
  output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_wr_addr,
  // enable
  input  wire                                 bram_wr_conv_valid,   //in conv, port a write enable
  output reg                                  bram_wr_en,
  // data
  input  wire[K_C*MID_WIDTH-1:0]              bram_wr_conv_i,
  output reg [K_C*MID_WIDTH-1:0]              bram_wr_data
  );

  wire                                _bram_wr_x_quarter; // 0~1
  wire                                _bram_wr_y_quarter; // 0~1
  wire[2:0]                           _bram_wr_qpos_x; // x coordinate in 7x7
  wire[2:0]                           _bram_wr_qpos_y; // y coordinate in 7x7
  wire[3:0]                           _bram_wr_x_minus7;
  wire[3:0]                           _bram_wr_y_minus7;
  wire[5:0]                           _bram_wr_quarter_addr; // address in 7x7
  reg [5:0]                           _bram_wr_shift;
  wire[PORT_ADDR_WIDTH-1 : 0]         _bram_wr_addr;
  reg [K_C*MID_WIDTH-1:0]             _bram_wr_conv_i;
  reg                                 _bram_wr_en_pre;
  reg [PORT_ADDR_WIDTH-1 : 0]         _bram_wr_addr_reg;
  reg [K_C*MID_WIDTH-1:0]             _bram_wr_data;

  assign _bram_wr_x_minus7  = bram_wr_x - 4'd7;
  assign _bram_wr_y_minus7  = bram_wr_y - 4'd7;
  assign _bram_wr_x_quarter = _bram_wr_x_minus7[3] ? 1'b0 : 1'b1; //0 while x<7, 1 while x>=7
  assign _bram_wr_y_quarter = _bram_wr_y_minus7[3] ? 1'b0 : 1'b1;
  assign _bram_wr_qpos_x    = _bram_wr_x_quarter ? _bram_wr_x_minus7[2:0] : bram_wr_x[2:0]; //0~6
  assign _bram_wr_qpos_y    = _bram_wr_y_quarter ? _bram_wr_y_minus7[2:0] : bram_wr_y[2:0];
  assign _bram_wr_quarter_addr  = _bram_wr_qpos_y*4'd7 + {1'b0,_bram_wr_qpos_x}; //0~48
  assign _bram_wr_addr          = {bram_wr_ker_set, _bram_wr_y_quarter, _bram_wr_x_quarter}*6'd49 + _bram_wr_quarter_addr; //address: quarter 00, 01, 10, 11

  // enable
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bram_wr_en <= 1'b0;
      _bram_wr_en_pre <= 1'b0;
    end else begin
      _bram_wr_en_pre <= bram_wr_conv_valid;
      bram_wr_en <= _bram_wr_en_pre;
    end
  end
  
  always@(posedge clk) begin
    _bram_wr_conv_i <= bram_wr_conv_i; //register data
    _bram_wr_addr_reg <= _bram_wr_addr;
    bram_wr_addr  <= {K_C{_bram_wr_addr_reg}}; //address
    _bram_wr_shift <= _bram_wr_quarter_addr; //ctrl
    bram_wr_data <= _bram_wr_data; //data written out
  end
  
  always@(_bram_wr_shift or _bram_wr_conv_i or _bram_wr_en_pre) begin
    if(_bram_wr_en_pre) begin
      _bram_wr_data = {(64*MID_WIDTH){1'b0}};
      case(_bram_wr_shift) //synopsys full_case parallel_case
        6'd0 : _bram_wr_data =  _bram_wr_conv_i;
        6'd1 : _bram_wr_data = {_bram_wr_conv_i[63*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 63*MID_WIDTH]};
        6'd2 : _bram_wr_data = {_bram_wr_conv_i[62*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 62*MID_WIDTH]};
        6'd3 : _bram_wr_data = {_bram_wr_conv_i[61*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 61*MID_WIDTH]};
        6'd4 : _bram_wr_data = {_bram_wr_conv_i[60*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 60*MID_WIDTH]};
        6'd5 : _bram_wr_data = {_bram_wr_conv_i[59*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 59*MID_WIDTH]};
        6'd6 : _bram_wr_data = {_bram_wr_conv_i[58*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 58*MID_WIDTH]};
        6'd7 : _bram_wr_data = {_bram_wr_conv_i[57*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 57*MID_WIDTH]};
        6'd8 : _bram_wr_data = {_bram_wr_conv_i[56*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 56*MID_WIDTH]};
        6'd9 : _bram_wr_data = {_bram_wr_conv_i[55*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 55*MID_WIDTH]};
        6'd10: _bram_wr_data = {_bram_wr_conv_i[54*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 54*MID_WIDTH]};
        6'd11: _bram_wr_data = {_bram_wr_conv_i[53*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 53*MID_WIDTH]};
        6'd12: _bram_wr_data = {_bram_wr_conv_i[52*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 52*MID_WIDTH]};
        6'd13: _bram_wr_data = {_bram_wr_conv_i[51*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 51*MID_WIDTH]};
        6'd14: _bram_wr_data = {_bram_wr_conv_i[50*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 50*MID_WIDTH]};
        6'd15: _bram_wr_data = {_bram_wr_conv_i[49*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 49*MID_WIDTH]};
        6'd16: _bram_wr_data = {_bram_wr_conv_i[48*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 48*MID_WIDTH]};
        6'd17: _bram_wr_data = {_bram_wr_conv_i[47*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 47*MID_WIDTH]};
        6'd18: _bram_wr_data = {_bram_wr_conv_i[46*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 46*MID_WIDTH]};
        6'd19: _bram_wr_data = {_bram_wr_conv_i[45*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 45*MID_WIDTH]};
        6'd20: _bram_wr_data = {_bram_wr_conv_i[44*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 44*MID_WIDTH]};
        6'd21: _bram_wr_data = {_bram_wr_conv_i[43*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 43*MID_WIDTH]};
        6'd22: _bram_wr_data = {_bram_wr_conv_i[42*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 42*MID_WIDTH]};
        6'd23: _bram_wr_data = {_bram_wr_conv_i[41*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 41*MID_WIDTH]};
        6'd24: _bram_wr_data = {_bram_wr_conv_i[40*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 40*MID_WIDTH]};
        6'd25: _bram_wr_data = {_bram_wr_conv_i[39*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 39*MID_WIDTH]};
        6'd26: _bram_wr_data = {_bram_wr_conv_i[38*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 38*MID_WIDTH]};
        6'd27: _bram_wr_data = {_bram_wr_conv_i[37*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 37*MID_WIDTH]};
        6'd28: _bram_wr_data = {_bram_wr_conv_i[36*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 36*MID_WIDTH]};
        6'd29: _bram_wr_data = {_bram_wr_conv_i[35*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 35*MID_WIDTH]};
        6'd30: _bram_wr_data = {_bram_wr_conv_i[34*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 34*MID_WIDTH]};
        6'd31: _bram_wr_data = {_bram_wr_conv_i[33*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 33*MID_WIDTH]};
        6'd32: _bram_wr_data = {_bram_wr_conv_i[32*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 32*MID_WIDTH]};
        6'd33: _bram_wr_data = {_bram_wr_conv_i[31*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 31*MID_WIDTH]};
        6'd34: _bram_wr_data = {_bram_wr_conv_i[30*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 30*MID_WIDTH]};
        6'd35: _bram_wr_data = {_bram_wr_conv_i[29*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 29*MID_WIDTH]};
        6'd36: _bram_wr_data = {_bram_wr_conv_i[28*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 28*MID_WIDTH]};
        6'd37: _bram_wr_data = {_bram_wr_conv_i[27*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 27*MID_WIDTH]};
        6'd38: _bram_wr_data = {_bram_wr_conv_i[26*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 26*MID_WIDTH]};
        6'd39: _bram_wr_data = {_bram_wr_conv_i[25*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 25*MID_WIDTH]};
        6'd40: _bram_wr_data = {_bram_wr_conv_i[24*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 24*MID_WIDTH]};
        6'd41: _bram_wr_data = {_bram_wr_conv_i[23*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 23*MID_WIDTH]};
        6'd42: _bram_wr_data = {_bram_wr_conv_i[22*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 22*MID_WIDTH]};
        6'd43: _bram_wr_data = {_bram_wr_conv_i[21*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 21*MID_WIDTH]};
        6'd44: _bram_wr_data = {_bram_wr_conv_i[20*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 20*MID_WIDTH]};
        6'd45: _bram_wr_data = {_bram_wr_conv_i[19*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 19*MID_WIDTH]};
        6'd46: _bram_wr_data = {_bram_wr_conv_i[18*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 18*MID_WIDTH]};
        6'd47: _bram_wr_data = {_bram_wr_conv_i[17*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 17*MID_WIDTH]};
        6'd48: _bram_wr_data = {_bram_wr_conv_i[16*MID_WIDTH-1 : 0*MID_WIDTH] , _bram_wr_conv_i[64*MID_WIDTH-1 : 16*MID_WIDTH]};
      endcase
    end else begin
      _bram_wr_data = {(64*MID_WIDTH){1'b0}};
    end
  end
  
endmodule