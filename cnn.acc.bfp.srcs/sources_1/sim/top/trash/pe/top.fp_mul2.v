// float point multiplication simulation top module
`timescale 1ns/1ps

module top;
  reg clk;
  reg [31:0] A;
  reg [31:0] B;
  reg [31:0] C;

  localparam EXP = 8;
  localparam MAN = 23;
  reg [MAN:0]  exp_sum; //[(MAN+3)*2-1:0]

  initial begin
    clk = 1'b1;
    //A   = 32'h3e6c074f;
    //B   = 32'h3f437ebe;
    A   = 32'h430260bb;
    B   = 32'hbd7b54be;
    #100
    $display("[%t] : %h mul %h is %h\n", $realtime, A, B, C);
    $display("[%t] : exponent sum: %b\n", $realtime, exp_sum);
    $finish;
  end

  fp_mul2#(.EXPONENT(EXP),
          .MANTISSA(MAN)
    ) mul2(
    .A(A),
    .B(B),
    ._expOutput(exp_sum),
    .C(C)
  );

  always #10 clk=~clk;

endmodule
