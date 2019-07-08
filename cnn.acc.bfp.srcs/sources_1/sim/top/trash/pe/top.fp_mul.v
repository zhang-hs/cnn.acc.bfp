// float point multiplication simulation top module
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
    A   = 32'h430260bb;
    B   = 32'hbd7b54be;
    #100
    $display("[%t] : %h mul %h is %h\n", $realtime, A, B, C);
    $finish;
  end

  fp_mul2#(.EXPONENT(EXP),
          .MANTISSA(MAN)
    ) mul2(
    .A(A),
    .B(B),
    .C(C)
  );

  always #10 clk=~clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef NCV // Cadence TRN dump
          $recordsetup("design=board",
                       "compress",
                       "wrapsize=100M",
                       "version=1",
                       "run=1");
          $recordvars();
  
      `elsif VCS //Synopsys VPD dump
          $vcdplusfile("board.vpd");
          $vcdpluson;
          //$vcdplusglitchon;
          //$vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("board.vcd");
          $dumpvars(0, board);
      `endif
    end
  end

endmodule
