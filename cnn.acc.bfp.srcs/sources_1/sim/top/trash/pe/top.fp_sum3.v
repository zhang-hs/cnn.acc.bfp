// sum up 3 operand simulation top module

`timescale 1ns/1ps

module top;
  localparam EXP = 8;
  localparam MAN = 23;

  reg clk;
  reg [EXP+MAN:0] A_i;
  reg [EXP+MAN:0] B_i;
  reg [EXP+MAN:0] C_i;
  reg             A_sign;
  reg             B_sign;
  reg             C_sign;

  reg [MAN+4:0]   D_o;
  reg             D_sign;

  initial begin
    clk = 1'b1;
    A_i = 32'h0;
    B_i = 32'h0;
    C_i = 32'h0;
    #10
    A_i = 32'hcfa6a865; // -1.302014
    B_i = 32'hbc81abaa; // -0.015829
    C_i = 32'hcdc9bbee; // -0.098503
    //D_o = 26'hff;
    #100
    $display("[%t] : A_i: %h, B_i: %h C_i: %h\n", $realtime, A_i, B_i, C_i);
    $display("[%t] : A_sign:%b, B_sign:%b, C_sign:%b\n", $realtime, A_i[EXP+MAN], B_i[EXP+MAN], C_i[EXP+MAN]);
    $display("[%t] : D_o:%h\n", $realtime, D_o);
    $display("[%t] : D_sign:%b\n", $realtime, D_sign);
    $finish;
  end

  fp_sum3#(
          .EXPONENT(EXP),
          .MANTISSA(MAN)
    ) sum3(
          .a1_mantissa_unsigned({1'b1,A_i[MAN-1:0],2'b0}),
          .a2_mantissa_unsigned({1'b1,B_i[MAN-1:0],2'b0}),
          .a3_mantissa_unsigned({1'b1,C_i[MAN-1:0],2'b0}),
          .a1_sign(A_i[EXP+MAN]),
          .a2_sign(B_i[EXP+MAN]),
          .a3_sign(C_i[EXP+MAN]),
          .sum_unsigned(D_o),
          .sum_sign(D_sign)
    );

  always #10 clk=~clk;

endmodule
