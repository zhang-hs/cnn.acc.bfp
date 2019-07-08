// ---------------------------------------------------
// File       : gen_ker.tb.v
//
// Description: generate ker data used in conv_op.v
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/100fs
`define NULL 0
`define usingDirectC
module top;

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
          $vcdplusglitchon;
          $vcdplusflush;
      `else
          // Verilog VC dump
          $dumpfile("top.vcd");
          $dumpvars(0, gen_data);
      `endif
    end
  end
  // ddr clock and reset
  reg ddr_clk;
  reg sys_rst_n;

  initial begin
    sys_rst_n = 1'b0;
    #20 sys_rst_n = 1'b1;
  end

  initial begin
    ddr_clk = 1'b0;
    forever #10 ddr_clk = ~ddr_clk;
  end

  localparam BIAS_NUM    = 64; // 64, 128, 256, 512
  localparam KER_SET_NUM = 2;  // 2, 4, 8
  localparam KER_SET_SIZE= 32*9;
  localparam FLOAT_NUM_BIT = 32;
  localparam DDR_DATA_WIDTH = 64;
  localparam BIAS_BURST  = BIAS_NUM*FLOAT_NUM_BIT/DDR_DATA_WIDTH/8;
  localparam KER_BURST   = KER_SET_SIZE*KER_SET_NUM*FLOAT_NUM_BIT/DDR_DATA_WIDTH/8;
  // open file
  localparam EXP = 8;
  localparam MAN = 23;
  integer fd_result;
  integer data_count;
  reg [EXP+MAN:0] data01,data02,data03,data04,data05,data06,data07,data08,
                  data09,data10,data11,data12,data13,data14,data15,data16;

  initial begin
    fd_result = $fopen("ker.tb.bin","wb");
    data_count = 0;
    if(fd_result == `NULL) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // data
    data01 = 5'd00; data02 = 5'd01;
    data03 = 5'd02; data04 = 5'd03;
    data05 = 5'd04; data06 = 5'd05;
    data07 = 5'd06; data08 = 5'd07;
    data09 = 5'd08; data10 = 5'd09;
    data11 = 5'd10; data12 = 5'd11;
    data13 = 5'd12; data14 = 5'd13;
    data15 = 5'd14; data16 = 5'd15;
  end
  // generate data file
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(sys_rst_n) begin
      if(data01[15:0]==16'h110) begin // KER_SET_SIZE - 16
        data01 <= {data01[31:16],16'b0} + 32'h10000; data02 <= {data02[31:16],16'b0} + 32'h10001;
        data03 <= {data03[31:16],16'b0} + 32'h10002; data04 <= {data04[31:16],16'b0} + 32'h10003;
        data05 <= {data05[31:16],16'b0} + 32'h10004; data06 <= {data06[31:16],16'b0} + 32'h10005;
        data07 <= {data07[31:16],16'b0} + 32'h10006; data08 <= {data08[31:16],16'b0} + 32'h10007;
        data09 <= {data09[31:16],16'b0} + 32'h10008; data10 <= {data10[31:16],16'b0} + 32'h10009;
        data11 <= {data11[31:16],16'b0} + 32'h1000a; data12 <= {data12[31:16],16'b0} + 32'h1000b;
        data13 <= {data13[31:16],16'b0} + 32'h1000c; data14 <= {data14[31:16],16'b0} + 32'h1000d;
        data15 <= {data15[31:16],16'b0} + 32'h1000e; data16 <= {data16[31:16],16'b0} + 32'h1000f;
      end else begin
        data01 <= data01 + 5'd16; data02 <= data02 + 5'd16;
        data03 <= data03 + 5'd16; data04 <= data04 + 5'd16;
        data05 <= data05 + 5'd16; data06 <= data06 + 5'd16;
        data07 <= data07 + 5'd16; data08 <= data08 + 5'd16;
        data09 <= data09 + 5'd16; data10 <= data10 + 5'd16;
        data11 <= data11 + 5'd16; data12 <= data12 + 5'd16;
        data13 <= data13 + 5'd16; data14 <= data14 + 5'd16;
        data15 <= data15 + 5'd16; data16 <= data16 + 5'd16;
      end
      $display("%t: %h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h_%h\n", $realtime, data01, data02, data03,
                data04, data05, data06, data07, data08, data09, data10, data11,
                data12, data13, data14, data15, data16);
    //if(data04[7:0] == 8'hc3) begin
    //  $fwrite(fd_result, "%c%c%c%c", data01[31:24],data01[23:16],data01[15:8],data01[7:0]);
    //  $fwrite(fd_result, "%c%c%c%c", data02[31:24],data02[23:16],data02[15:8],data02[7:0]);
    //  $fwrite(fd_result, "%c%c%c%c", data03[31:24],data03[23:16],data03[15:8],data03[7:0]);
    //  $fwrite(fd_result, "%c%c%c%c", data04[31:24],data04[23:16],data04[15:8],data04[7:0]);
    //  data_count <= data_count + 5'd4;
    //end else begin
      `ifdef usingDirectC
        $fwrite(fd_result, "%c%c%c%c", data01[7:0],data01[15:8],data01[23:16],data01[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data02[7:0],data02[15:8],data02[23:16],data02[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data03[7:0],data03[15:8],data03[23:16],data03[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data04[7:0],data04[15:8],data04[23:16],data04[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data05[7:0],data05[15:8],data05[23:16],data05[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data06[7:0],data06[15:8],data06[23:16],data06[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data07[7:0],data07[15:8],data07[23:16],data07[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data08[7:0],data08[15:8],data08[23:16],data08[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data09[7:0],data09[15:8],data09[23:16],data09[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data10[7:0],data10[15:8],data10[23:16],data10[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data11[7:0],data11[15:8],data11[23:16],data11[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data12[7:0],data12[15:8],data12[23:16],data12[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data13[7:0],data13[15:8],data13[23:16],data13[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data14[7:0],data14[15:8],data14[23:16],data14[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data15[7:0],data15[15:8],data15[23:16],data15[31:24]);
        $fwrite(fd_result, "%c%c%c%c", data16[7:0],data16[15:8],data16[23:16],data16[31:24]);
      `else
        $fwrite(fd_result, "%c%c%c%c", data01[31:24],data01[23:16],data01[15:8],data01[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data02[31:24],data02[23:16],data02[15:8],data02[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data03[31:24],data03[23:16],data03[15:8],data03[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data04[31:24],data04[23:16],data04[15:8],data04[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data05[31:24],data05[23:16],data05[15:8],data05[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data06[31:24],data06[23:16],data06[15:8],data06[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data07[31:24],data07[23:16],data07[15:8],data07[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data08[31:24],data08[23:16],data08[15:8],data08[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data09[31:24],data09[23:16],data09[15:8],data09[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data10[31:24],data10[23:16],data10[15:8],data10[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data11[31:24],data11[23:16],data11[15:8],data11[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data12[31:24],data12[23:16],data12[15:8],data12[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data13[31:24],data13[23:16],data13[15:8],data13[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data14[31:24],data14[23:16],data14[15:8],data14[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data15[31:24],data15[23:16],data15[15:8],data15[7:0]);
        $fwrite(fd_result, "%c%c%c%c", data16[31:24],data16[23:16],data16[15:8],data16[7:0]);
      `endif
        data_count <= data_count + 5'd1;
    //end
    //data_count <= data_count+5'd1;
      if(data_count == ((KER_SET_NUM*KER_SET_SIZE)/16-1)) begin
        $display("%t: data_count: %d", $realtime, data_count);
        $finish;
      end
    end
  end

endmodule
