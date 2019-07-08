// -----------------------------------------
// conv_op simulation top module
// -----------------------------------------
  
  `timescale 1ns/1ps
  `define NULL 0
  //`define usingDirectC
  //`ifdef usingDirectC
      extern pointer  getFileDescriptor(input string fileName);
      extern void     closeFile(input pointer fileDescriptor);
      extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
      extern int      read16bitFloatNum(input pointer fileDescriptor, output bit[15:0]);
      //extern int      readFloatcvt16bit(input pointer fileDescriptor, output bit[15:0]);
      extern int      read32and16bitNum(input pointer fileDescriptor, output bit[31:0] fpC, output bit[15:0] dataC);
      extern int      read8bitNum(input pointer fileDescriptor, output bit[7:0] MantC);
      //extern int      read5bitNum(input pointer fileDescriptor, output bit[4:0]);
      extern bit      cmp8bitData(input bit cmpEn,input bit[6*8-1:0] MantC, input bit[6*8-1:0] MantV);
      extern bit      cmp32bitData(input bit cmpEn,input bit[6*32-1:0] fpC, input bit[6*32-1:0] fpV);
  
  //`endif
  module top;
//module top_float_to_fixed;
    localparam FPH_WIDTH = 16;
    localparam FP_WIDTH = 32;
    localparam DATA_WIDTH = 8;
    localparam EXP_WIDTH = 5;
    localparam MID_DATA_WIDTH = 26;
  
  //clk,reset
    reg       rst_n;
    reg       clk;
    reg       init_complete;
    initial begin
      rst_n = 1'b0;
      init_complete = 1'b0;
      #50 rst_n = 1'b1;
      #150 init_complete = 1'b1;
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
  
  //read from file
    integer fd_32, fd_16, fd_fixed,fd_exp, count;
    reg [31:0] fp0, fp1, fp2,fp3,fp4,fp5;  
    reg [15:0] data0, data1, data2,data3,data4,data5;
    reg [7:0]  fixed0, fixed1,fixed2,fixed3,fixed4,fixed5;
    reg [7:0]  exp;
    reg next_rd_fp, next_rd_data, next_rd_exp, next_rd_fixed; 
    //reg rd_file_init;
      
    initial begin
    fd_32 = getFileDescriptor("../../../../../data/bfp_trans/float32_fixed_c.txt"); // bottom feature map file
    fd_16 = getFileDescriptor("../../../../../data/bfp_trans/float16_c.txt");    // kernel weight file
    fd_fixed = getFileDescriptor("../../../../../data/bfp_trans/fixed8_c.txt");
    fd_exp  = getFileDescriptor("../../../../../data/bfp_trans/blockexp_c.txt");    // kernel weight file
      if(fd_32==`NULL || fd_16==`NULL || fd_fixed ==`NULL || fd_exp==`NULL) begin
        $display("file handles are NULL, CAN NOT OPEN FILES\n");
        $finish;
      end
      $display("read data 32 bits\n");
      count = readFloatNum(fd_32, fp0);
      count = readFloatNum(fd_32, fp1);
      count = readFloatNum(fd_32, fp2);
      count = readFloatNum(fd_32, fp3);
      count = readFloatNum(fd_32, fp4);
      count = readFloatNum(fd_32, fp5);
      //rd_fp_full = 1'b1;
      $display("read data 16 bits\n");
      count = read16bitFloatNum(fd_16,data0);
      count = read16bitFloatNum(fd_16,data1);
      count = read16bitFloatNum(fd_16,data2);
      count = read16bitFloatNum(fd_16,data3);
      count = read16bitFloatNum(fd_16,data4);
      count = read16bitFloatNum(fd_16,data5);
      //rd_data_full = 1'b1;
      $display("read fixed 8bits\n");
      count = read8bitNum(fd_fixed, fixed0);
      count = read8bitNum(fd_fixed, fixed1);
      count = read8bitNum(fd_fixed, fixed2);
      count = read8bitNum(fd_fixed, fixed3);
      count = read8bitNum(fd_fixed, fixed4);
      count = read8bitNum(fd_fixed, fixed5);
      //rd_fixed_full = 1'b1;
      //exp
      $display("read exp 8bits\n");
      count = read8bitNum(fd_exp, exp);
      //rd_exp_full = 1'b1;
      //rd_file_init = 1'b1;
    end
  
    always@(posedge clk or negedge rst_n) begin
      if(rst_n)begin
        if(next_rd_fp) begin
            $display("read data 32 bits\n");
            count = readFloatNum(fd_32, fp0);
            count = readFloatNum(fd_32, fp1);
            count = readFloatNum(fd_32, fp2);
            count = readFloatNum(fd_32, fp3);
            count = readFloatNum(fd_32, fp4);
            count = readFloatNum(fd_32, fp5);
        end
        if(next_rd_data) begin
            $display("read data 16 bits\n");
            count = read16bitFloatNum(fd_16,data0);
            count = read16bitFloatNum(fd_16,data1);
            count = read16bitFloatNum(fd_16,data2);
            count = read16bitFloatNum(fd_16,data3);
            count = read16bitFloatNum(fd_16,data4);
            count = read16bitFloatNum(fd_16,data5);
        end
        if(next_rd_exp) begin
            $display("read exp 8bits\n");
            count = read8bitNum(fd_exp, exp);
        end
        if(next_rd_fixed) begin
            $display("read fixed 8bits\n");
            count = read8bitNum(fd_fixed, fixed0);
            count = read8bitNum(fd_fixed, fixed1);
            count = read8bitNum(fd_fixed, fixed2);
            count = read8bitNum(fd_fixed, fixed3);
            count = read8bitNum(fd_fixed, fixed4);
            count = read8bitNum(fd_fixed, fixed5);
        end
      end
    end
    
    
    reg [DATA_WIDTH*6-1:0]   fixed_c;
    reg [FPH_WIDTH*6-1:0]    data_c;
    reg [FP_WIDTH*6-1:0]     fp_c;
    reg [EXP_WIDTH*1-1:0]    exp_c;
    
   localparam RD_FP_NUM = 10'd1000; //*6
   localparam RD_DATA_NUM = 10'd1000;
   localparam RD_FIXED_NUM = 10'd1000;
   localparam RD_EXP_NUM  = 1'd1;
   reg [9:0]  rd_fp_addr;
   reg [9:0]  rd_data_addr;
   reg [9:0]  rd_fixed_addr;
   reg        rd_exp_addr;
   
   reg rd_file_end;
   reg [31:0] error_sum;
   reg [31:0] num_trans;
   reg rd_fp_full, rd_data_full, rd_fixed_full, rd_exp_full;
   reg _data_valid;
   
   //FSM
   reg [1:0] _state_now;
   reg [1:0] _state_next;
   localparam FSM_RST = 2'b00;
   localparam FSM_RD_DATA = 2'b01;
   //localparam FSM_RD_END = 2'b10;
   //ff
   always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
          _state_now <= FSM_RST;
      end else begin
          _state_now <= _state_next; 
      end
   end
   //state transtation
   always@(_state_now or init_complete or rd_file_end)begin
      _state_next = FSM_RST;
      case(_state_now)
        FSM_RST:begin
          if(init_complete && !rd_file_end)begin
              _state_next = FSM_RD_DATA;
          end else begin
              _state_next = FSM_RST;
          end
        end
        FSM_RD_DATA: begin
          if(rd_file_end) begin
              _state_next = FSM_RST;
          end else begin
              _state_next = FSM_RD_DATA;
          end
        end
      endcase
   end
   //logic
   always@(rd_fp_addr or rd_data_addr or rd_fixed_addr or rd_exp_addr or
           fp0 or fp1 or fp2 or fp3 or fp4 or fp5 or
           data0 or data1 or data2 or data3 or data4 or data5 or
           fixed0 or fixed1 or fixed2 or fixed3 or fixed4 or fixed5 or
           exp or _state_now or rd_file_end) begin
     next_rd_fp = 1'b0;
     next_rd_data = 1'b0;
     next_rd_fixed = 1'b0;
     next_rd_exp = 1'b0;
     rd_fp_full = 1'b0;
     rd_data_full = 1'b0;
     rd_fixed_full = 1'b0;
     rd_exp_full = 1'b0;
     case(_state_now)
       FSM_RST: begin
          _data_valid = 1'b0;
       end
       FSM_RD_DATA: begin
           fp_c = {fp5,fp4,fp3,fp2,fp1,fp0};
           if(rd_fp_addr == RD_FP_NUM) begin
             next_rd_fp = 1'b0;
             rd_fp_full = 1'b1;
           end else begin
             next_rd_fp = 1'b1;
           end
           
           data_c = {data5,data4,data3,data2,data1,data0};
           if(rd_data_addr == RD_DATA_NUM) begin
             next_rd_data = 1'b0;
             rd_data_full = 1'b1;
           end else begin
             next_rd_data = 1'b1;
           end
           
           fixed_c = {fixed5,fixed4,fixed3,fixed2,fixed1,fixed0};
           if(rd_fixed_addr == RD_FIXED_NUM) begin
             next_rd_fixed = 1'b0;
             rd_fixed_full = 1'b1;
           end else begin
             next_rd_fixed = 1'b1;
           end
           
           exp_c = exp[4:0];
           if(rd_exp_addr == RD_EXP_NUM) begin
             next_rd_exp = 1'b0;
             rd_exp_full = 1'b1;
           end else begin
             next_rd_exp = 1'b1;
           end
           
           if(!rd_file_end) begin
             _data_valid = 1'b1;
           end else begin
             _data_valid = 1'b0;
           end
       end
     endcase
   end

    reg [DATA_WIDTH*6-1:0]   fixed_c_last_clk;
    reg [FPH_WIDTH*6-1:0]    data_c_last_clk;
    reg [FP_WIDTH*6-1:0]     fp_c_last_clk;
    reg [EXP_WIDTH*1-1:0]    exp_c_last_clk;
   always@(posedge clk or negedge rst_n) begin
     if(!rst_n) begin
       rd_fp_addr <= 10'b1;
       rd_data_addr <= 10'b1;
       rd_exp_addr  <= 1'b1;
       rd_fixed_addr <= 10'b1;
       rd_file_end <= 1'b0;
     end else begin
       fp_c_last_clk <= fp_c;
       data_c_last_clk <= data_c;
       fixed_c_last_clk <= fixed_c;
       exp_c_last_clk <= exp_c;
       if(next_rd_fp) begin
         rd_fp_addr <= rd_fp_addr + 1'b1;
       end
       if(next_rd_data) begin
         rd_data_addr <= rd_data_addr + 1'b1;
       end
       if(next_rd_exp) begin
         rd_exp_addr <= rd_exp_addr + 1'b1;
       end
       if(next_rd_fixed) begin
         rd_fixed_addr <= rd_fixed_addr + 1'b1;
       end
       if(rd_fp_full && rd_data_full && rd_fixed_full && rd_exp_full) begin
         rd_file_end <= 1'b1; 
       end else begin
         rd_file_end <= 1'b0;
       end
     end
   end

reg stop_all;
always@(posedge clk) begin
  if(rd_file_end) begin
    stop_all <= 1'b1;
  end else begin
    stop_all <= 1'b0;
  end
  if(stop_all) begin
      closeFile(fd_32);
      closeFile(fd_16);
      closeFile(fd_fixed);
      closeFile(fd_exp);
     $display("error_sum_total:%x",error_sum);
     $display("num_trans:%d\n",num_trans);
     $finish;
  end
end
  
  
  reg [7:0] fixed_v[5:0];
  reg       fixed_v_valid[5:0];
  //wire      trans_start;
  //assign trans_start = rd_file_init || _data_valid;
  wire      trans_finish;
  assign    trans_finish = fixed_v_valid[0] && fixed_v_valid[1] && fixed_v_valid[2] && fixed_v_valid[3] && fixed_v_valid[4] && fixed_v_valid[5]; 
   float_to_fixed float_to_fixed0(
      .clk(clk),
      .rst_n(rst_n),
      .datain(data_c[FPH_WIDTH-1:0]),
      .expin(exp_c),
      .datain_valid(_data_valid),
      .dataout_valid(fixed_v_valid[0]),
      .dataout(fixed_v[0])
    );
     float_to_fixed float_to_fixed1(
       .clk(clk),
       .rst_n(rst_n),
       .datain(data_c[FPH_WIDTH*2-1:FPH_WIDTH]),
       .expin(exp_c),
       .datain_valid(_data_valid),
       .dataout_valid(fixed_v_valid[1]),
       .dataout(fixed_v[1])
     );
      float_to_fixed float_to_fixed2(
        .clk(clk),
        .rst_n(rst_n),
        .datain(data_c[FPH_WIDTH*3-1:FPH_WIDTH*2]),
        .expin(exp_c),
        .datain_valid(_data_valid),
        .dataout_valid(fixed_v_valid[2]),
        .dataout(fixed_v[2])
      );
       float_to_fixed float_to_fixed3(
         .clk(clk),
         .rst_n(rst_n),
         .datain(data_c[FPH_WIDTH*4-1:FPH_WIDTH*3]),
         .expin(exp_c),
         .datain_valid(_data_valid),
         .dataout_valid(fixed_v_valid[3]),
         .dataout(fixed_v[3])
       );
        float_to_fixed float_to_fixed4(
          .clk(clk),
          .rst_n(rst_n),
          .datain(data_c[FPH_WIDTH*5-1:FPH_WIDTH*4]),
          .expin(exp_c),
          .datain_valid(_data_valid),
          .dataout_valid(fixed_v_valid[4]),
          .dataout(fixed_v[4])
        );
         float_to_fixed float_to_fixed5(
           .clk(clk),
           .rst_n(rst_n),
           .datain(data_c[FPH_WIDTH*6-1:FPH_WIDTH*5]),
           .expin(exp_c),
           .datain_valid(_data_valid),
           .dataout_valid(fixed_v_valid[5]),
           .dataout(fixed_v[5])
         );
  
      wire[DATA_WIDTH*6-1:0] fixed_v_tmp;
      assign fixed_v_tmp = {fixed_v[5],fixed_v[4],fixed_v[3],fixed_v[2],fixed_v[1],fixed_v[0]};
       
      always@(posedge clk) begin
          if(!rst_n) begin
              error_sum = 0;
              num_trans = 0;
          end else begin
              if(trans_finish)begin
                  error_sum = error_sum + cmp8bitData(trans_finish, fixed_c_last_clk, fixed_v_tmp);
                  num_trans = num_trans + 1'b1;
              end
           end
       end 
      
    /*  
    reg  [FP_WIDTH-1:0]     app_fp[8:0];
    wire [FP_WIDTH*9-1:0]   app_fp_tmp;
    reg       app_fp_valid[8:0];
    wire      fp_trans_finish;                   
    assign app_fp_tmp = {app_fp[8], app_fp[7], app_fp[6], app_fp[5], 
                         app_fp[4], app_fp[3], app_fp[2], app_fp[1], app_fp[0]}; 
    assign fp_trans_finish = app_fp_valid[8] && app_fp_valid[7] && app_fp_valid[6] && app_fp_valid[5] && 
                             app_fp_valid[4] && app_fp_valid[3] && app_fp_valid[2] && app_fp_valid[1] && app_fp_valid[0];   
    fixed_to_float fixed_to_float0(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[0]}),
      .m_axis_result_tvalid(app_fp_valid[0]),
      .m_axis_result_tdata(app_fp[0])
    );
    fixed_to_float fixed_to_float1(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[1]}),
      .m_axis_result_tvalid(app_fp_valid[1]),
      .m_axis_result_tdata(app_fp[1])
    );
    fixed_to_float fixed_to_float2(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[2]}),
      .m_axis_result_tvalid(app_fp_valid[2]),
      .m_axis_result_tdata(app_fp[2])
    );
    fixed_to_float fixed_to_float3(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[3]}),
      .m_axis_result_tvalid(app_fp_valid[3]),
      .m_axis_result_tdata(app_fp[3])
    );
    fixed_to_float fixed_to_float4(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[4]}),
      .m_axis_result_tvalid(app_fp_valid[4]),
      .m_axis_result_tdata(app_fp[4])
    );
    fixed_to_float fixed_to_float5(
      .aclk(clk),
      .s_axis_a_tvalid(trans_finish),
      .s_axis_a_tready(),
      .s_axis_a_tdata({24'd0,fixed_v[5]}),
      .m_axis_result_tvalid(app_fp_valid[5]),
      .m_axis_result_tdata(app_fp[5])
    );
    
     always@(posedge clk) begin
        if(fp_trans_finish)begin
            count = cmp32bitData(fp_trans_finish, fp, app_fp_tmp);
            $finish;
        end
    end 
  */
  endmodule
