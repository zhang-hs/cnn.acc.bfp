// ---------------------------------------------------
// File       : pooling.tb.v
//
// Description: pooling layer test bench
//
// Version    : 1.0
// ---------------------------------------------------
module top;

  reg  clk, rst_n;
  reg  [3:0]  conv_x, conv_y;
  reg  conv_valid;
  reg  next_valid;

  initial begin
    clk         = 1'b0;
    rst_n       = 1'b0;
    conv_valid  = 1'b0;
    next_valid  = 1'b0;
    #45 rst_n   = 1'b1;
  end
  always #10 clk = ~clk;
  // output position
  always@(posedge clk) begin
    if(!rst_n) begin
      conv_x <= 4'b0;
      conv_y <= 4'b0;
    end else begin
      if(rst_n) begin
        conv_valid <= 1'b1;
      end
      // output valid or convolution tail
      if(conv_valid) begin
        // row
        if(conv_y!=4'd13) begin
          conv_y <= conv_y+1'b1;
        end else begin
          conv_y <= 4'h0;
        end
        // col
        if(conv_x!=4'd13) begin
          if(conv_y == 4'd13)
            conv_x <= conv_x + 1'b1;
        end else begin
          if(conv_y == 4'd13) begin
            conv_x <= 4'd0;
            conv_valid <= 1'b0;
          end
        end
      end else begin
        conv_x <= 4'd0;
        conv_y <= 4'd0;
      end
      $display("%t, on (x,y): %6d, %6d", $realtime, conv_x, conv_y);
      if((conv_x == 4'd13) && (conv_y == 4'd13)) begin
        #80 $finish;
      end
    end
  end

  pooling pool(
    .clk(clk),
    .rst_n(rst_n),
    .conv_x(conv_x),
    .conv_y(conv_y),
    .conv_valid(conv_valid),
    .pool_x(),
    .pool_y()
  );


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
