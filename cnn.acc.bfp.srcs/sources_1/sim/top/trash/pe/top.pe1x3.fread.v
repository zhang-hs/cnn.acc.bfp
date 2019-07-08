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

  // file IO
  integer         fd_data; // data file handle
  integer         fd_ker;  // kernel file handle
  integer         fd_bias; // bias file handle
  integer         fd_result; // file stored in result
  integer         char_count;
  integer         data_count;
  integer         count;

  // open file
  initial begin
    rst_n = 1'b0;
    clk = 1'b0;
    fd_data = $fopen("../data/top.bin","rb");
    fd_ker  = $fopen("../data/weight.bin","rb");
    fd_bias = $fopen("../data/bias.bin","rb");
    fd_result = $fopen("result.bin","wb");
    char_count = 0;
    data_count = 0;
    if((fd_data == `NULL) || (fd_ker == `NULL) ||
        (fd_bias == `NULL) || (fd_result == `NULL)) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // read kernel and bias
    count = $fread(ker1, fd_ker);
    count = $fread(ker2, fd_ker);
    count = $fread(ker3, fd_ker);
    $display("ker1: %h, ker2: %h, ker3: %h\n", ker1, ker2, ker3);
    count = $fread(bias, fd_bias);
    $display("bias: %h\n", bias);
    #50 rst_n = 1'b1;
  end

  always #10 clk=~clk;

  always@(posedge clk) begin
    if(rst_n == 1'b1) begin
      if(!$feof(fd_data)) begin
        // feeding data
        count = $fread(data1, fd_data);
        char_count <= char_count + count;
        count = $fread(data2, fd_data);
        char_count <= char_count + count;
        count = $fread(data3, fd_data);
        char_count <= char_count + count;
        data_count <= data_count + 1;
        if(count == 0) begin
          data1 <= 32'b0;
          data2 <= 32'b0;
          data3 <= 32'b0;
        end
        if(result[0] !== 1'bx) begin
          $fwrite(fd_result, "%c", result[MAN+EXP:MAN+EXP-7]);
          $fwrite(fd_result, "%c", result[MAN+EXP-8:MAN+EXP-15]);
          $fwrite(fd_result, "%c", result[MAN+EXP-16:MAN+EXP-23]);
          $fwrite(fd_result, "%c", result[MAN+EXP-24:MAN+EXP-31]);
        end
      end else begin
        $display("%t: data feeding done\n", $realtime);
        $fwrite(fd_result, "%c", result[MAN+EXP:MAN+EXP-7]);
        $fwrite(fd_result, "%c", result[MAN+EXP-8:MAN+EXP-15]);
        $fwrite(fd_result, "%c", result[MAN+EXP-16:MAN+EXP-23]);
        $fwrite(fd_result, "%c", result[MAN+EXP-24:MAN+EXP-31]);
        if(on_3mul) begin
          $fclose(fd_data);
          $fclose(fd_ker);
          $fclose(fd_bias);
          $fclose(fd_result);
          $finish;
        end
      end
    end
  end

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
