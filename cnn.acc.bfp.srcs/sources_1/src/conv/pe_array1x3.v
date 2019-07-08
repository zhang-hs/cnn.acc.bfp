`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/23 21:38:07
// Module Name: pe_array1x3_bias
// Description: 1 dim(1x3) processing element array
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module pe_array1x3#(
  parameter DATA_WIDTH  = 8,
  parameter MID_WIDTH   = 29
)(
  input  wire [3*DATA_WIDTH-1:0]    pe_ker3_i,
  input  wire [MID_WIDTH-1:0]       pe_bias_i,
  input  wire [3*DATA_WIDTH-1:0]    pe_data3_i,
  input  wire                       clk,
  input  wire                       pe_en, // start calculation
  output wire                       pe_next_partial_sum, // require next partial sum
  output reg [MID_WIDTH-1:0]        pe_data_o,
  output reg                        pe_data_valid
);

  reg                        _pe_en;
  reg  [3*DATA_WIDTH-1:0]    _pe_ker3_i;
  reg  [3*DATA_WIDTH-1:0]    _pe_data3_i;
  wire [2*DATA_WIDTH-1:0]    _mul_h;
  wire [2*DATA_WIDTH-1:0]    _mul_m;
  wire [2*DATA_WIDTH-1:0]    _mul_l;
  reg                        _req_1;
  reg                        _req_2;
  reg                        _req_3;
  reg                        _req_4;
  wire [17-1:0]              _sum_2;
  wire [18-1:0]              _sum_3;
  reg  [18-1:0]              _sum_3_reg;
  wire [MID_WIDTH-1:0]       _pe_data_o;
  
//  assign pe_next_partial_sum = _pe_en; //time to read partial sum
  assign pe_next_partial_sum = pe_en; //time to read partial sum
  
  always@(posedge clk) begin
    if(pe_en) begin
      _pe_en <= pe_en;
      _pe_ker3_i <= pe_ker3_i;
      _pe_data3_i <= pe_data3_i;
    end else begin
      _pe_en <= 1'b0;
    end
  end
  
  always@(posedge clk) begin
    _req_1 <= _pe_en;
    _req_2 <= _req_1;
    _req_3 <= _req_2;
    _req_4 <= _req_3;
    pe_data_valid <= _req_4;
  end
  
  always@(posedge clk) begin
    _sum_3_reg <= _sum_3;
    pe_data_o <= _pe_data_o;
  end

  // 3 multiply
  wire  _ce;
  assign _ce = _pe_en || _req_2;
  mult2 pe_mul_h(
    .CLK(clk),
    .A(_pe_data3_i[3*DATA_WIDTH-1:2*DATA_WIDTH]),
    .B(_pe_ker3_i[3*DATA_WIDTH-1:2*DATA_WIDTH]),
    .CE(_ce), //control whether IP works.
    .P(_mul_h)
  );

  mult2 pe_mul_m(
    .CLK(clk),
    .A(_pe_data3_i[2*DATA_WIDTH-1:DATA_WIDTH]),
    .B(_pe_ker3_i[2*DATA_WIDTH-1:DATA_WIDTH]),
    .CE(_ce),
    .P(_mul_m)
   );

  mult2 pe_mul_l(
    .CLK(clk),
    .A(_pe_data3_i[DATA_WIDTH-1:0]),
    .B(_pe_ker3_i[DATA_WIDTH-1:0]),
    .CE(_ce),
    .P(_mul_l)
  );
  
  // 2 level adder
  adder_1 sum_2(
    .A(_mul_h),
    .B(_mul_m),
    .CE(_req_3),
    .S(_sum_2)
  );
  
  adder_2 sum_3(
    .A(_sum_2),
    .B(_mul_l),
    .CE(_req_3),
    .S(_sum_3)
  );
  
  adder_3 sum_bias(
    .A(pe_bias_i),
    .B(_sum_3_reg),
    .CE(_req_4),
    .S(_pe_data_o)
  );


endmodule
