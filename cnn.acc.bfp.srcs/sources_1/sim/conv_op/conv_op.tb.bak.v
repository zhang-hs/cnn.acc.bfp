// -----------------------------------------
// conv_op simulation top module
// -----------------------------------------

`define NULL 0
`timescale 1ns/1ps
//`define usingDirectC
//`ifdef usingDirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern void     readProcRam(input pointer fileDescriptor,output bit[8*16*16-1:0] procRam,output bit readFileDone);
  extern void     readProcKer(input pointer fileDescriptor,output bit[8*3*3-1:0] procKer,output bit readFileDone);
  extern void     readTopDirectC(input pointer fileDescriptor,output bit[32*14*14-1:0] procTop,output bit readFileDone);
  extern void     cmpCnnCorr(input bit[4:0] bottomExp, input bit[4:0] kerExp, input bit[3:0] convX, input bit[3:0] convY, 
                             input bit[32*14*14-1:0] topDirectC, input bit[16-1:0] convTopFp, inout bit[31:0] err);
//`endif
module top;
  localparam K_C = 1;
  localparam K_H = 3;
  localparam K_W = 3;
  localparam IM_C = 1;
  localparam CW_H = 16;
  localparam CW_W = 16;
  localparam DATA_WIDTH = 8;
  localparam EXP_WIDTH = 5;
  localparam FP_WIDTH = 16;
  localparam MID_WIDTH = 29;
  localparam EXP_BOTTOM = 22;
  localparam EXP_KER = 14;
  
  // clocks
  reg                                   clk;
  reg                                   rst_n;
  reg                                   init_calib_complete;
  // convolution
  reg                                   conv_start;   
  reg  [DATA_WIDTH*K_C*K_H*K_W-1:0]     conv_ker;     
  reg  [DATA_WIDTH*CW_H*CW_W-1:0]       conv_bottom;  
  
  reg                                   conv_partial_sum_valid; 
  reg  [K_C*MID_WIDTH-1:0]              conv_partial_sum;
  wire [MID_WIDTH*K_C-1:0]              conv_top;
  wire                                  conv_rd_data_partial_sum;
  reg                                   conv_first_pos;
  reg                                   conv_last_pos;
  reg                                   conv_output_valid;
  wire                                  conv_output_last;
  reg  [3:0]                            conv_x;   
  reg  [3:0]                            conv_y;   
  reg  [3:0]                            conv_to_x;
  reg  [3:0]                            conv_to_y;
  reg                                   conv_busy;
  wire                                  conv_done;
  reg  [FP_WIDTH-1:0]                   conv_top_fp;
  //read from file
  //reg rd_data_file, rd_ker_file, rd_exp_file;
  reg           rd_data_full;
  reg           rd_ker_full;
  reg           rd_top_full;
  reg  [32*14*14-1:0] top_directC;

  initial begin
    rst_n           = 1'b0;
    init_calib_complete = 1'b0;
    #50  rst_n            = 1'b1;
    #100 init_calib_complete  = 1'b1;
  end
  initial clk = 1'b0;
  always #10 clk = ~clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef VCS //Synopsys VPD dump
        $vcdplusfile("top.vpd");
        $vcdpluson;
        $vcdplusglitchon;
      `endif
    end
  end
  
  integer fd_data, fd_ker, fd_top_c;
  initial begin
    fd_data = getFileDescriptor("../../../../../data/conv_op/conv_bottom_16x16_block_exp22.txt"); // bottom feature map file
    fd_ker = getFileDescriptor("../../../../../data/conv_op/conv_weight_3x3_block_exp14.txt");    // kernel weight file
    fd_top_c = getFileDescriptor("../../../../../data/conv_op/conv_top_14x14_fp32.txt");
    if(fd_data==`NULL || fd_ker==`NULL || fd_top_c==`NULL) begin
      $display("file handles are NULL, CAN NOT OPEN FILES\n");
      $finish;
    end
    conv_start                = 1'b0;
//    conv_ker                  = {(DATA_WIDTH*K_C*K_H*K_W){1'b0}};
//    conv_bottom               = {(DATA_WIDTH*CW_H*CW_W){1'b0}};
    conv_partial_sum_valid    = 1'b1; 
    conv_partial_sum          = {(K_C*MID_WIDTH){1'b0}};
    rd_data_full              = 1'b0;
    rd_ker_full               = 1'b0;
    rd_top_full               = 1'b0;
  end
  
  always@(posedge clk) begin
    if((!rd_data_full) && rst_n) begin
      readProcRam(fd_data, conv_bottom, rd_data_full);
    end
  end
  always@(posedge clk) begin
    if((!rd_ker_full) && rst_n) begin
      readProcKer(fd_ker, conv_ker, rd_ker_full);
    end
  end
  always@(posedge clk) begin
    if((!rd_top_full) && rst_n) begin
      readTopDirectC(fd_top_c, top_directC, rd_top_full);
    end
  end
  
  // start convolution
  always@(posedge clk) begin
    if(rd_ker_full && rd_data_full && rd_top_full) begin
      conv_start <= 1'b1;
    end else begin
      conv_start <= 1'b0;
    end
  end

//conv_op ctrl
  conv_op#(
    .K_C(K_C),       
    .K_H(K_H),         
    .K_W(K_W),   
    .CW_H(CW_H),   
    .CW_W(CW_W),
    .DATA_WIDTH(DATA_WIDTH),
    .EXP_WIDTH(EXP_WIDTH),
    .MID_WIDTH(MID_WIDTH)
  )conv_op_u(
    .conv_rst_n(rst_n),
    .conv_clk(clk),
    .conv_start(conv_start),
    .conv_ker(conv_ker),
    .conv_bottom(conv_bottom),
    .conv_partial_sum_valid(conv_partial_sum_valid), 
    .conv_partial_sum(conv_partial_sum),
    .conv_top(conv_top),
    .conv_rd_data_partial_sum(conv_rd_data_partial_sum),
    .conv_first_pos(conv_first_pos),
    .conv_last_pos(conv_last_pos), 
    .conv_output_valid(conv_output_valid),
    .conv_output_last(conv_output_last),
    .conv_x(conv_x),
    .conv_y(conv_y),
    .conv_to_x(conv_to_x),
    .conv_to_y(conv_to_y),
    .conv_busy(conv_busy)
  );
  
  fixed_to_float #(
    .FP_WIDTH(FP_WIDTH),
    .MID_WIDTH(MID_WIDTH)
  )fixed_to_float_u(
    .datain(conv_top),
//    .expin(EXP_BOTTOM+EXP_KER),
    .datain_valid(conv_output_valid),
    .dataout(conv_top_fp)
  );
  
  //compare
  reg  [31:0]           err;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      err = 32'd0;
    end else if(conv_output_valid)begin
      cmpCnnCorr(EXP_BOTTOM, EXP_KER, conv_x, conv_y, top_directC, conv_top_fp, err);
    end
  end
  
  // terminate
  assign conv_done = (conv_x == 4'd13) && (conv_y == 4'd13);
  always@(posedge clk) begin
    if(conv_done) begin
      closeFile(fd_data);
      closeFile(fd_ker);
      $finish;
    end
  end

  
endmodule
