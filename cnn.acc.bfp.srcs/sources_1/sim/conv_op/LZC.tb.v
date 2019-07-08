`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/30 08:32:38
// Module Name: top_LZC
// Description: counting the number of leading zeros.
//              four-stage parallel dichotomy
// 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////


module top_LZC;

//clk,reset
  reg       rst_n;
  reg       clk;
  initial begin
    rst_n = 1'b0;
    #100 rst_n = 1'b1;
  end
  initial begin
    clk = 1'b0;
    forever #10 clk=~clk;
  end

  // dump vpd file
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
          $vcdplusfile("top.vpd");
          $vcdpluson;
          $vcdplusglitchon;
          $vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("top.vcd");
          $dumpvars(0, top);
      `endif
    end
  end
  
  reg  [29-1:0]   _data_in;
  reg             _data_in_valid;
  wire [4:0]      _leading_zero_num;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _data_in <= 29'b0;
      _data_in_valid <= 1'b0;
    end else begin
      if(_data_in > 29'h0fffffff) begin
        _data_in <= 29'b0;
        _data_in_valid <= 1'b0;
      end else if(_data_in > 29'hffffff) begin
        _data_in <= _data_in + 29'hfffff;
      end else if(_data_in > 29'hfffff) begin
        _data_in <= _data_in + 29'hffff;
      end else if(_data_in > 29'hffff) begin
        _data_in <= _data_in + 29'hfff;
      end else if(_data_in > 29'hfff) begin
        _data_in <= _data_in + 29'hff;
      end else if(_data_in > 29'hf) begin
        _data_in <= _data_in + 29'hf;
      end else begin
        _data_in <= _data_in + 1'b1;
        _data_in_valid <= 1'b1;
      end
    end
  end

  LZC LZC_u (
  .data_in(_data_in),
  .data_in_valid(_data_in_valid),
  .leading_zero_num(_leading_zero_num)
  );


endmodule
