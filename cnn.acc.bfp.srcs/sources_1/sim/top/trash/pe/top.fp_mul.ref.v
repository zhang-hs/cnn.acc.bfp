`timescale 1ns/1ps

module top;
  reg clk;
  reg [31:0] A;
  reg [31:0] B;
  reg [31:0] C;

  localparam EXP = 8;
  localparam MAN = 23;

  initial begin
    clk = 1'b1;
    A   = 32'h3e6c074f;
    B   = 32'h3f437ebe;
    #100
    $display("[%t] : %h mul %h is %h\n", $realtime, A, B, C);
    $finish;
  end

  fpmul #(.wE(EXP),
          .wF(MAN)
    )(
    .nA(A),
    .nB(B),
    .nR(C)
  );

  always #10 clk=~clk;

endmodule
