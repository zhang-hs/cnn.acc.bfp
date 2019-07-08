`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:zhanghs 
// 
// Create Date: 2018/11/12 20:36:37
// Module Name: bram_conv_wr
// Project Name: vgg.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: top fm storage, bram:64 x (32)width x(14x14x8)depth
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module bram_buffer #(
  parameter MID_WIDTH = 29,
  parameter K_C = 64,
  parameter PORT_ADDR_WIDTH = 11
)(
  input   wire                                clk,
  // port a
  input   wire[K_C*PORT_ADDR_WIDTH-1:0]       port_a_addr, // 32*port_addr_width-1 : 0
  input   wire                                port_a_en,
  input   wire                                port_a_wr_en,
  input   wire[K_C*MID_WIDTH-1:0]             port_a_data_i,
  // port b
  input   wire[K_C*PORT_ADDR_WIDTH-1:0]       port_b_addr, // port b address, 32*port_addr_width-1 : 0
  input   wire                                port_b_en, // read enable
  // output
  output  wire[K_C*MID_WIDTH-1:0]             port_a_data_o,
  output  wire[K_C*MID_WIDTH-1:0]             port_b_data_o
  );
  
  wire [2:0]  _port_a_data_o_tmp[0:K_C-1];
  wire [2:0]  _port_b_data_o_tmp[0:K_C-1];
  
  genvar i;
  generate
    for(i=0; i<K_C; i=i+1) 
    begin: top_buffer
      of_blkmem  bram_top(
        .clka  (clk),    // input wire clka
        .ena   (port_a_en),      // input wire ena
        .wea   (port_a_wr_en),      // input wire [0 : 0] wea
        .addra (port_a_addr[(i+1)*PORT_ADDR_WIDTH-1 : i*PORT_ADDR_WIDTH]),  // input wire [11 : 0] addra
        .dina  ({3'b0, port_a_data_i[(i+1)*MID_WIDTH-1 : i*MID_WIDTH]}),    // input wire [31 : 0] dina
        .douta ({_port_a_data_o_tmp[i], port_a_data_o[(i+1)*MID_WIDTH-1 : i*MID_WIDTH]}),  // output wire [31 : 0] douta
        .clkb  (clk),    // input wire clkb
        .enb   (port_b_en),      // input wire enb
        .web   (1'b0),      // input wire [0 : 0] web
        .addrb (port_b_addr[(i+1)*PORT_ADDR_WIDTH-1 : i*PORT_ADDR_WIDTH]),  // input wire [11 : 0] addrb
        .dinb  ({32{1'b0}}),    // input wire [31 : 0] dinb
        .doutb ({_port_b_data_o_tmp[i], port_b_data_o[(i+1)*MID_WIDTH-1 : i*MID_WIDTH]})  // output wire [31 : 0] doutb
      );
    end
  endgenerate
endmodule
