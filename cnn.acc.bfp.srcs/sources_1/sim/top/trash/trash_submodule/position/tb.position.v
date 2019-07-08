// submodule position simulation top module
`timescale 1ns/1ps

module top;
  reg       clk;
  reg       rst_n;
  reg       next_pos;
  reg [3:0] row;
  reg [3:0] col;
  reg       end_pos;

  localparam EXP = 8;
  localparam MAN = 23;

  initial begin
    clk   = 1'b1;
    rst_n = 1'b0;
    next_pos  = 1'b0;
    #10
    rst_n     = 1'b1;
    next_pos  = 1'b1;
    $display("[%t] : row: %d col: %d next_pos: %b\n", $realtime, row, col, next_pos);
  end

  position position(
    .clk(clk),
    .cnn_conv_rst_n(rst_n),
    ._next_pos(next_pos),
    ._row(row),
    ._col(col),
    ._end_pos(end_pos)
  );

  always #10 clk=~clk;
  always@(posedge clk) begin
    $display("[%t] : row: %d col: %d next_pos: %b, end pos: %b\n", $realtime, row, col, next_pos, end_pos);
    if((row == 4'd13) && (col == 4'd13)) begin
      next_pos <= 1'b0;
      $finish;
    end else begin
      next_pos <= 1'b1;
    end
  end

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
          $dumpvars(0, position);
      `endif
    end
  end

endmodule
