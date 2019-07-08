// -----------------------------------------
// conv_op simulation top module
// -----------------------------------------

`define NULL 0
`timescale 1ns/1ps
//`define usingDirectC
//`ifdef usingDirectC
    extern pointer  getFileDescriptor(input string fileName);
    extern void     closeFile(input pointer fileDescriptor);
    extern void     readProcRam(input pointer fileDesc, input bit readBottom, input bit[8:0] xPos,
                                input bit[8:0] yPos, input bit[8:0] xEndPos, input bit[8:0] yEndPos,
                                input bit[29:0] barOffset, input bit[29:0] ithFM,
                                output bit[16*16*32-1 : 0] procRam, output bit procRamFull);
    extern void     readProcKer(input pointer fileDesc, input bit readKer, input bit[29:0] readKerAddr,
                                input bit[9:0] ithKerSet, output bit[32*3*3*32-1:0] kerRam, output bit kerRamFull);
    extern void     readControl(input bit resetDone, input bit convLastPos, output bit readBottomData,
                                inout bit[29:0] bottomDataAddr, input bit[8:0] xEndPos, input bit[8:0] yEndPos,
                                inout bit[8:0] xPos, inout bit[8:0] yPos, output bit isFirstFM,
                                inout bit[29:0] ithOffset, inout bit[29:0] barOffset, inout bit[9:0] ithFM,
                                output bit readEnd, output bit readKer, inout bit[29:0] readKerAddr,
                                inout bit[9:0] ithKerSet);
    extern void     cnnConv(input bit startConv, output bit[14*14*32*32-1:0] convOutput,
                            input bit[16*16*32-1:0] bottomData, input bit[32*3*3*32-1:0] kerData);
//`endif
module top;

  localparam EXP      = 8;
  localparam MAN      = 23;
  localparam K_C      = 32; // kernel channels
  localparam K_H      = 3;  // kernel height
  localparam K_W      = 3;  // kernel width
  localparam DATA_H   = 16; // feature map data height
  localparam DATA_W   = 16; // feature map data width
  localparam ENDOFX   = 16-1; // fmWidth/atomicWidth - 1
  localparam ENDOFY   = 16-1; // fmHeight/atomicHeight - 1

  // convolution
  reg  [(EXP+MAN+1)*DATA_H*DATA_W-1:0]  conv_bottom;  // bottom patch data
  reg  [(EXP+MAN+1)*K_C*K_H*K_W-1:0]    conv_ker;     // ker set data
  reg  [(EXP+MAN+1)*K_C-1:0]            conv_top;     // top output data
  reg                                   conv_data_full; // data ready
  reg                                   conv_start;   // conv start signal
  reg                                   rst_n;
  reg                                   clk;
  wire                                  conv_output_valid;
  wire                                  conv_output_last;
//wire                                  conv_at_last_pos;
  reg                                   conv_at_last_pos;
  wire [3:0]                            conv_x;
  wire [3:0]                            conv_y;
  // read control
  reg           rd_data_bottom;
  reg  [29:0]   rd_data_bottom_addr;
  reg  [8:0]    rd_data_x;
  reg  [8:0]    rd_data_y;
  reg           rd_data_first_fm;
  reg  [29:0]   rd_data_bottom_ith_offset;
  reg  [29:0]   rd_data_bar_offset;
  reg  [9:0]    rd_data_ithFM;
  reg           rd_data_end;
//reg  []       rd_data_data;   -> conv_bottom;
  reg           rd_data_full;
  reg           rd_ker;
  reg  [9:0]    rd_ker_ith;
  reg  [29:0]   rd_ker_addr;
//reg  []       rd_ker_data;  -> conv_ker;
  reg           rd_ker_full;

  // reset
  initial begin
    rst_n = 1'b0;
    #100 rst_n = 1'b1;
  end
  // clock
  initial begin
    clk = 1'b0;
    forever #10 clk=~clk;
  end

//// rst_n rising edge
//reg   rst_n_reg;
//wire  rst_n_rising_edge;
//assign rst_n_rising_edge = (rst_n && (!rst_n_reg));
//initial begin
//  rst_n_reg = 1'b0;
//end
//always@(posedge clk) begin
//  if(rst_n) begin
//    rst_n_reg <= 1'b1;
//  end else begin
//    rst_n_reg <= 1'b0;
//  end
//end

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

  integer fd_data, fd_ker, fd_result;
  // file descriptor
  initial begin
    fd_data = getFileDescriptor("../../data/c.gen.bottom.tb.bin"); // bottom feature map file
    fd_ker  = getFileDescriptor("../../data/ker.tb.bin");    // kernel weight file
    if(fd_data==`NULL || fd_ker==`NULL) begin
      $display("file handles are NULL, CAN NOT OPEN FILES\n");
      $finish;
    end
    // initialize control information
    rd_data_bottom      = 1'b0;
    rd_data_bottom_addr = 30'h0;
    rd_data_x           = 9'h0;
    rd_data_y           = 9'h0;
    rd_data_first_fm    = 1'b0;
    rd_data_bottom_ith_offset = 30'h0;
    rd_data_bar_offset  = 30'h0;
    rd_data_ithFM       = 10'h0;
    rd_data_end         = 1'b0;
    rd_data_full        = 1'b0;
    rd_ker              = 1'b0;
    rd_ker_ith          = 10'h0;
    rd_ker_addr         = 30'h0;
    rd_ker_full         = 1'b0;
    conv_start          = 1'b0;
    conv_at_last_pos    = 1'b0;
  //#130 conv_at_last_pos = 1'b1;
  end

  reg resetDone;
  initial begin
    resetDone = 1'b0;
    #100 resetDone = 1'b1;
    #30  resetDone = 1'b0;
  end


//// read data from file
//always@(posedge clk or negedge rst_n) begin
//  if(!rst_n) begin
//  end else begin
//  end
//end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      conv_at_last_pos <= 1'b0;
    end else begin
      if(resetDone) begin
        conv_at_last_pos <= 1'b1;
      end
    end
  end

  // reading control
  always@(posedge clk or negedge rst_n) begin
    if(resetDone || conv_at_last_pos) begin
      readControl(resetDone, conv_at_last_pos, rd_data_bottom, rd_data_bottom_addr,
                  ENDOFX, ENDOFY, rd_data_x, rd_data_y, rd_data_first_fm, rd_data_bottom_ith_offset,
                  rd_data_bar_offset, rd_data_ithFM, rd_data_end, rd_ker, rd_ker_addr, rd_ker_ith);
    end
  end

  // read processing ram data
  reg  [DATA_H*DATA_W*(EXP+MAN+1)-1:0] rd_data_ram;
  always@(posedge clk) begin
    if(rd_data_bottom) begin
      readProcRam(fd_data, rd_data_bottom, rd_data_x, rd_data_y, ENDOFX, ENDOFY,
                  rd_data_bar_offset, rd_data_ithFM, rd_data_ram, rd_data_full);
    end else begin
      rd_data_full <= 1'b0;
    end
  end

  // read kernels
  reg  [K_C*K_H*K_W*(EXP+MAN+1)-1:0] rd_ker_ram;
  always@(posedge clk) begin
    if(rd_ker) begin
      readProcKer(fd_ker, rd_ker, rd_ker_addr, rd_ker_ith, rd_ker_ram, rd_ker_full);
    end else begin
      rd_ker_full <= 1'b0;
    end
  end

  // start convolution
  always@(posedge clk) begin
    if(rd_ker_full && rd_data_full) begin
      conv_start <= 1'b1;
    end else begin
      conv_start <= 1'b0;
    end
  end

  reg  [14*14*32*32-1:0] top_data;
  always@(posedge clk) begin
    if(conv_start) begin
      cnnConv(conv_start, top_data, rd_data_ram, rd_ker_ram);
    end
  end

  // terminate
  always@(posedge clk) begin
    if(rd_data_end) begin
      closeFile(fd_data);
      closeFile(fd_ker);
      $finish;
    end
  end

//conv_op#(
//    .EXPONENT(EXP),
//    .MANTISSA(MAN),
//    .K_C(32),
//    .K_H(3),
//    .K_W(3),
//    .DATA_H(16),
//    .DATA_W(16)
//  ) cnn_conv(
//    .conv_rst_n(rst_n),
//    .conv_clk(clk),
//    .conv_start(conv_start),
//    .conv_next_ker_valid_at_next_clk(1'b0),
//    .conv_ker(conv_ker),    // shape: k_c k_h k_w
//    .conv_bottom(conv_bottom), // shape: data_h data_w
//    .conv_top(conv_top),    // shape: k_c, no output buffer reg
//    .conv_x(conv_x),      // ceil(log(14))
//    .conv_y(conv_y),      // ceil(log(14))
//    .conv_output_valid(conv_output_valid),
//    .conv_output_last(),
//    .conv_busy()
//  );

endmodule
