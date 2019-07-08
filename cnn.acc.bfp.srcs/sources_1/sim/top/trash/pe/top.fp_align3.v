// alignment simulation top module

`timescale 1ns/1ps

module top;
  localparam EXP = 8;
  localparam MAN = 23;

  reg clk;
  reg [EXP+MAN:0] A_i;
  reg [EXP+MAN:0] B_i;
  reg [EXP+MAN:0] C_i;
  reg [MAN+2:0]   A_o;
  reg [MAN+2:0]   B_o;
  reg [MAN+2:0]   C_o;
  reg [MAN+2:0]   D_o;
  reg             A_sign;
  reg             B_sign;
  reg             C_sign;

  initial begin
    clk = 1'b1;
    A_i = 32'h0;
    B_i = 32'h0;
    C_i = 32'h0;
    #10
    A_i = 32'h3e71d0a6;
    B_i = 32'h3f2f9e2c;
    C_i = 32'hbc81abaa;
    //Ai  = {1'b1,A_i[MAN-1:0],2'b00};
    //Bi  = {1'b1,B_i[MAN-1:0],2'b00};
    //Ci  = {1'b1,C_i[MAN-1:0],2'b00};
    //D_o = 26'hff;
    #100
    $display("[%t] : A_i: %h, B_i: %h C_i: %h\n", $realtime, {1'b1,A_i[MAN-1:0],2'b00}, {1'b1,B_i[MAN-1:0],2'b00}, {1'b1,C_i[MAN-1:0],2'b00});
    $display("[%t] : A_o: %h, B_o: %h C_o: %h\n", $realtime, A_o, B_o, C_o);
    $display("[%t] : A_sign:%h, B_sign:%h, C_sign:%h\n", $realtime, A_sign, B_sign, C_sign);
    $display("[%t] : D_o:%h\n", $realtime, D_o);
    $finish;
  end

  fp_align3#(
          .EXPONENT(EXP),
          .MANTISSA(MAN)
    ) align3(
    .a1(A_i),
    .a2(B_i),
    .a3(C_i),
    .a1_mantissa(A_o),
    .a2_mantissa(B_o),
    .a3_mantissa(C_o),
    .a1_sign(A_sign),
    .a2_sign(B_sign),
    .a3_sign(C_sign)
  );

  fp_rshift#(
          .EXPONENT(EXP),
          .MANTISSA(MAN)
    ) rshift(
          .val({1'b1,B_i[MAN-1:0]}),
          .count(8'h3),
          .val_o(D_o)
    );

  always #10 clk=~clk;

endmodule
