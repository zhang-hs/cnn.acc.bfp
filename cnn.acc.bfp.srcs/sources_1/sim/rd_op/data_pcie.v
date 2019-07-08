// ---------------------------------------------------
// File       : data_pcie.v
//
// Description: stimulate PCIe data transfer
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/1ps
`define NULL 0
`define sim_ // simulation using directC
`ifdef sim_ // {{{
  // DirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
  extern int      read16bitFloatNum(input pointer fileDescriptor, output bit[15:0]);
  extern int      readFloatcvt16bit(input pointer fileDescriptor, output bit[15:0]);
  extern int      read8bitNum(input pointer fileDescriptor, output bit[7:0]);
`endif // }}}

module data_pcie(
    input  wire           clk,
    input  wire           rst_n,
    // MIG
    input  wire           init_calib_complete,
    // ddr
    input  wire [511:0]   ddr_rd_data,
    input  wire           ddr_rd_data_end,
    input  wire           ddr_rd_data_valid,
    input  wire           ddr_rdy,
    input  wire           ddr_wdf_rdy,

    output reg  [29:0]    app_addr,
    output reg  [2:0]     app_cmd,
    output reg            app_en,
    output reg  [511:0]   app_wdf_data,
    output reg  [63:0]    app_wdf_mask,
    output reg            app_wdf_end,
    output reg            app_wdf_wren,
    output reg            tb_load_done
  );

  // open file
  localparam EXP = 8;
  localparam MAN = 23;
  integer fd_data, fd_param, fd_exp;
  integer char_count, data_count, count, countParam, exp_count;
  //bottom
  reg [15:0] data01,data02,data03,data04,data05,data06,data07,data08,
             data09,data10,data11,data12,data13,data14,data15,data16,
             data17,data18,data19,data20,data21,data22,data23,data24,
             data25,data26,data27,data28,data29,data30,data31,data32;
 //param:8bits, bias:16bits
  reg [7:0] param01,param02,param03,param04,param05,param06,param07,param08,
            param09,param10,param11,param12,param13,param14,param15,param16,
            param17,param18,param19,param20,param21,param22,param23,param24,
            param25,param26,param27,param28,param29,param30,param31,param32,
            param33,param34,param35,param36,param37,param38,param39,param40,
            param41,param42,param43,param44,param45,param46,param47,param48,
            param49,param50,param51,param52,param53,param54,param55,param56,
            param57,param58,param59,param60,param61,param62,param63,param64;
 //exp of param and data:5bits
  reg [7:0] exp01,exp02,exp03,exp04,exp05,exp06,exp07,exp08,
             exp09,exp10,exp11,exp12,exp13,exp14,exp15,exp16,
             exp17,exp18,exp19,exp20,exp21,exp22,exp23,exp24,
             exp25,exp26,exp27,exp28,exp29,exp30,exp31,exp32,
             exp33,exp34,exp35,exp36,exp37,exp38,exp39,exp40,
             exp41,exp42,exp43,exp44,exp45,exp46,exp47,exp48,
             exp49,exp50,exp51,exp52,exp53,exp54,exp55,exp56,
             exp57,exp58,exp59,exp60,exp61,exp62,exp63,exp64,
             exp65;
  reg        _next_wr_img, _next_wr_patch, _next_wr_param, _next_wr_exp;

  initial begin
    $display("location:data_pcie.v\n");
    fd_data = getFileDescriptor("../../../../../data/caffe_bfp/conv1_1/conv1_1.bottom.txt");
    fd_param= getFileDescriptor("../../../../../data/caffe_bfp/conv1_1/conv1_1.weight.txt");
    fd_exp  = getFileDescriptor("../../../../../data/caffe_bfp/conv1_1/conv1_1.blockexp.txt");
    char_count = 0;
    data_count = 0;
    exp_count  = 0;
    if((fd_data == `NULL) || (fd_param == `NULL) || (fd_exp == `NULL)) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // bottomdata
    $display("read data\n");
    count = read16bitFloatNum(fd_data, data01); 
    count = read16bitFloatNum(fd_data, data02); 
    count = read16bitFloatNum(fd_data, data03); 
    count = read16bitFloatNum(fd_data, data04); 
    count = read16bitFloatNum(fd_data, data05); 
    count = read16bitFloatNum(fd_data, data06); 
    count = read16bitFloatNum(fd_data, data07); 
    count = read16bitFloatNum(fd_data, data08); 
    count = read16bitFloatNum(fd_data, data09); 
    count = read16bitFloatNum(fd_data, data10); 
    count = read16bitFloatNum(fd_data, data11); 
    count = read16bitFloatNum(fd_data, data12); 
    count = read16bitFloatNum(fd_data, data13); 
    count = read16bitFloatNum(fd_data, data14); 
    count = read16bitFloatNum(fd_data, data15); 
    count = read16bitFloatNum(fd_data, data16); 
    count = read16bitFloatNum(fd_data, data17); 
    count = read16bitFloatNum(fd_data, data18); 
    count = read16bitFloatNum(fd_data, data19); 
    count = read16bitFloatNum(fd_data, data20); 
    count = read16bitFloatNum(fd_data, data21); 
    count = read16bitFloatNum(fd_data, data22); 
    count = read16bitFloatNum(fd_data, data23); 
    count = read16bitFloatNum(fd_data, data24); 
    count = read16bitFloatNum(fd_data, data25); 
    count = read16bitFloatNum(fd_data, data26); 
    count = read16bitFloatNum(fd_data, data27); 
    count = read16bitFloatNum(fd_data, data28); 
    count = read16bitFloatNum(fd_data, data29); 
    count = read16bitFloatNum(fd_data, data30); 
    count = read16bitFloatNum(fd_data, data31); 
    count = read16bitFloatNum(fd_data, data32); 
    $display("read parameter\n");
    countParam = read8bitNum(fd_param, param01);
    countParam = read8bitNum(fd_param, param02);
    countParam = read8bitNum(fd_param, param03);
    countParam = read8bitNum(fd_param, param04);
    countParam = read8bitNum(fd_param, param05);
    countParam = read8bitNum(fd_param, param06);
    countParam = read8bitNum(fd_param, param07);
    countParam = read8bitNum(fd_param, param08);
    countParam = read8bitNum(fd_param, param09);
    countParam = read8bitNum(fd_param, param10);
    countParam = read8bitNum(fd_param, param11);
    countParam = read8bitNum(fd_param, param12);
    countParam = read8bitNum(fd_param, param13);
    countParam = read8bitNum(fd_param, param14);
    countParam = read8bitNum(fd_param, param15);
    countParam = read8bitNum(fd_param, param16);
    countParam = read8bitNum(fd_param, param17);
    countParam = read8bitNum(fd_param, param18);
    countParam = read8bitNum(fd_param, param19);
    countParam = read8bitNum(fd_param, param20);
    countParam = read8bitNum(fd_param, param21);
    countParam = read8bitNum(fd_param, param22);
    countParam = read8bitNum(fd_param, param23);
    countParam = read8bitNum(fd_param, param24);
    countParam = read8bitNum(fd_param, param25);
    countParam = read8bitNum(fd_param, param26);
    countParam = read8bitNum(fd_param, param27);
    countParam = read8bitNum(fd_param, param28);
    countParam = read8bitNum(fd_param, param29);
    countParam = read8bitNum(fd_param, param30);
    countParam = read8bitNum(fd_param, param31);
    countParam = read8bitNum(fd_param, param32);
    countParam = read8bitNum(fd_param, param33);
    countParam = read8bitNum(fd_param, param34);
    countParam = read8bitNum(fd_param, param35);
    countParam = read8bitNum(fd_param, param36);
    countParam = read8bitNum(fd_param, param37);
    countParam = read8bitNum(fd_param, param38);
    countParam = read8bitNum(fd_param, param39);
    countParam = read8bitNum(fd_param, param40);
    countParam = read8bitNum(fd_param, param41);
    countParam = read8bitNum(fd_param, param42);
    countParam = read8bitNum(fd_param, param43);
    countParam = read8bitNum(fd_param, param44);
    countParam = read8bitNum(fd_param, param45);
    countParam = read8bitNum(fd_param, param46);
    countParam = read8bitNum(fd_param, param47);
    countParam = read8bitNum(fd_param, param48);
    countParam = read8bitNum(fd_param, param49);
    countParam = read8bitNum(fd_param, param50);
    countParam = read8bitNum(fd_param, param51);
    countParam = read8bitNum(fd_param, param52);
    countParam = read8bitNum(fd_param, param53);
    countParam = read8bitNum(fd_param, param54);
    countParam = read8bitNum(fd_param, param55);
    countParam = read8bitNum(fd_param, param56);
    countParam = read8bitNum(fd_param, param57);
    countParam = read8bitNum(fd_param, param58);
    countParam = read8bitNum(fd_param, param59);
    countParam = read8bitNum(fd_param, param60);
    countParam = read8bitNum(fd_param, param61);
    countParam = read8bitNum(fd_param, param62);
    countParam = read8bitNum(fd_param, param63);
    countParam = read8bitNum(fd_param, param64);
    $display("read exponent\n");
    exp_count  = read8bitNum(fd_exp, exp01);
    exp_count  = read8bitNum(fd_exp, exp02);
    exp_count  = read8bitNum(fd_exp, exp03);
    exp_count  = read8bitNum(fd_exp, exp04);
    exp_count  = read8bitNum(fd_exp, exp05);
    exp_count  = read8bitNum(fd_exp, exp06);
    exp_count  = read8bitNum(fd_exp, exp07);
    exp_count  = read8bitNum(fd_exp, exp08);
    exp_count  = read8bitNum(fd_exp, exp09);                                                                                              
    exp_count  = read8bitNum(fd_exp, exp10);
    exp_count  = read8bitNum(fd_exp, exp11);                                                
    exp_count  = read8bitNum(fd_exp, exp12);
    exp_count  = read8bitNum(fd_exp, exp13);
    exp_count  = read8bitNum(fd_exp, exp14);
    exp_count  = read8bitNum(fd_exp, exp15);
    exp_count  = read8bitNum(fd_exp, exp16);
    exp_count  = read8bitNum(fd_exp, exp17);
    exp_count  = read8bitNum(fd_exp, exp18);
    exp_count  = read8bitNum(fd_exp, exp19);
    exp_count  = read8bitNum(fd_exp, exp20);
    exp_count  = read8bitNum(fd_exp, exp21);
    exp_count  = read8bitNum(fd_exp, exp22);
    exp_count  = read8bitNum(fd_exp, exp23);
    exp_count  = read8bitNum(fd_exp, exp24);
    exp_count  = read8bitNum(fd_exp, exp25);
    exp_count  = read8bitNum(fd_exp, exp26);
    exp_count  = read8bitNum(fd_exp, exp27);
    exp_count  = read8bitNum(fd_exp, exp28);
    exp_count  = read8bitNum(fd_exp, exp29);
    exp_count  = read8bitNum(fd_exp, exp30);
    exp_count  = read8bitNum(fd_exp, exp31);
    exp_count  = read8bitNum(fd_exp, exp32);
    exp_count  = read8bitNum(fd_exp, exp33);
    exp_count  = read8bitNum(fd_exp, exp34);
    exp_count  = read8bitNum(fd_exp, exp35);
    exp_count  = read8bitNum(fd_exp, exp36);
    exp_count  = read8bitNum(fd_exp, exp37);
    exp_count  = read8bitNum(fd_exp, exp38);
    exp_count  = read8bitNum(fd_exp, exp39);
    exp_count  = read8bitNum(fd_exp, exp40);
    exp_count  = read8bitNum(fd_exp, exp41);                                                                                              
    exp_count  = read8bitNum(fd_exp, exp42);
    exp_count  = read8bitNum(fd_exp, exp43);                                                
    exp_count  = read8bitNum(fd_exp, exp44);
    exp_count  = read8bitNum(fd_exp, exp45);
    exp_count  = read8bitNum(fd_exp, exp46);
    exp_count  = read8bitNum(fd_exp, exp47);
    exp_count  = read8bitNum(fd_exp, exp48);
    exp_count  = read8bitNum(fd_exp, exp49);
    exp_count  = read8bitNum(fd_exp, exp50);
    exp_count  = read8bitNum(fd_exp, exp51);
    exp_count  = read8bitNum(fd_exp, exp52);
    exp_count  = read8bitNum(fd_exp, exp53);
    exp_count  = read8bitNum(fd_exp, exp54);
    exp_count  = read8bitNum(fd_exp, exp55);
    exp_count  = read8bitNum(fd_exp, exp56);
    exp_count  = read8bitNum(fd_exp, exp57);
    exp_count  = read8bitNum(fd_exp, exp58);
    exp_count  = read8bitNum(fd_exp, exp59);
    exp_count  = read8bitNum(fd_exp, exp60);
    exp_count  = read8bitNum(fd_exp, exp61);
    exp_count  = read8bitNum(fd_exp, exp62);
    exp_count  = read8bitNum(fd_exp, exp63);
    exp_count  = read8bitNum(fd_exp, exp64);
    exp_count  = read8bitNum(fd_exp, exp65);
  end

  // read from file
  always@(posedge clk or negedge rst_n) begin
    if((rst_n) && init_calib_complete) begin
      if(_next_wr_patch) begin
        // patch data
        count = read16bitFloatNum(fd_data, data01); 
        count = read16bitFloatNum(fd_data, data02); 
        count = read16bitFloatNum(fd_data, data03); 
        count = read16bitFloatNum(fd_data, data04); 
        count = read16bitFloatNum(fd_data, data05); 
        count = read16bitFloatNum(fd_data, data06); 
        count = read16bitFloatNum(fd_data, data07); 
        count = read16bitFloatNum(fd_data, data08); 
        count = read16bitFloatNum(fd_data, data09); 
        count = read16bitFloatNum(fd_data, data10); 
        count = read16bitFloatNum(fd_data, data11); 
        count = read16bitFloatNum(fd_data, data12); 
        count = read16bitFloatNum(fd_data, data13); 
        count = read16bitFloatNum(fd_data, data14); 
        count = read16bitFloatNum(fd_data, data15); 
        count = read16bitFloatNum(fd_data, data16); 
        count = read16bitFloatNum(fd_data, data17); 
        count = read16bitFloatNum(fd_data, data18); 
        count = read16bitFloatNum(fd_data, data19); 
        count = read16bitFloatNum(fd_data, data20); 
        count = read16bitFloatNum(fd_data, data21); 
        count = read16bitFloatNum(fd_data, data22); 
        count = read16bitFloatNum(fd_data, data23); 
        count = read16bitFloatNum(fd_data, data24); 
        count = read16bitFloatNum(fd_data, data25); 
        count = read16bitFloatNum(fd_data, data26); 
        count = read16bitFloatNum(fd_data, data27); 
        count = read16bitFloatNum(fd_data, data28); 
        count = read16bitFloatNum(fd_data, data29); 
        count = read16bitFloatNum(fd_data, data30); 
        count = read16bitFloatNum(fd_data, data31); 
        count = read16bitFloatNum(fd_data, data32); 
      end

      if(_next_wr_param) begin
        // param data
        countParam = read8bitNum(fd_param, param01);
        countParam = read8bitNum(fd_param, param02);
        countParam = read8bitNum(fd_param, param03);
        countParam = read8bitNum(fd_param, param04);
        countParam = read8bitNum(fd_param, param05);
        countParam = read8bitNum(fd_param, param06);
        countParam = read8bitNum(fd_param, param07);
        countParam = read8bitNum(fd_param, param08);
        countParam = read8bitNum(fd_param, param09);
        countParam = read8bitNum(fd_param, param10);
        countParam = read8bitNum(fd_param, param11);
        countParam = read8bitNum(fd_param, param12);
        countParam = read8bitNum(fd_param, param13);
        countParam = read8bitNum(fd_param, param14);
        countParam = read8bitNum(fd_param, param15);
        countParam = read8bitNum(fd_param, param16);
        countParam = read8bitNum(fd_param, param17);
        countParam = read8bitNum(fd_param, param18);
        countParam = read8bitNum(fd_param, param19);
        countParam = read8bitNum(fd_param, param20);
        countParam = read8bitNum(fd_param, param21);
        countParam = read8bitNum(fd_param, param22);
        countParam = read8bitNum(fd_param, param23);
        countParam = read8bitNum(fd_param, param24);
        countParam = read8bitNum(fd_param, param25);
        countParam = read8bitNum(fd_param, param26);
        countParam = read8bitNum(fd_param, param27);
        countParam = read8bitNum(fd_param, param28);
        countParam = read8bitNum(fd_param, param29);
        countParam = read8bitNum(fd_param, param30);
        countParam = read8bitNum(fd_param, param31);
        countParam = read8bitNum(fd_param, param32);
        countParam = read8bitNum(fd_param, param33);
        countParam = read8bitNum(fd_param, param34);
        countParam = read8bitNum(fd_param, param35);
        countParam = read8bitNum(fd_param, param36);
        countParam = read8bitNum(fd_param, param37);
        countParam = read8bitNum(fd_param, param38);
        countParam = read8bitNum(fd_param, param39);
        countParam = read8bitNum(fd_param, param40);
        countParam = read8bitNum(fd_param, param41);
        countParam = read8bitNum(fd_param, param42);
        countParam = read8bitNum(fd_param, param43);
        countParam = read8bitNum(fd_param, param44);
        countParam = read8bitNum(fd_param, param45);
        countParam = read8bitNum(fd_param, param46);
        countParam = read8bitNum(fd_param, param47);
        countParam = read8bitNum(fd_param, param48);
        countParam = read8bitNum(fd_param, param49);
        countParam = read8bitNum(fd_param, param50);
        countParam = read8bitNum(fd_param, param51);
        countParam = read8bitNum(fd_param, param52);
        countParam = read8bitNum(fd_param, param53);
        countParam = read8bitNum(fd_param, param54);
        countParam = read8bitNum(fd_param, param55);
        countParam = read8bitNum(fd_param, param56);
        countParam = read8bitNum(fd_param, param57);
        countParam = read8bitNum(fd_param, param58);
        countParam = read8bitNum(fd_param, param59);
        countParam = read8bitNum(fd_param, param60);
        countParam = read8bitNum(fd_param, param61);
        countParam = read8bitNum(fd_param, param62);
        countParam = read8bitNum(fd_param, param63);
        countParam = read8bitNum(fd_param, param64);
      end
      
     if(_next_wr_exp) begin
     //exponent,useless in conv1_1
       exp_count  = read8bitNum(fd_exp, exp01);
       exp_count  = read8bitNum(fd_exp, exp02);
       exp_count  = read8bitNum(fd_exp, exp03);
       exp_count  = read8bitNum(fd_exp, exp04);
       exp_count  = read8bitNum(fd_exp, exp05);
       exp_count  = read8bitNum(fd_exp, exp06);
       exp_count  = read8bitNum(fd_exp, exp07);
       exp_count  = read8bitNum(fd_exp, exp08);
       exp_count  = read8bitNum(fd_exp, exp09);                                                                                              
       exp_count  = read8bitNum(fd_exp, exp10);
       exp_count  = read8bitNum(fd_exp, exp11);                                                
       exp_count  = read8bitNum(fd_exp, exp12);
       exp_count  = read8bitNum(fd_exp, exp13);
       exp_count  = read8bitNum(fd_exp, exp14);
       exp_count  = read8bitNum(fd_exp, exp15);
       exp_count  = read8bitNum(fd_exp, exp16);
       exp_count  = read8bitNum(fd_exp, exp17);
       exp_count  = read8bitNum(fd_exp, exp18);
       exp_count  = read8bitNum(fd_exp, exp19);
       exp_count  = read8bitNum(fd_exp, exp20);
       exp_count  = read8bitNum(fd_exp, exp21);
       exp_count  = read8bitNum(fd_exp, exp22);
       exp_count  = read8bitNum(fd_exp, exp23);
       exp_count  = read8bitNum(fd_exp, exp24);
       exp_count  = read8bitNum(fd_exp, exp25);
       exp_count  = read8bitNum(fd_exp, exp26);
       exp_count  = read8bitNum(fd_exp, exp27);
       exp_count  = read8bitNum(fd_exp, exp28);
       exp_count  = read8bitNum(fd_exp, exp29);
       exp_count  = read8bitNum(fd_exp, exp30);
       exp_count  = read8bitNum(fd_exp, exp31);
       exp_count  = read8bitNum(fd_exp, exp32);
       exp_count  = read8bitNum(fd_exp, exp33);
       exp_count  = read8bitNum(fd_exp, exp34);
       exp_count  = read8bitNum(fd_exp, exp35);
       exp_count  = read8bitNum(fd_exp, exp36);
       exp_count  = read8bitNum(fd_exp, exp37);
       exp_count  = read8bitNum(fd_exp, exp38);
       exp_count  = read8bitNum(fd_exp, exp39);
       exp_count  = read8bitNum(fd_exp, exp40);
       exp_count  = read8bitNum(fd_exp, exp41);                                                                                              
       exp_count  = read8bitNum(fd_exp, exp42);
       exp_count  = read8bitNum(fd_exp, exp43);                                                
       exp_count  = read8bitNum(fd_exp, exp44);
       exp_count  = read8bitNum(fd_exp, exp45);
       exp_count  = read8bitNum(fd_exp, exp46);
       exp_count  = read8bitNum(fd_exp, exp47);
       exp_count  = read8bitNum(fd_exp, exp48);
       exp_count  = read8bitNum(fd_exp, exp49);
       exp_count  = read8bitNum(fd_exp, exp50);
       exp_count  = read8bitNum(fd_exp, exp51);
       exp_count  = read8bitNum(fd_exp, exp52);
       exp_count  = read8bitNum(fd_exp, exp53);
       exp_count  = read8bitNum(fd_exp, exp54);
       exp_count  = read8bitNum(fd_exp, exp55);
       exp_count  = read8bitNum(fd_exp, exp56);
       exp_count  = read8bitNum(fd_exp, exp57);
       exp_count  = read8bitNum(fd_exp, exp58);
       exp_count  = read8bitNum(fd_exp, exp59);
       exp_count  = read8bitNum(fd_exp, exp60);
       exp_count  = read8bitNum(fd_exp, exp61);
       exp_count  = read8bitNum(fd_exp, exp62);
       exp_count  = read8bitNum(fd_exp, exp63);
       exp_count  = read8bitNum(fd_exp, exp64);
      end
    end
  end

  // write to ddr3 model {{{
  localparam TB_RST       = 2'b0;
  localparam TB_WR_DATA   = 2'b1;
  localparam TB_WR_PARAM  = 2'b11;
  localparam TB_WR_EXP    = 2'b10;

  localparam DDR_BANK_IMAGE   = 3'b000;
  localparam DDR_BANK_FM1     = 3'b001;
  localparam DDR_BANK_PARAM   = 3'b010;
  localparam DDR_BANK_FM2     = 3'b011;
  localparam DDR_BANK_EXP     = 3'b101;
  localparam DDR_ROW      = 16'h0;
  localparam DDR_COL      = 10'h0;

  localparam WR_ADDR_STRIDE     = 4'd8;
  //image,conv1_1
  localparam WR_IMG_START_ADDR    = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL};
  localparam WR_IMG_END_ADDR      = WR_IMG_START_ADDR + 30'hbff8; // conv1_1, 256*256*3*16/64-8
  //bottom feather map
  localparam WR_DATA_START_ADDR   = {DDR_BANK_FM1, DDR_ROW, DDR_COL};
  localparam WR_DATA_END_ADDR     = WR_DATA_START_ADDR + 30'hf7ff8;
  //param
  localparam WR_PARAM_START_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
  localparam WR_KER_START_ADDR    = WR_PARAM_START_ADDR + 30'd32; //skip bias
  //localparam WR_PARAM_END_ADDR    = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'he0;     //(bias_num*16 + o_channels*in_channels*9*8)/ddr_data_width - ddr_burst_size(8)
  localparam WR_PARAM_END_ADDR    = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'hd0; //without bias
  //localparam WR_PARAM_END_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'h3821c8;  //(bias_num + o_channels*in_channels*9)float_num_bits/ddr_data_width - ddr_burst_size(8)
  //exp
  localparam WR_EXP_START_ADDR  = {DDR_BANK_EXP, DDR_ROW, DDR_COL};
  localparam WR_EXP_END_ADDR    = WR_EXP_START_ADDR + 3'h0;    //(o_channels*5)/ddr_data_width
  //conv
  //localparam CONV_TOP_ADDR      = {DDR_BANK_TOP, DDR_ROW, DDR_COL}; //useless
  //localparam CONV_BOTTOM_ADDR   = WR_DATA_START_ADDR; //useless


  reg  [1:0]    _rdwr_state;
  reg  [1:0]    _next_state;
  reg  [29:0]   _wr_patch_addr;
  reg  [29:0]   _wr_param_addr;
  reg  [29:0]   _wr_exp_addr;
  reg  [511:0]  _wr_data;
  wire [31:0] _rd_data01,_rd_data02,_rd_data03,_rd_data04,_rd_data05,_rd_data06,_rd_data07,_rd_data08,
              _rd_data09,_rd_data10,_rd_data11,_rd_data12,_rd_data13,_rd_data14,_rd_data15,_rd_data16;

  assign _rd_data01 = ddr_rd_data[511:480]; assign _rd_data02 = ddr_rd_data[479:448];
  assign _rd_data03 = ddr_rd_data[447:416]; assign _rd_data04 = ddr_rd_data[415:384];
  assign _rd_data05 = ddr_rd_data[383:352]; assign _rd_data06 = ddr_rd_data[351:320];
  assign _rd_data07 = ddr_rd_data[319:288]; assign _rd_data08 = ddr_rd_data[287:256];
  assign _rd_data09 = ddr_rd_data[255:224]; assign _rd_data10 = ddr_rd_data[223:192];
  assign _rd_data11 = ddr_rd_data[191:160]; assign _rd_data12 = ddr_rd_data[159:128];
  assign _rd_data13 = ddr_rd_data[127:96];  assign _rd_data14 = ddr_rd_data[95:64];
  assign _rd_data15 = ddr_rd_data[63:32];   assign _rd_data16 = ddr_rd_data[31:0];
  // FF
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rdwr_state <= TB_RST;
    end else begin
      _rdwr_state <= _next_state;
    end
  end
  // state transition
  always@(_rdwr_state or init_calib_complete or _wr_patch_addr or _wr_param_addr) begin
    _next_state= TB_RST;
    case(_rdwr_state)
      TB_RST: begin
        if(init_calib_complete && !tb_load_done)
          _next_state = TB_WR_DATA;
        else
          _next_state = TB_RST;
      end
      TB_WR_DATA: begin
        if(_wr_patch_addr == WR_IMG_END_ADDR)
          _next_state = TB_WR_EXP;
        else
          _next_state = TB_WR_DATA;
      end
      TB_WR_EXP: begin
        if(_wr_exp_addr == WR_EXP_END_ADDR)
          _next_state = TB_WR_PARAM;
        else
          _next_state = TB_WR_EXP;
      end
      TB_WR_PARAM: begin
        if(_wr_param_addr == WR_PARAM_END_ADDR)
          _next_state = TB_RST;
        else
          _next_state = TB_WR_PARAM;
      end
    endcase
  end
  // logic
  always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_patch_addr or _wr_param_addr or _wr_exp_addr or
          data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
          data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16 or
          data17 or data18 or data19 or data20 or data21 or data22 or data23 or data24 or
          data25 or data26 or data27 or data28 or data29 or data30 or data31 or data32 or
          param01 or param02 or param03 or param04 or param05 or param06 or param07 or param08 or
          param09 or param10 or param11 or param12 or param13 or param14 or param15 or param16 or
          param17 or param18 or param19 or param20 or param21 or param22 or param23 or param24 or
          param25 or param26 or param27 or param28 or param29 or param30 or param31 or param32 or
          exp01 or exp02 or exp03 or exp04 or exp05 or exp06 or exp07 or exp08 or
          exp09 or exp10 or exp11 or exp12 or exp13 or exp14 or exp15 or exp16 or
          exp17 or exp18 or exp19 or exp20 or exp21 or exp22 or exp23 or exp24 or 
          exp25 or exp26 or exp27 or exp28 or exp29 or exp30 or exp31 or exp32 or
          exp33 or exp34 or exp35 or exp36 or exp37 or exp38 or exp39 or exp40 or
          exp41 or exp42 or exp43 or exp44 or exp45 or exp46 or exp47 or exp48 or
          exp49 or exp50 or exp51 or exp52 or exp53 or exp54 or exp55 or exp56 or 
          exp57 or exp58 or exp59 or exp60 or exp61 or exp62 or exp63 or exp64 or
          exp65
         ) begin
    _next_wr_patch = 1'b0;
    _next_wr_param = 1'b0;
    _next_wr_exp   = 1'b0;
    app_en   = 1'b0;
    app_cmd  = 3'b1; // read
    app_addr = 30'b0;
    app_wdf_wren = 1'b0;
    app_wdf_end  = 1'b1;
    app_wdf_mask = 64'b0;
    app_wdf_data = 512'b0;
    case(_rdwr_state)
      TB_RST: begin
        app_en = 1'b0;
      end
      TB_WR_DATA: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en    = 1'b1;
          app_cmd   = 3'b0; // write command
          app_addr  = _wr_patch_addr;
          app_wdf_mask  = 64'b0; // no mask
          app_wdf_data  = {data32,data31,data30,data29,
                           data28,data27,data26,data25,
                           data24,data23,data22,data21,
                           data20,data19,data18,data17,
                           data16,data15,data14,data13,
                           data12,data11,data10,data09,
                           data08,data07,data06,data05,
                           data04,data03,data02,data01
                           };
          app_wdf_wren  = 1'b1;
          app_wdf_end   = 1'b1;
          if(_wr_patch_addr == WR_IMG_END_ADDR) begin
            _next_wr_patch  = 1'b0;
          end else begin
            _next_wr_patch  = 1'b1;
          end
        end
      end
      TB_WR_PARAM: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en  = 1'b1;
          app_cmd = 3'b0;
          app_addr  = _wr_param_addr;
          app_wdf_mask  = 64'b0;
          app_wdf_data  = {param64,param63,param62,param61,
                           param60,param59,param58,param57,
                           param56,param55,param54,param53,
                           param52,param51,param50,param49,
                           param48,param47,param46,param45,
                           param44,param43,param42,param41,
                           param40,param39,param38,param37,
                           param36,param35,param34,param33,
                           param32,param31,param30,param29,
                           param28,param27,param26,param25,
                           param24,param23,param22,param21,
                           param20,param19,param18,param17,
                           param16,param15,param14,param13,
                           param12,param11,param10,param09,
                           param08,param07,param06,param05,
                           param04,param03,param02,param01
                          };
          app_wdf_wren  = 1'b1;
          app_wdf_end   = 1'b1;
          // $display("%t: app addr: %x\n", $realtime, app_addr);
          if(_wr_param_addr == WR_PARAM_END_ADDR) begin
            _next_wr_param  = 1'b0;
          end else begin
            _next_wr_param  = 1'b1;
          end
        end
      end
      TB_WR_EXP: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en  = 1'b1;
          app_cmd = 3'b0;
          app_addr  = _wr_exp_addr;
          app_wdf_mask  = 64'b0;
          app_wdf_data  = {exp65[4:0],{187{1'h1}},
                           exp64[4:0],exp63[4:0],exp62[4:0],exp61[4:0],exp60[4:0],exp59[4:0],exp58[4:0],exp57[4:0],
                           exp56[4:0],exp55[4:0],exp54[4:0],exp53[4:0],exp52[4:0],exp51[4:0],exp50[4:0],exp49[4:0],
                           exp48[4:0],exp47[4:0],exp46[4:0],exp45[4:0],exp44[4:0],exp43[4:0],exp42[4:0],exp41[4:0],
                           exp40[4:0],exp39[4:0],exp38[4:0],exp37[4:0],exp36[4:0],exp35[4:0],exp34[4:0],exp33[4:0],
                           exp32[4:0],exp31[4:0],exp30[4:0],exp29[4:0],exp28[4:0],exp27[4:0],exp26[4:0],exp25[4:0],
                           exp24[4:0],exp23[4:0],exp22[4:0],exp21[4:0],exp20[4:0],exp19[4:0],exp18[4:0],exp17[4:0],
                           exp16[4:0],exp15[4:0],exp14[4:0],exp13[4:0],exp12[4:0],exp11[4:0],exp10[4:0],exp09[4:0],
                           exp08[4:0],exp07[4:0],exp06[4:0],exp05[4:0],exp04[4:0],exp03[4:0],exp02[4:0],exp01[4:0]
                          };
          app_wdf_wren  = 1'b1;
          app_wdf_end   = 1'b1;
          // $display("%t: app addr: %x\n", $realtime, app_addr);
          if(_wr_exp_addr == WR_EXP_END_ADDR) begin
            _next_wr_exp  = 1'b0;
          end else begin
            _next_wr_exp  = 1'b1;
          end
        end
      end
    endcase
  end

  always@(posedge clk) begin
    if(!rst_n) begin
      _wr_patch_addr<= WR_IMG_START_ADDR;
      _wr_param_addr<= WR_PARAM_START_ADDR;
      _wr_exp_addr<= WR_EXP_START_ADDR;
      tb_load_done  <= 1'b0;
    end else begin
      if(_next_wr_patch) begin
        _wr_patch_addr <= _wr_patch_addr + WR_ADDR_STRIDE;
      //$display("%t: bottom data addr: %x\n", $realtime, _wr_patch_addr);
      end
      if(_next_wr_param) begin
        _wr_param_addr <= _wr_param_addr + WR_ADDR_STRIDE;
      //$display("%t: param data addr: %x\n", $realtime, _wr_param_addr);
      end
      if(_next_wr_exp) begin
        _wr_exp_addr <= _wr_exp_addr + WR_ADDR_STRIDE;
      end

      if(_wr_param_addr == WR_PARAM_END_ADDR) begin
        tb_load_done <= 1'b1;
        //$finish; // any operation on address WR_PARAM_END_ADDR will be terminated
      end
    //if(tb_load_done) begin
    //  closeFile(fd_data);
    //  closeFile(fd_param);
    //end
    end
  end // write to ddr }}}

endmodule
