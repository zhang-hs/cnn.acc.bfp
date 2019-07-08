// right shift simulation top module

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
    A_i = 32'h3e6c074f;
    B_i = 32'h8f437ebe;
    C_i = 32'h3e5c074f;
    //D_o = 26'hff;
    #100
    $display("[%t] : A_i: %h, B_i: %h C_i: %h\n", $realtime, A_i, B_i, C_i);
    $display("[%t] : A_o: %h, B_o: %h C_o: %h\n", $realtime, A_o, B_o, C_o);
    $display("[%t] : A_sign:%h, B_sign:%h, C_sign:%h\n", $realtime, A_sign, B_sign, C_sign);
    $display("[%t] : D_o:%h\n", $realtime, D_o);
    $finish;
  end

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
