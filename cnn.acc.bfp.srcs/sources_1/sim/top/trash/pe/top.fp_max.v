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
    A   = 32'h00000000;
    B   = 32'hbd7b54be;
    #100
    $display("[%t] : larger one of %h and %h is %h\n", $realtime, A, B, C);
    $finish;
  end

  fp_max#(.EXPONENT(EXP),
          .MANTISSA(MAN)
    ) max(
    .a1(A),
    .a2(B),
    .max_o(C)
  );

  always #10 clk=~clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef NCV // Cadence TRN dump
          $recordsetup("design=top",
                       "compress",
                       "wrapsize=100M",
                       "version=1",
                       "run=1");
          $recordvars();
  
      `elsif VCS //Synopsys VPD dump
          $vcdplusfile("top.vpd");
          $vcdpluson;
          //$vcdplusglitchon;
          //$vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("top.vcd");
          $dumpvars(0, top);
      `endif
    end
  end

endmodule
