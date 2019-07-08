// processing element simulation top module

`timescale 1ns/1ps
`define NULL 0

module top;
  localparam EXP = 8;
  localparam MAN = 23;

  reg clk;

  reg [EXP+MAN:0] ker1;
  reg [EXP+MAN:0] ker2;
  reg [EXP+MAN:0] ker3;
  reg [EXP+MAN:0] data1;
  reg [EXP+MAN:0] data2;
  reg [EXP+MAN:0] data3;
  reg [EXP+MAN:0] bias;
  reg [EXP+MAN:0] result;
  reg             rst_n; // start processing
  reg             done;
  wire            on_3mul;
  wire            on_align3;
  wire            on_sum3;
  wire            on_bias;

  initial begin
    clk = 1'b1;
    data1 = 32'h0;
    data2 = 32'h0;
    data3 = 32'h0;
    ker1  = 32'h0;
    ker2  = 32'h0;
    ker3  = 32'h0;
    bias  = 32'h0;

    #10
    data1 = 32'hc42d7f86;  //32'h42f9a7ad;
    data2 = 32'hc42670c5;  //32'h42fb7b8d;
    data3 = 32'hc399b024;  //32'h430260bb;
    ker1  = 32'h3edbe391;
    ker2  = 32'h3ebf3711;
    ker3  = 32'hbd7b54be;
    bias  = 32'h3f3bfafa;
    //bias  = 32'h42ba9bc8;
    #100
    $display("[%t] : data1: %h, data2: %h data3: %h\n", $realtime, data1, data2, data3);
    $display("[%t] : ker1:%h, ker2:%h, ker3:%h\n", $realtime, ker1, ker2, ker3);
    $display("[%t] : bias:%h\n", $realtime, bias);
    $display("[%t] : result:%h\n", $realtime, result);
    $finish;
  end

  always #10 clk=~clk;

  pe_array1x3#(
          .EXPONENT(EXP),
          .MANTISSA(MAN)
    ) pe(
    .pe_ker3_i({ker1,ker2,ker3}),
    .pe_bias_i(bias),
    .pe_data3_i({data1,data2,data3}),
    .clk(clk),
    .pe_on_3mul_pe_en(1'b1),//on_3mul),
    .pe_on_align3(1'b1),//on_align3),
    .pe_on_sum3(1'b1),//on_sum3),
    .pe_on_bias(1'b1),//on_bias),
    .pe_data_o(result)
  );

  proc_control ctrl(
    .clk(clk),
    .rst_n(rst_n),
    .on_3mul(on_3mul),
    .on_align3(on_align3),
    .on_sum3(on_sum3),
    .on_bias(on_bias)
  );

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

module proc_control(
    input  wire   clk,
    input  wire   rst_n,
    output reg    on_3mul,
    output reg    on_align3,
    output reg    on_sum3,
    output reg    on_bias
  );

  localparam ON_MUL   = 3'h1;
  localparam ON_ALIGN = 3'h2;
  localparam ON_SUM   = 3'h3;
  localparam ON_BIAS  = 3'h4;

  reg  [2:0] _state;
  reg  [2:0] _next_state;
  always@(posedge clk) begin
    _state <= _next_state;
  end

  always@(_state or rst_n) begin
    if(rst_n) begin
      _next_state = ON_MUL;
      case(_state)
        ON_MUL:   _next_state = ON_ALIGN;
        ON_ALIGN: _next_state = ON_SUM;
        ON_SUM:   _next_state = ON_BIAS;
        ON_BIAS:  _next_state = ON_MUL;
      endcase
    end else begin
      _next_state = ON_MUL;
    end
  end

  always@(_state or rst_n) begin
    on_3mul   = 1'b0;
    on_align3 = 1'b0;
    on_sum3   = 1'b0;
    on_bias   = 1'b0;
    if(rst_n) begin
      case(_state)
        ON_MUL:   on_3mul = 1'b1;
        ON_ALIGN: on_align3 = 1'b1;
        ON_SUM:   on_sum3 = 1'b1;
        ON_BIAS:  on_bias = 1'b1;
      endcase
    end
  end

endmodule
