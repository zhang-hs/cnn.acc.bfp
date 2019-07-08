// submodule position simulation top module
`timescale 1ns/1ps

module top;
  localparam EXP = 8;
  localparam MAN = 23;
  localparam K_W = 3;

  reg       clk;
  reg       rst_n;
  reg       next_pos;
  reg [3:0] row;
  reg [3:0] col;
  reg [(EXP+MAN+1)*K_W-1:0] data0;
  reg [(EXP+MAN+1)*K_W-1:0] data1;

  initial begin
    clk   = 1'b1;
    rst_n = 1'b0;
    next_pos  = 1'b0;
    #10
    rst_n     = 1'b1;
    next_pos  = 1'b1;
    $display("[%t] : row: %d col: %d next_pos: %b\n", $realtime, row, col, next_pos);
    forever #10 clk=~clk;
  end

  always@(posedge clk) begin
    $display("[%t] : row: %d, col: %d, next_pos: %b, data0: %h, data1: %h\n", $realtime, row, col, next_pos, data0, data1);
    if((row == 4'd13) && (col == 4'd13)) begin
      next_pos <= 1'b0;
      $finish;
    end else begin
      next_pos <= 1'b1;
    end
  end

  data_multiplexer mux(
    .clk(clk),
    .cnn_conv_rst_n(rst_n),
    ._next_pos(next_pos),
    ._col(col),
    ._row(row),
    ._data0(data0),
    ._data1(data1)
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
          //$vcdplusglitchon;
          //$vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("board.vcd");
          $dumpvars(0, data_multiplexer);
      `endif
    end
  end

endmodule
