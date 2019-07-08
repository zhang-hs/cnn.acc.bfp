// submodule position simulation top module
`timescale 1ns/1ps

module top;
  reg       clk;
  reg       rst_n;
  reg       output_valid;
  reg [3:0] cnn_conv_x;
  reg [3:0] cnn_conv_y;
  reg       last_output_pos;

  localparam EXP = 8;
  localparam MAN = 23;

  initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    output_valid = 1'b0;
    #10
    clk   = 1'b0;
    rst_n = 1'b1;
    output_valid = 1'b0;
    #10
    rst_n = 1'b1;
    output_valid = 1'b1;
    $display("[%t] : x: %d, y: %d last_output_pos: %b\n", $realtime, cnn_conv_x, cnn_conv_y, last_output_pos);
    forever #10 clk=~clk;
  end

  outputfsm fsm(
    .clk(clk),
    .cnn_conv_rst_n(rst_n),
    ._output_valid(output_valid),
    .cnn_conv_x(cnn_conv_x),
    .cnn_conv_y(cnn_conv_y),
    ._last_output_pos(last_output_pos)
  );

  always@(posedge clk) begin
    $display("[%t] : x: %d, y: %d last_output_pos: %b\n", $realtime, cnn_conv_x, cnn_conv_y, last_output_pos);
    if((cnn_conv_x == 4'd13) && cnn_conv_y == 4'd13) begin
      output_valid <= 1'b0;
    end else begin
      output_valid <= 1'b1;
    end
    if(!output_valid && rst_n)
      $finish;
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
          $display("!!!!!!  NO DUMP FILE (unknown dump format)!!!!!\n");
          // Verilog VC dump
      `endif
    end
  end

endmodule
