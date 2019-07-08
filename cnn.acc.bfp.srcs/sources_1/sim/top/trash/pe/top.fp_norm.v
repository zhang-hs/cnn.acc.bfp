// float point normalization simulation top module

`timescale 1ns/1ps

module top;
  localparam EXP = 8;
  localparam MAN = 12;

  reg clk;

  reg             sum_sign;
  reg [MAN+4:0]   sum_unsigned;
  reg [EXP-1:0]   sum_exp;
  reg [EXP+MAN:0] sum_o;

  localparam a_width    = MAN+1+2; // width of sum after rounding (_sum)
  // addr_width should be less than EXPONENT
  localparam addr_width = log(a_width);
  `include "misc.v"
  `include "DW_lzd_function.inc"
  reg [addr_width-1:0] num_zeros;

  initial begin
    sum_sign     = 1'b0;
    sum_unsigned = {MAN+5{1'b0}};
    sum_exp      = {EXP{1'b0}};

    #10
    sum_sign     = 1'b0;
    sum_unsigned = 17'b10; //28'b111 << 25;
    sum_exp      = 8'd12;

    #100
    $display("[%t] : sum_sign: %b, sum_unsigned: %h sum_exp: %h\n", $realtime, sum_sign, sum_unsigned, sum_exp);
    $display("[%t] : sum_sign: %b, sum_unsigned: %b sum_exp: %b\n", $realtime, sum_sign, sum_unsigned, sum_exp);
    $display("[%t] : sum_o:%h, sum_o exp: %h, sum_o unsigned: %h\n", $realtime, sum_o, sum_o[EXP+MAN-1:MAN], {1'b1,sum_o[MAN-1:0]});
    $display("[%t] : sum_o:%b, sum_o exp: %b, sum_o unsigned: %b\n", $realtime, sum_o, sum_o[EXP+MAN-1:MAN], {1'b1,sum_o[MAN-1:0]});
    $display("[%t] : num_zeros:%b\n", $realtime, num_zeros);
    $finish;
  end

  fp_norm#(
          .EXPONENT(EXP),
          .MANTISSA(MAN)
    ) fpnorm(
          .sum_sign(sum_sign),
          .sum_unsigned(sum_unsigned),
          .sum_exp(sum_exp),
          .num_zeros(num_zeros),
          .sum_o(sum_o)
    );
  //input  wire                         sum_sign,
  //input  wire [MANTISSA+4 : 0]        sum_unsigned,
  //input  wire [EXPONENT-1  : 0]       sum_exp,
  //output reg  [MANTISSA+EXPONENT : 0] sum_o

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
          $vcdplusglitchon;
          $vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("board.vcd");
          $dumpvars(0, board);
      `endif
    end
  end

endmodule
