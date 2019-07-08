`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:zhanghs 
// 
// Create Date: 2018/11/12 20:36:37
// Module Name: bram_conv_wr
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: read from bram(ddr mode),through port B
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

////original
//module bram_ddr_rd #(
//    parameter MID_WIDTH = 29,
//    parameter K_C = 64,
//    parameter PORT_ADDR_WIDTH = 11
//  ) (
//    input  wire                                 clk,
//    input  wire                                 rst_n,
//    // addr
//    input  wire[2:0]                            bram_rd_ddr_ker_set,
//    input  wire[5:0]                            bram_rd_ddr_channel_idx, // channel index in one kernel set? 0?63
//    input  wire[1:0]                            bram_rd_ddr_quarter_num,
//    output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_rd_ddr_addr_b,
//    // enable
//    input  wire                                 bram_rd_ddr_en,     // enable
//    input  wire                                 bram_rd_ddr_rd_en,  //in conv, port b read enable
//    input  wire                                 bram_rd_ddr_next_quar, // clear valid signal
//    output reg                                  bram_rd_ddr_en_bram,
//    output reg                                  bram_rd_ddr_bram_valid,
//    // data
//    input  wire[K_C*MID_WIDTH-1:0]              bram_rd_ddr_b_data,
//    output reg                                  bram_rd_ddr_data_valid,
//    output reg [49*MID_WIDTH-1:0]               bram_rd_ddr_data
//  );

//  wire[PORT_ADDR_WIDTH-1 : 0]     _bram_rd_ddr_base_addr;
//  reg [64*PORT_ADDR_WIDTH-1 : 0]  _bram_rd_ddr_addr;
//  reg [K_C*MID_WIDTH-1 : 0]       _bram_rd_ddr_data;
//  reg [5:0]                       _bram_rd_ddr_channel_idx_1;
//  reg [5:0]                       _bram_rd_ddr_channel_idx_2;
//  reg [5:0]                       _bram_rd_ddr_channel_idx_3;
//  reg [5:0]                       _bram_rd_ddr_channel_idx_4;
//  reg                             _bram_rd_ddr_rd_en;
//  assign _bram_rd_ddr_base_addr = {bram_rd_ddr_ker_set,bram_rd_ddr_quarter_num}*6'd49;

//  // enable
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_rd_ddr_en_bram     <= 1'b0;
//      bram_rd_ddr_bram_valid  <= 1'b0;
//    end else begin
//      _bram_rd_ddr_rd_en      <= bram_rd_ddr_rd_en;
//      bram_rd_ddr_en_bram     <= _bram_rd_ddr_rd_en;
//      bram_rd_ddr_bram_valid  <= bram_rd_ddr_en_bram;
//    end
//  end
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_rd_ddr_data_valid  <= 1'b0;
//    end else begin 
//      if(!bram_rd_ddr_en || bram_rd_ddr_next_quar) begin
//        bram_rd_ddr_data_valid  <= 1'b0;
//      end else if(bram_rd_ddr_en && bram_rd_ddr_bram_valid) begin
//        bram_rd_ddr_data_valid  <= 1'b1;
//      end
//    end
//  end
  
//  // channel index delay
//  always@(posedge clk) begin
//    _bram_rd_ddr_channel_idx_1 <= bram_rd_ddr_channel_idx;
//    _bram_rd_ddr_channel_idx_2 <= _bram_rd_ddr_channel_idx_1;
//    _bram_rd_ddr_channel_idx_3 <= _bram_rd_ddr_channel_idx_2;
//    _bram_rd_ddr_channel_idx_4 <= _bram_rd_ddr_channel_idx_3;
//  end
  
//  // address
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _bram_rd_ddr_addr <= {(64*PORT_ADDR_WIDTH){1'b0}};
//    end else begin
//      if(bram_rd_ddr_rd_en) begin //down direction
//        _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 63*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[63*PORT_ADDR_WIDTH-1 : 62*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[62*PORT_ADDR_WIDTH-1 : 61*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[61*PORT_ADDR_WIDTH-1 : 60*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[60*PORT_ADDR_WIDTH-1 : 59*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[59*PORT_ADDR_WIDTH-1 : 58*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[58*PORT_ADDR_WIDTH-1 : 57*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[57*PORT_ADDR_WIDTH-1 : 56*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[56*PORT_ADDR_WIDTH-1 : 55*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[55*PORT_ADDR_WIDTH-1 : 54*PORT_ADDR_WIDTH] <= 11'd0; 
//        _bram_rd_ddr_addr[54*PORT_ADDR_WIDTH-1 : 53*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[53*PORT_ADDR_WIDTH-1 : 52*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[52*PORT_ADDR_WIDTH-1 : 51*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[51*PORT_ADDR_WIDTH-1 : 50*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[50*PORT_ADDR_WIDTH-1 : 49*PORT_ADDR_WIDTH] <= 11'd0;
//        _bram_rd_ddr_addr[49*PORT_ADDR_WIDTH-1 : 48*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd48;
//        _bram_rd_ddr_addr[48*PORT_ADDR_WIDTH-1 : 47*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd47;
//        _bram_rd_ddr_addr[47*PORT_ADDR_WIDTH-1 : 46*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd46;
//        _bram_rd_ddr_addr[46*PORT_ADDR_WIDTH-1 : 45*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd45;
//        _bram_rd_ddr_addr[45*PORT_ADDR_WIDTH-1 : 44*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd44;
//        _bram_rd_ddr_addr[44*PORT_ADDR_WIDTH-1 : 43*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd43;
//        _bram_rd_ddr_addr[43*PORT_ADDR_WIDTH-1 : 42*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd42;
//        _bram_rd_ddr_addr[42*PORT_ADDR_WIDTH-1 : 41*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd41;
//        _bram_rd_ddr_addr[41*PORT_ADDR_WIDTH-1 : 40*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd40;
//        _bram_rd_ddr_addr[40*PORT_ADDR_WIDTH-1 : 39*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd39;
//        _bram_rd_ddr_addr[39*PORT_ADDR_WIDTH-1 : 38*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd38;
//        _bram_rd_ddr_addr[38*PORT_ADDR_WIDTH-1 : 37*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd37;
//        _bram_rd_ddr_addr[37*PORT_ADDR_WIDTH-1 : 36*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd36;
//        _bram_rd_ddr_addr[36*PORT_ADDR_WIDTH-1 : 35*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd35;
//        _bram_rd_ddr_addr[35*PORT_ADDR_WIDTH-1 : 34*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd34;
//        _bram_rd_ddr_addr[34*PORT_ADDR_WIDTH-1 : 33*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd33;
//        _bram_rd_ddr_addr[33*PORT_ADDR_WIDTH-1 : 32*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd32;
//        _bram_rd_ddr_addr[32*PORT_ADDR_WIDTH-1 : 31*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd31;
//        _bram_rd_ddr_addr[31*PORT_ADDR_WIDTH-1 : 30*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd30;
//        _bram_rd_ddr_addr[30*PORT_ADDR_WIDTH-1 : 29*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd29;
//        _bram_rd_ddr_addr[29*PORT_ADDR_WIDTH-1 : 28*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd28;
//        _bram_rd_ddr_addr[28*PORT_ADDR_WIDTH-1 : 27*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd27;
//        _bram_rd_ddr_addr[27*PORT_ADDR_WIDTH-1 : 26*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd26;
//        _bram_rd_ddr_addr[26*PORT_ADDR_WIDTH-1 : 25*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd25;
//        _bram_rd_ddr_addr[25*PORT_ADDR_WIDTH-1 : 24*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd24;
//        _bram_rd_ddr_addr[24*PORT_ADDR_WIDTH-1 : 23*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd23;
//        _bram_rd_ddr_addr[23*PORT_ADDR_WIDTH-1 : 22*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd22;
//        _bram_rd_ddr_addr[22*PORT_ADDR_WIDTH-1 : 21*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd21;
//        _bram_rd_ddr_addr[21*PORT_ADDR_WIDTH-1 : 20*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd20;
//        _bram_rd_ddr_addr[20*PORT_ADDR_WIDTH-1 : 19*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd19;
//        _bram_rd_ddr_addr[19*PORT_ADDR_WIDTH-1 : 18*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd18;
//        _bram_rd_ddr_addr[18*PORT_ADDR_WIDTH-1 : 17*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd17;
//        _bram_rd_ddr_addr[17*PORT_ADDR_WIDTH-1 : 16*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd16;
//        _bram_rd_ddr_addr[16*PORT_ADDR_WIDTH-1 : 15*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd15;
//        _bram_rd_ddr_addr[15*PORT_ADDR_WIDTH-1 : 14*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd14;
//        _bram_rd_ddr_addr[14*PORT_ADDR_WIDTH-1 : 13*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd13;
//        _bram_rd_ddr_addr[13*PORT_ADDR_WIDTH-1 : 12*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd12;
//        _bram_rd_ddr_addr[12*PORT_ADDR_WIDTH-1 : 11*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd11;
//        _bram_rd_ddr_addr[11*PORT_ADDR_WIDTH-1 : 10*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd10;
//        _bram_rd_ddr_addr[10*PORT_ADDR_WIDTH-1 :  9*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd9; 
//        _bram_rd_ddr_addr[ 9*PORT_ADDR_WIDTH-1 :  8*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd8; 
//        _bram_rd_ddr_addr[ 8*PORT_ADDR_WIDTH-1 :  7*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd7; 
//        _bram_rd_ddr_addr[ 7*PORT_ADDR_WIDTH-1 :  6*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd6; 
//        _bram_rd_ddr_addr[ 6*PORT_ADDR_WIDTH-1 :  5*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd5; 
//        _bram_rd_ddr_addr[ 5*PORT_ADDR_WIDTH-1 :  4*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd4; 
//        _bram_rd_ddr_addr[ 4*PORT_ADDR_WIDTH-1 :  3*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd3; 
//        _bram_rd_ddr_addr[ 3*PORT_ADDR_WIDTH-1 :  2*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd2; 
//        _bram_rd_ddr_addr[ 2*PORT_ADDR_WIDTH-1 :  1*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd1; 
//        _bram_rd_ddr_addr[ 1*PORT_ADDR_WIDTH-1 :  0*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd0; 
//      end
//    end
//  end
  
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      bram_rd_ddr_addr_b <= {64*PORT_ADDR_WIDTH{1'b0}};
//    end else begin
//      case(_bram_rd_ddr_channel_idx_1) //0~48
//        6'd0 : bram_rd_ddr_addr_b <=  _bram_rd_ddr_addr;
//        6'd1 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[63*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 63*PORT_ADDR_WIDTH]};
//        6'd2 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[62*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 62*PORT_ADDR_WIDTH]};
//        6'd3 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[61*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 61*PORT_ADDR_WIDTH]};
//        6'd4 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[60*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 60*PORT_ADDR_WIDTH]};
//        6'd5 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[59*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 59*PORT_ADDR_WIDTH]};
//        6'd6 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[58*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 58*PORT_ADDR_WIDTH]};
//        6'd7 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[57*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 57*PORT_ADDR_WIDTH]};
//        6'd8 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[56*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 56*PORT_ADDR_WIDTH]};
//        6'd9 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[55*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 55*PORT_ADDR_WIDTH]};
//        6'd10: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[54*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 54*PORT_ADDR_WIDTH]};
//        6'd11: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[53*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 53*PORT_ADDR_WIDTH]};
//        6'd12: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[52*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 52*PORT_ADDR_WIDTH]};
//        6'd13: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[51*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 51*PORT_ADDR_WIDTH]};
//        6'd14: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[50*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 50*PORT_ADDR_WIDTH]};
//        6'd15: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[49*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 49*PORT_ADDR_WIDTH]};
//        6'd16: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[48*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 48*PORT_ADDR_WIDTH]};
//        6'd17: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[47*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 47*PORT_ADDR_WIDTH]};
//        6'd18: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[46*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 46*PORT_ADDR_WIDTH]};
//        6'd19: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[45*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 45*PORT_ADDR_WIDTH]};
//        6'd20: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[44*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 44*PORT_ADDR_WIDTH]};
//        6'd21: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[43*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 43*PORT_ADDR_WIDTH]};
//        6'd22: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[42*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 42*PORT_ADDR_WIDTH]};
//        6'd23: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[41*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 41*PORT_ADDR_WIDTH]};
//        6'd24: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[40*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 40*PORT_ADDR_WIDTH]};
//        6'd25: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[39*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 39*PORT_ADDR_WIDTH]};
//        6'd26: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[38*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 38*PORT_ADDR_WIDTH]};
//        6'd27: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[37*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 37*PORT_ADDR_WIDTH]};
//        6'd28: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[36*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 36*PORT_ADDR_WIDTH]};
//        6'd29: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[35*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 35*PORT_ADDR_WIDTH]};
//        6'd30: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[34*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 34*PORT_ADDR_WIDTH]};
//        6'd31: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[33*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 33*PORT_ADDR_WIDTH]};
//        6'd32: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[32*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 32*PORT_ADDR_WIDTH]};
//        6'd33: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[31*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 31*PORT_ADDR_WIDTH]};
//        6'd34: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[30*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 30*PORT_ADDR_WIDTH]};
//        6'd35: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[29*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 29*PORT_ADDR_WIDTH]};
//        6'd36: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[28*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 28*PORT_ADDR_WIDTH]};
//        6'd37: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[27*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 27*PORT_ADDR_WIDTH]};
//        6'd38: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[26*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 26*PORT_ADDR_WIDTH]};
//        6'd39: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[25*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 25*PORT_ADDR_WIDTH]};
//        6'd40: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[24*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 24*PORT_ADDR_WIDTH]};
//        6'd41: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[23*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 23*PORT_ADDR_WIDTH]};
//        6'd42: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[22*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 22*PORT_ADDR_WIDTH]};
//        6'd43: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[21*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 21*PORT_ADDR_WIDTH]};
//        6'd44: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[20*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 20*PORT_ADDR_WIDTH]};
//        6'd45: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[19*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 19*PORT_ADDR_WIDTH]};
//        6'd46: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[18*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 18*PORT_ADDR_WIDTH]};
//        6'd47: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[17*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 17*PORT_ADDR_WIDTH]};
//        6'd48: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[16*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 16*PORT_ADDR_WIDTH]};
//        6'd49: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[15*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 15*PORT_ADDR_WIDTH]};
//        6'd50: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[14*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 14*PORT_ADDR_WIDTH]};
//        6'd51: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[13*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 13*PORT_ADDR_WIDTH]};
//        6'd52: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[12*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 12*PORT_ADDR_WIDTH]};
//        6'd53: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[11*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 11*PORT_ADDR_WIDTH]};
//        6'd54: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[10*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 10*PORT_ADDR_WIDTH]};
//        6'd55: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 9*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  9*PORT_ADDR_WIDTH]};
//        6'd56: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 8*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  8*PORT_ADDR_WIDTH]};
//        6'd57: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 7*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  7*PORT_ADDR_WIDTH]};
//        6'd58: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 6*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  6*PORT_ADDR_WIDTH]};
//        6'd59: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 5*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  5*PORT_ADDR_WIDTH]};
//        6'd60: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 4*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  4*PORT_ADDR_WIDTH]};
//        6'd61: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 3*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  3*PORT_ADDR_WIDTH]};
//        6'd62: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 2*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  2*PORT_ADDR_WIDTH]};
//        6'd63: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 1*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  1*PORT_ADDR_WIDTH]};
//      endcase
//    end
//  end
  
//  // data
//  always@(posedge clk) begin
//    if(bram_rd_ddr_bram_valid) begin
//      _bram_rd_ddr_data <= bram_rd_ddr_b_data;
//    end
//  end
  
//  always@(_bram_rd_ddr_channel_idx_4 or _bram_rd_ddr_data or bram_rd_ddr_data_valid) begin
//    if(bram_rd_ddr_data_valid) begin
//      bram_rd_ddr_data = {(49*MID_WIDTH){1'b0}};
//      case(_bram_rd_ddr_channel_idx_4) //synopsys full_case parallel_case
//        6'd0 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+0 )*MID_WIDTH-1 : 0 *MID_WIDTH];
//        6'd1 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+1 )*MID_WIDTH-1 : 1 *MID_WIDTH];
//        6'd2 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+2 )*MID_WIDTH-1 : 2 *MID_WIDTH];
//        6'd3 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+3 )*MID_WIDTH-1 : 3 *MID_WIDTH];
//        6'd4 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+4 )*MID_WIDTH-1 : 4 *MID_WIDTH];
//        6'd5 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+5 )*MID_WIDTH-1 : 5 *MID_WIDTH];
//        6'd6 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+6 )*MID_WIDTH-1 : 6 *MID_WIDTH];
//        6'd7 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+7 )*MID_WIDTH-1 : 7 *MID_WIDTH];
//        6'd8 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+8 )*MID_WIDTH-1 : 8 *MID_WIDTH];
//        6'd9 : bram_rd_ddr_data = _bram_rd_ddr_data[(49+9 )*MID_WIDTH-1 : 9 *MID_WIDTH];
//        6'd10: bram_rd_ddr_data = _bram_rd_ddr_data[(49+10)*MID_WIDTH-1 : 10*MID_WIDTH];
//        6'd11: bram_rd_ddr_data = _bram_rd_ddr_data[(49+11)*MID_WIDTH-1 : 11*MID_WIDTH];
//        6'd12: bram_rd_ddr_data = _bram_rd_ddr_data[(49+12)*MID_WIDTH-1 : 12*MID_WIDTH];
//        6'd13: bram_rd_ddr_data = _bram_rd_ddr_data[(49+13)*MID_WIDTH-1 : 13*MID_WIDTH];
//        6'd14: bram_rd_ddr_data = _bram_rd_ddr_data[(49+14)*MID_WIDTH-1 : 14*MID_WIDTH];
//        6'd15: bram_rd_ddr_data = _bram_rd_ddr_data[(49+15)*MID_WIDTH-1 : 15*MID_WIDTH];
//        6'd16: bram_rd_ddr_data = {_bram_rd_ddr_data[1 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 16*MID_WIDTH]};
//        6'd17: bram_rd_ddr_data = {_bram_rd_ddr_data[2 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 17*MID_WIDTH]};
//        6'd18: bram_rd_ddr_data = {_bram_rd_ddr_data[3 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 18*MID_WIDTH]};
//        6'd19: bram_rd_ddr_data = {_bram_rd_ddr_data[4 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 19*MID_WIDTH]};
//        6'd20: bram_rd_ddr_data = {_bram_rd_ddr_data[5 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 20*MID_WIDTH]};
//        6'd21: bram_rd_ddr_data = {_bram_rd_ddr_data[6 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 21*MID_WIDTH]};
//        6'd22: bram_rd_ddr_data = {_bram_rd_ddr_data[7 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 22*MID_WIDTH]};
//        6'd23: bram_rd_ddr_data = {_bram_rd_ddr_data[8 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 23*MID_WIDTH]};
//        6'd24: bram_rd_ddr_data = {_bram_rd_ddr_data[9 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 24*MID_WIDTH]};
//        6'd25: bram_rd_ddr_data = {_bram_rd_ddr_data[10*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 25*MID_WIDTH]};
//        6'd26: bram_rd_ddr_data = {_bram_rd_ddr_data[11*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 26*MID_WIDTH]};
//        6'd27: bram_rd_ddr_data = {_bram_rd_ddr_data[12*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 27*MID_WIDTH]};
//        6'd28: bram_rd_ddr_data = {_bram_rd_ddr_data[13*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 28*MID_WIDTH]};
//        6'd29: bram_rd_ddr_data = {_bram_rd_ddr_data[14*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 29*MID_WIDTH]};
//        6'd30: bram_rd_ddr_data = {_bram_rd_ddr_data[15*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 30*MID_WIDTH]};
//        6'd31: bram_rd_ddr_data = {_bram_rd_ddr_data[16*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 31*MID_WIDTH]};
//        6'd32: bram_rd_ddr_data = {_bram_rd_ddr_data[17*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 32*MID_WIDTH]};
//        6'd33: bram_rd_ddr_data = {_bram_rd_ddr_data[18*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 33*MID_WIDTH]};
//        6'd34: bram_rd_ddr_data = {_bram_rd_ddr_data[19*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 34*MID_WIDTH]};
//        6'd35: bram_rd_ddr_data = {_bram_rd_ddr_data[20*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 35*MID_WIDTH]};
//        6'd36: bram_rd_ddr_data = {_bram_rd_ddr_data[21*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 36*MID_WIDTH]};
//        6'd37: bram_rd_ddr_data = {_bram_rd_ddr_data[22*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 37*MID_WIDTH]};
//        6'd38: bram_rd_ddr_data = {_bram_rd_ddr_data[23*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 38*MID_WIDTH]};
//        6'd39: bram_rd_ddr_data = {_bram_rd_ddr_data[24*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 39*MID_WIDTH]};
//        6'd40: bram_rd_ddr_data = {_bram_rd_ddr_data[25*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 40*MID_WIDTH]};
//        6'd41: bram_rd_ddr_data = {_bram_rd_ddr_data[26*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 41*MID_WIDTH]};
//        6'd42: bram_rd_ddr_data = {_bram_rd_ddr_data[27*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 42*MID_WIDTH]};
//        6'd43: bram_rd_ddr_data = {_bram_rd_ddr_data[28*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 43*MID_WIDTH]};
//        6'd44: bram_rd_ddr_data = {_bram_rd_ddr_data[29*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 44*MID_WIDTH]};
//        6'd45: bram_rd_ddr_data = {_bram_rd_ddr_data[30*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 45*MID_WIDTH]};
//        6'd46: bram_rd_ddr_data = {_bram_rd_ddr_data[31*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 46*MID_WIDTH]};
//        6'd47: bram_rd_ddr_data = {_bram_rd_ddr_data[32*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 47*MID_WIDTH]};
//        6'd48: bram_rd_ddr_data = {_bram_rd_ddr_data[33*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 48*MID_WIDTH]};
//        6'd49: bram_rd_ddr_data = {_bram_rd_ddr_data[34*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 49*MID_WIDTH]};
//        6'd50: bram_rd_ddr_data = {_bram_rd_ddr_data[35*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 50*MID_WIDTH]};
//        6'd51: bram_rd_ddr_data = {_bram_rd_ddr_data[36*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 51*MID_WIDTH]};
//        6'd52: bram_rd_ddr_data = {_bram_rd_ddr_data[37*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 52*MID_WIDTH]};
//        6'd53: bram_rd_ddr_data = {_bram_rd_ddr_data[38*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 53*MID_WIDTH]};
//        6'd54: bram_rd_ddr_data = {_bram_rd_ddr_data[39*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 54*MID_WIDTH]};
//        6'd55: bram_rd_ddr_data = {_bram_rd_ddr_data[40*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 55*MID_WIDTH]};
//        6'd56: bram_rd_ddr_data = {_bram_rd_ddr_data[41*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 56*MID_WIDTH]};
//        6'd57: bram_rd_ddr_data = {_bram_rd_ddr_data[42*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 57*MID_WIDTH]};
//        6'd58: bram_rd_ddr_data = {_bram_rd_ddr_data[43*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 58*MID_WIDTH]};
//        6'd59: bram_rd_ddr_data = {_bram_rd_ddr_data[44*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 59*MID_WIDTH]};
//        6'd60: bram_rd_ddr_data = {_bram_rd_ddr_data[45*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 60*MID_WIDTH]};
//        6'd61: bram_rd_ddr_data = {_bram_rd_ddr_data[46*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 61*MID_WIDTH]};
//        6'd62: bram_rd_ddr_data = {_bram_rd_ddr_data[47*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 62*MID_WIDTH]};
//        6'd63: bram_rd_ddr_data = {_bram_rd_ddr_data[48*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_data[64*MID_WIDTH-1 : 63*MID_WIDTH]};
//      endcase
//    end else begin
//      bram_rd_ddr_data = {(49*MID_WIDTH){1'b0}};
//    end
//  end
  
//endmodule


//register output
module bram_ddr_rd #(
    parameter MID_WIDTH = 29,
    parameter K_C = 64,
    parameter PORT_ADDR_WIDTH = 11
  ) (
    input  wire                                 clk,
    input  wire                                 rst_n,
    // addr
    input  wire[2:0]                            bram_rd_ddr_ker_set,
    input  wire[5:0]                            bram_rd_ddr_channel_idx, // channel index in one kernel set? 0?63
    input  wire[1:0]                            bram_rd_ddr_quarter_num,
    output reg [K_C*PORT_ADDR_WIDTH-1 : 0]      bram_rd_ddr_addr_b,
    // enable
    input  wire                                 bram_rd_ddr_en,     // enable
    input  wire                                 bram_rd_ddr_rd_en,  //in conv, port b read enable
    input  wire                                 bram_rd_ddr_next_quar, // clear valid signal
    output reg                                  bram_rd_ddr_en_bram,
    output reg                                  bram_rd_ddr_bram_valid,
    // data
    input  wire[K_C*MID_WIDTH-1:0]              bram_rd_ddr_b_data,
    output reg                                  bram_rd_ddr_data_valid,
    output reg [49*MID_WIDTH-1:0]               bram_rd_ddr_data
  );

  wire[PORT_ADDR_WIDTH-1 : 0]     _bram_rd_ddr_base_addr;
  reg [64*PORT_ADDR_WIDTH-1 : 0]  _bram_rd_ddr_addr;
  reg [K_C*MID_WIDTH-1:0]         _bram_rd_ddr_b_data;
  reg [49*MID_WIDTH-1 : 0]        _bram_rd_ddr_data;
  reg [5:0]                       _bram_rd_ddr_channel_idx_1;
  reg [5:0]                       _bram_rd_ddr_channel_idx_2;
  reg [5:0]                       _bram_rd_ddr_channel_idx_3;
  reg [5:0]                       _bram_rd_ddr_channel_idx_4;
  reg                             _bram_rd_ddr_rd_en;
  reg                             _bram_rd_ddr_data_en;
  assign _bram_rd_ddr_base_addr = {bram_rd_ddr_ker_set,bram_rd_ddr_quarter_num}*6'd49;

  // enable
  reg     _bram_rd_ddr_data_en_reg; //fixed_to_float
  reg     _bram_rd_ddr_data_en_reg2;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bram_rd_ddr_en_bram     <= 1'b0;
      bram_rd_ddr_bram_valid  <= 1'b0;
      _bram_rd_ddr_data_en     <= 1'b0;
      _bram_rd_ddr_data_en_reg  <= 1'b0;
      _bram_rd_ddr_data_en_reg2 <= 1'b0;
    end else begin
      _bram_rd_ddr_rd_en      <= bram_rd_ddr_rd_en;
      bram_rd_ddr_en_bram     <= _bram_rd_ddr_rd_en;
      bram_rd_ddr_bram_valid  <= bram_rd_ddr_en_bram;
      _bram_rd_ddr_data_en     <= bram_rd_ddr_bram_valid;
      _bram_rd_ddr_data_en_reg  <= _bram_rd_ddr_data_en;
      _bram_rd_ddr_data_en_reg2 <= _bram_rd_ddr_data_en_reg;
    end
  end
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bram_rd_ddr_data_valid  <= 1'b0;
    end else begin 
      if(!bram_rd_ddr_en || bram_rd_ddr_next_quar) begin
        bram_rd_ddr_data_valid  <= 1'b0;
      end else if(bram_rd_ddr_en && _bram_rd_ddr_data_en_reg2) begin
        bram_rd_ddr_data_valid  <= 1'b1;
      end
    end
  end
  
  // channel index delay
  always@(posedge clk) begin
    _bram_rd_ddr_channel_idx_1 <= bram_rd_ddr_channel_idx;
    _bram_rd_ddr_channel_idx_2 <= _bram_rd_ddr_channel_idx_1;
    _bram_rd_ddr_channel_idx_3 <= _bram_rd_ddr_channel_idx_2;
    _bram_rd_ddr_channel_idx_4 <= _bram_rd_ddr_channel_idx_3;
  end
  
  // address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _bram_rd_ddr_addr <= {(64*PORT_ADDR_WIDTH){1'b0}};
    end else begin
      if(bram_rd_ddr_rd_en) begin //down direction
        _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 63*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[63*PORT_ADDR_WIDTH-1 : 62*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[62*PORT_ADDR_WIDTH-1 : 61*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[61*PORT_ADDR_WIDTH-1 : 60*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[60*PORT_ADDR_WIDTH-1 : 59*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[59*PORT_ADDR_WIDTH-1 : 58*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[58*PORT_ADDR_WIDTH-1 : 57*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[57*PORT_ADDR_WIDTH-1 : 56*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[56*PORT_ADDR_WIDTH-1 : 55*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[55*PORT_ADDR_WIDTH-1 : 54*PORT_ADDR_WIDTH] <= 11'd0; 
        _bram_rd_ddr_addr[54*PORT_ADDR_WIDTH-1 : 53*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[53*PORT_ADDR_WIDTH-1 : 52*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[52*PORT_ADDR_WIDTH-1 : 51*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[51*PORT_ADDR_WIDTH-1 : 50*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[50*PORT_ADDR_WIDTH-1 : 49*PORT_ADDR_WIDTH] <= 11'd0;
        _bram_rd_ddr_addr[49*PORT_ADDR_WIDTH-1 : 48*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd48;
        _bram_rd_ddr_addr[48*PORT_ADDR_WIDTH-1 : 47*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd47;
        _bram_rd_ddr_addr[47*PORT_ADDR_WIDTH-1 : 46*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd46;
        _bram_rd_ddr_addr[46*PORT_ADDR_WIDTH-1 : 45*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd45;
        _bram_rd_ddr_addr[45*PORT_ADDR_WIDTH-1 : 44*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd44;
        _bram_rd_ddr_addr[44*PORT_ADDR_WIDTH-1 : 43*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd43;
        _bram_rd_ddr_addr[43*PORT_ADDR_WIDTH-1 : 42*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd42;
        _bram_rd_ddr_addr[42*PORT_ADDR_WIDTH-1 : 41*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd41;
        _bram_rd_ddr_addr[41*PORT_ADDR_WIDTH-1 : 40*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd40;
        _bram_rd_ddr_addr[40*PORT_ADDR_WIDTH-1 : 39*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd39;
        _bram_rd_ddr_addr[39*PORT_ADDR_WIDTH-1 : 38*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd38;
        _bram_rd_ddr_addr[38*PORT_ADDR_WIDTH-1 : 37*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd37;
        _bram_rd_ddr_addr[37*PORT_ADDR_WIDTH-1 : 36*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd36;
        _bram_rd_ddr_addr[36*PORT_ADDR_WIDTH-1 : 35*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd35;
        _bram_rd_ddr_addr[35*PORT_ADDR_WIDTH-1 : 34*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd34;
        _bram_rd_ddr_addr[34*PORT_ADDR_WIDTH-1 : 33*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd33;
        _bram_rd_ddr_addr[33*PORT_ADDR_WIDTH-1 : 32*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd32;
        _bram_rd_ddr_addr[32*PORT_ADDR_WIDTH-1 : 31*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd31;
        _bram_rd_ddr_addr[31*PORT_ADDR_WIDTH-1 : 30*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd30;
        _bram_rd_ddr_addr[30*PORT_ADDR_WIDTH-1 : 29*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd29;
        _bram_rd_ddr_addr[29*PORT_ADDR_WIDTH-1 : 28*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd28;
        _bram_rd_ddr_addr[28*PORT_ADDR_WIDTH-1 : 27*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd27;
        _bram_rd_ddr_addr[27*PORT_ADDR_WIDTH-1 : 26*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd26;
        _bram_rd_ddr_addr[26*PORT_ADDR_WIDTH-1 : 25*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd25;
        _bram_rd_ddr_addr[25*PORT_ADDR_WIDTH-1 : 24*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd24;
        _bram_rd_ddr_addr[24*PORT_ADDR_WIDTH-1 : 23*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd23;
        _bram_rd_ddr_addr[23*PORT_ADDR_WIDTH-1 : 22*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd22;
        _bram_rd_ddr_addr[22*PORT_ADDR_WIDTH-1 : 21*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd21;
        _bram_rd_ddr_addr[21*PORT_ADDR_WIDTH-1 : 20*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd20;
        _bram_rd_ddr_addr[20*PORT_ADDR_WIDTH-1 : 19*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd19;
        _bram_rd_ddr_addr[19*PORT_ADDR_WIDTH-1 : 18*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd18;
        _bram_rd_ddr_addr[18*PORT_ADDR_WIDTH-1 : 17*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd17;
        _bram_rd_ddr_addr[17*PORT_ADDR_WIDTH-1 : 16*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd16;
        _bram_rd_ddr_addr[16*PORT_ADDR_WIDTH-1 : 15*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd15;
        _bram_rd_ddr_addr[15*PORT_ADDR_WIDTH-1 : 14*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd14;
        _bram_rd_ddr_addr[14*PORT_ADDR_WIDTH-1 : 13*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd13;
        _bram_rd_ddr_addr[13*PORT_ADDR_WIDTH-1 : 12*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd12;
        _bram_rd_ddr_addr[12*PORT_ADDR_WIDTH-1 : 11*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd11;
        _bram_rd_ddr_addr[11*PORT_ADDR_WIDTH-1 : 10*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd10;
        _bram_rd_ddr_addr[10*PORT_ADDR_WIDTH-1 :  9*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd9; 
        _bram_rd_ddr_addr[ 9*PORT_ADDR_WIDTH-1 :  8*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd8; 
        _bram_rd_ddr_addr[ 8*PORT_ADDR_WIDTH-1 :  7*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd7; 
        _bram_rd_ddr_addr[ 7*PORT_ADDR_WIDTH-1 :  6*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd6; 
        _bram_rd_ddr_addr[ 6*PORT_ADDR_WIDTH-1 :  5*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd5; 
        _bram_rd_ddr_addr[ 5*PORT_ADDR_WIDTH-1 :  4*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd4; 
        _bram_rd_ddr_addr[ 4*PORT_ADDR_WIDTH-1 :  3*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd3; 
        _bram_rd_ddr_addr[ 3*PORT_ADDR_WIDTH-1 :  2*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd2; 
        _bram_rd_ddr_addr[ 2*PORT_ADDR_WIDTH-1 :  1*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd1; 
        _bram_rd_ddr_addr[ 1*PORT_ADDR_WIDTH-1 :  0*PORT_ADDR_WIDTH] <= _bram_rd_ddr_base_addr + 11'd0; 
      end
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bram_rd_ddr_addr_b <= {64*PORT_ADDR_WIDTH{1'b0}};
    end else begin
      case(_bram_rd_ddr_channel_idx_1) //0~48
        6'd0 : bram_rd_ddr_addr_b <=  _bram_rd_ddr_addr;
        6'd1 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[63*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 63*PORT_ADDR_WIDTH]};
        6'd2 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[62*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 62*PORT_ADDR_WIDTH]};
        6'd3 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[61*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 61*PORT_ADDR_WIDTH]};
        6'd4 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[60*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 60*PORT_ADDR_WIDTH]};
        6'd5 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[59*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 59*PORT_ADDR_WIDTH]};
        6'd6 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[58*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 58*PORT_ADDR_WIDTH]};
        6'd7 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[57*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 57*PORT_ADDR_WIDTH]};
        6'd8 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[56*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 56*PORT_ADDR_WIDTH]};
        6'd9 : bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[55*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 55*PORT_ADDR_WIDTH]};
        6'd10: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[54*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 54*PORT_ADDR_WIDTH]};
        6'd11: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[53*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 53*PORT_ADDR_WIDTH]};
        6'd12: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[52*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 52*PORT_ADDR_WIDTH]};
        6'd13: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[51*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 51*PORT_ADDR_WIDTH]};
        6'd14: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[50*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 50*PORT_ADDR_WIDTH]};
        6'd15: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[49*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 49*PORT_ADDR_WIDTH]};
        6'd16: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[48*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 48*PORT_ADDR_WIDTH]};
        6'd17: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[47*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 47*PORT_ADDR_WIDTH]};
        6'd18: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[46*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 46*PORT_ADDR_WIDTH]};
        6'd19: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[45*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 45*PORT_ADDR_WIDTH]};
        6'd20: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[44*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 44*PORT_ADDR_WIDTH]};
        6'd21: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[43*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 43*PORT_ADDR_WIDTH]};
        6'd22: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[42*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 42*PORT_ADDR_WIDTH]};
        6'd23: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[41*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 41*PORT_ADDR_WIDTH]};
        6'd24: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[40*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 40*PORT_ADDR_WIDTH]};
        6'd25: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[39*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 39*PORT_ADDR_WIDTH]};
        6'd26: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[38*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 38*PORT_ADDR_WIDTH]};
        6'd27: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[37*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 37*PORT_ADDR_WIDTH]};
        6'd28: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[36*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 36*PORT_ADDR_WIDTH]};
        6'd29: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[35*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 35*PORT_ADDR_WIDTH]};
        6'd30: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[34*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 34*PORT_ADDR_WIDTH]};
        6'd31: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[33*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 33*PORT_ADDR_WIDTH]};
        6'd32: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[32*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 32*PORT_ADDR_WIDTH]};
        6'd33: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[31*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 31*PORT_ADDR_WIDTH]};
        6'd34: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[30*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 30*PORT_ADDR_WIDTH]};
        6'd35: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[29*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 29*PORT_ADDR_WIDTH]};
        6'd36: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[28*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 28*PORT_ADDR_WIDTH]};
        6'd37: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[27*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 27*PORT_ADDR_WIDTH]};
        6'd38: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[26*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 26*PORT_ADDR_WIDTH]};
        6'd39: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[25*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 25*PORT_ADDR_WIDTH]};
        6'd40: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[24*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 24*PORT_ADDR_WIDTH]};
        6'd41: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[23*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 23*PORT_ADDR_WIDTH]};
        6'd42: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[22*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 22*PORT_ADDR_WIDTH]};
        6'd43: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[21*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 21*PORT_ADDR_WIDTH]};
        6'd44: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[20*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 20*PORT_ADDR_WIDTH]};
        6'd45: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[19*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 19*PORT_ADDR_WIDTH]};
        6'd46: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[18*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 18*PORT_ADDR_WIDTH]};
        6'd47: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[17*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 17*PORT_ADDR_WIDTH]};
        6'd48: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[16*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 16*PORT_ADDR_WIDTH]};
        6'd49: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[15*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 15*PORT_ADDR_WIDTH]};
        6'd50: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[14*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 14*PORT_ADDR_WIDTH]};
        6'd51: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[13*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 13*PORT_ADDR_WIDTH]};
        6'd52: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[12*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 12*PORT_ADDR_WIDTH]};
        6'd53: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[11*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 11*PORT_ADDR_WIDTH]};
        6'd54: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[10*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 : 10*PORT_ADDR_WIDTH]};
        6'd55: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 9*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  9*PORT_ADDR_WIDTH]};
        6'd56: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 8*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  8*PORT_ADDR_WIDTH]};
        6'd57: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 7*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  7*PORT_ADDR_WIDTH]};
        6'd58: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 6*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  6*PORT_ADDR_WIDTH]};
        6'd59: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 5*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  5*PORT_ADDR_WIDTH]};
        6'd60: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 4*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  4*PORT_ADDR_WIDTH]};
        6'd61: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 3*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  3*PORT_ADDR_WIDTH]};
        6'd62: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 2*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  2*PORT_ADDR_WIDTH]};
        6'd63: bram_rd_ddr_addr_b <= {_bram_rd_ddr_addr[ 1*PORT_ADDR_WIDTH-1 : 0*PORT_ADDR_WIDTH] , _bram_rd_ddr_addr[64*PORT_ADDR_WIDTH-1 :  1*PORT_ADDR_WIDTH]};
      endcase
    end
  end
  
  // data
  always@(posedge clk) begin
//    if(_bram_rd_ddr_data_en) begin
      bram_rd_ddr_data <= _bram_rd_ddr_data;
//    end
  end

  always@(posedge clk) begin
    if(bram_rd_ddr_bram_valid) begin
        _bram_rd_ddr_b_data <=  bram_rd_ddr_b_data;
    end
  end
  always@(_bram_rd_ddr_channel_idx_4 or _bram_rd_ddr_b_data) begin
      _bram_rd_ddr_data = {(49*MID_WIDTH){1'b0}};
      case(_bram_rd_ddr_channel_idx_4)//synopsys full_case parallel_case
        6'd0 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+0 )*MID_WIDTH-1 : 0 *MID_WIDTH];
        6'd1 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+1 )*MID_WIDTH-1 : 1 *MID_WIDTH];
        6'd2 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+2 )*MID_WIDTH-1 : 2 *MID_WIDTH];
        6'd3 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+3 )*MID_WIDTH-1 : 3 *MID_WIDTH];
        6'd4 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+4 )*MID_WIDTH-1 : 4 *MID_WIDTH];
        6'd5 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+5 )*MID_WIDTH-1 : 5 *MID_WIDTH];
        6'd6 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+6 )*MID_WIDTH-1 : 6 *MID_WIDTH];
        6'd7 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+7 )*MID_WIDTH-1 : 7 *MID_WIDTH];
        6'd8 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+8 )*MID_WIDTH-1 : 8 *MID_WIDTH];
        6'd9 : _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+9 )*MID_WIDTH-1 : 9 *MID_WIDTH];
        6'd10: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+10)*MID_WIDTH-1 : 10*MID_WIDTH];
        6'd11: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+11)*MID_WIDTH-1 : 11*MID_WIDTH];
        6'd12: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+12)*MID_WIDTH-1 : 12*MID_WIDTH];
        6'd13: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+13)*MID_WIDTH-1 : 13*MID_WIDTH];
        6'd14: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+14)*MID_WIDTH-1 : 14*MID_WIDTH];
        6'd15: _bram_rd_ddr_data = _bram_rd_ddr_b_data[(49+15)*MID_WIDTH-1 : 15*MID_WIDTH];
        6'd16: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[1 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 16*MID_WIDTH]};
        6'd17: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[2 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 17*MID_WIDTH]};
        6'd18: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[3 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 18*MID_WIDTH]};
        6'd19: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[4 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 19*MID_WIDTH]};
        6'd20: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[5 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 20*MID_WIDTH]};
        6'd21: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[6 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 21*MID_WIDTH]};
        6'd22: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[7 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 22*MID_WIDTH]};
        6'd23: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[8 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 23*MID_WIDTH]};
        6'd24: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[9 *MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 24*MID_WIDTH]};
        6'd25: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[10*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 25*MID_WIDTH]};
        6'd26: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[11*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 26*MID_WIDTH]};
        6'd27: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[12*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 27*MID_WIDTH]};
        6'd28: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[13*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 28*MID_WIDTH]};
        6'd29: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[14*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 29*MID_WIDTH]};
        6'd30: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[15*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 30*MID_WIDTH]};
        6'd31: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[16*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 31*MID_WIDTH]};
        6'd32: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[17*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 32*MID_WIDTH]};
        6'd33: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[18*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 33*MID_WIDTH]};
        6'd34: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[19*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 34*MID_WIDTH]};
        6'd35: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[20*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 35*MID_WIDTH]};
        6'd36: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[21*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 36*MID_WIDTH]};
        6'd37: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[22*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 37*MID_WIDTH]};
        6'd38: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[23*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 38*MID_WIDTH]};
        6'd39: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[24*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 39*MID_WIDTH]};
        6'd40: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[25*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 40*MID_WIDTH]};
        6'd41: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[26*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 41*MID_WIDTH]};
        6'd42: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[27*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 42*MID_WIDTH]};
        6'd43: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[28*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 43*MID_WIDTH]};
        6'd44: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[29*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 44*MID_WIDTH]};
        6'd45: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[30*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 45*MID_WIDTH]};
        6'd46: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[31*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 46*MID_WIDTH]};
        6'd47: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[32*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 47*MID_WIDTH]};
        6'd48: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[33*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 48*MID_WIDTH]};
        6'd49: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[34*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 49*MID_WIDTH]};
        6'd50: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[35*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 50*MID_WIDTH]};
        6'd51: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[36*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 51*MID_WIDTH]};
        6'd52: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[37*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 52*MID_WIDTH]};
        6'd53: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[38*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 53*MID_WIDTH]};
        6'd54: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[39*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 54*MID_WIDTH]};
        6'd55: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[40*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 55*MID_WIDTH]};
        6'd56: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[41*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 56*MID_WIDTH]};
        6'd57: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[42*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 57*MID_WIDTH]};
        6'd58: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[43*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 58*MID_WIDTH]};
        6'd59: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[44*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 59*MID_WIDTH]};
        6'd60: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[45*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 60*MID_WIDTH]};
        6'd61: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[46*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 61*MID_WIDTH]};
        6'd62: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[47*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 62*MID_WIDTH]};
        6'd63: _bram_rd_ddr_data = {_bram_rd_ddr_b_data[48*MID_WIDTH-1 :  0*MID_WIDTH] , _bram_rd_ddr_b_data[64*MID_WIDTH-1 : 63*MID_WIDTH]};
      endcase
  end
  
endmodule


