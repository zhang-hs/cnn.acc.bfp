// ---------------------------------------------------
// File       : data_pcie.v
//
// Description: stimulate PCIe data transfer
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/1ps
`define sim_ // simulation using directC
`ifdef sim_ // {{{
  // DirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
  extern int      read16bitNum(input pointer fileDescriptor, output bit[15:0]);
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
//  localparam EXP = 8;
//  localparam MAN = 23;
  integer fd_data, fd_param, fd_exp;
  integer char_count, data_count, count, countParam, exp_count;
  //bottom
  reg [15:0] data01,data02,data03,data04,data05,data06,data07,data08,
             data09,data10,data11,data12,data13,data14,data15,data16,
             data17,data18,data19,data20,data21,data22,data23,data24,
             data25,data26,data27,data28,data29,data30,data31,data32;
  //param:16bits
  reg [15:0] param01,param02,param03,param04,param05,param06,param07,param08,
             param09,param10,param11,param12,param13,param14,param15,param16,
             param17,param18,param19,param20,param21,param22,param23,param24,
             param25,param26,param27,param28,param29,param30,param31,param32;
 //exp of param and data:5bits
  reg [7:0] exp01,exp02,exp03,exp04,exp05,exp06,exp07,exp08,
            exp09,exp10,exp11,exp12,exp13,exp14,exp15,exp16,
            exp17,exp18,exp19,exp20,exp21,exp22,exp23,exp24,
            exp25,exp26,exp27,exp28,exp29,exp30,exp31,exp32,
            exp33,exp34,exp35,exp36,exp37,exp38,exp39,exp40,
            exp41,exp42,exp43,exp44,exp45,exp46,exp47,exp48,
            exp49,exp50,exp51,exp52,exp53,exp54,exp55,exp56,
            exp57,exp58,exp59,exp60,exp61,exp62,exp63,exp64;
  reg       _next_wr_img, _next_wr_patch, _next_wr_param,  _next_wr_exp;

  initial begin
    $display("location:data_pcie.v\n");
    fd_data = getFileDescriptor("../../../../../data/vggent16/bottom.txt"); //just for logic testing
    fd_param= getFileDescriptor("../../../../../data/vggnet16/param_all.txt");
    fd_exp  = getFileDescriptor("../../../../../data/vggnet16/exp.txt");
    char_count = 0;
    data_count = 0;
    exp_count  = 0;
    if((fd_data == `NULL) || (fd_param == `NULL) || (fd_exp == `NULL)) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // bottomdata
    $display("read data\n");
    count = read16bitNum(fd_data, data01); 
    count = read16bitNum(fd_data, data02); 
    count = read16bitNum(fd_data, data03); 
    count = read16bitNum(fd_data, data04); 
    count = read16bitNum(fd_data, data05); 
    count = read16bitNum(fd_data, data06); 
    count = read16bitNum(fd_data, data07); 
    count = read16bitNum(fd_data, data08); 
    count = read16bitNum(fd_data, data09); 
    count = read16bitNum(fd_data, data10); 
    count = read16bitNum(fd_data, data11); 
    count = read16bitNum(fd_data, data12); 
    count = read16bitNum(fd_data, data13); 
    count = read16bitNum(fd_data, data14); 
    count = read16bitNum(fd_data, data15); 
    count = read16bitNum(fd_data, data16); 
    count = read16bitNum(fd_data, data17); 
    count = read16bitNum(fd_data, data18); 
    count = read16bitNum(fd_data, data19); 
    count = read16bitNum(fd_data, data20); 
    count = read16bitNum(fd_data, data21); 
    count = read16bitNum(fd_data, data22); 
    count = read16bitNum(fd_data, data23); 
    count = read16bitNum(fd_data, data24); 
    count = read16bitNum(fd_data, data25); 
    count = read16bitNum(fd_data, data26); 
    count = read16bitNum(fd_data, data27); 
    count = read16bitNum(fd_data, data28); 
    count = read16bitNum(fd_data, data29); 
    count = read16bitNum(fd_data, data30); 
    count = read16bitNum(fd_data, data31); 
    count = read16bitNum(fd_data, data32); 
    $display("read param\n");
    count = read16bitNum(fd_param, param01); 
    count = read16bitNum(fd_param, param02); 
    count = read16bitNum(fd_param, param03); 
    count = read16bitNum(fd_param, param04); 
    count = read16bitNum(fd_param, param05); 
    count = read16bitNum(fd_param, param06); 
    count = read16bitNum(fd_param, param07); 
    count = read16bitNum(fd_param, param08); 
    count = read16bitNum(fd_param, param09); 
    count = read16bitNum(fd_param, param10); 
    count = read16bitNum(fd_param, param11); 
    count = read16bitNum(fd_param, param12); 
    count = read16bitNum(fd_param, param13); 
    count = read16bitNum(fd_param, param14); 
    count = read16bitNum(fd_param, param15); 
    count = read16bitNum(fd_param, param16); 
    count = read16bitNum(fd_param, param17); 
    count = read16bitNum(fd_param, param18); 
    count = read16bitNum(fd_param, param19); 
    count = read16bitNum(fd_param, param20); 
    count = read16bitNum(fd_param, param21); 
    count = read16bitNum(fd_param, param22); 
    count = read16bitNum(fd_param, param23); 
    count = read16bitNum(fd_param, param24); 
    count = read16bitNum(fd_param, param25); 
    count = read16bitNum(fd_param, param26); 
    count = read16bitNum(fd_param, param27); 
    count = read16bitNum(fd_param, param28); 
    count = read16bitNum(fd_param, param29); 
    count = read16bitNum(fd_param, param30); 
    count = read16bitNum(fd_param, param31); 
    count = read16bitNum(fd_param, param32); 
    $display("read exp\n");
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

  // read from file
  always@(posedge clk or negedge rst_n) begin
    if((rst_n) && init_calib_complete) begin
      if(_next_wr_patch) begin
        // patch data
        count = read16bitNum(fd_data, data01); 
        count = read16bitNum(fd_data, data02); 
        count = read16bitNum(fd_data, data03); 
        count = read16bitNum(fd_data, data04); 
        count = read16bitNum(fd_data, data05); 
        count = read16bitNum(fd_data, data06); 
        count = read16bitNum(fd_data, data07); 
        count = read16bitNum(fd_data, data08); 
        count = read16bitNum(fd_data, data09); 
        count = read16bitNum(fd_data, data10); 
        count = read16bitNum(fd_data, data11); 
        count = read16bitNum(fd_data, data12); 
        count = read16bitNum(fd_data, data13); 
        count = read16bitNum(fd_data, data14); 
        count = read16bitNum(fd_data, data15); 
        count = read16bitNum(fd_data, data16); 
        count = read16bitNum(fd_data, data17); 
        count = read16bitNum(fd_data, data18); 
        count = read16bitNum(fd_data, data19); 
        count = read16bitNum(fd_data, data20); 
        count = read16bitNum(fd_data, data21); 
        count = read16bitNum(fd_data, data22); 
        count = read16bitNum(fd_data, data23); 
        count = read16bitNum(fd_data, data24); 
        count = read16bitNum(fd_data, data25); 
        count = read16bitNum(fd_data, data26); 
        count = read16bitNum(fd_data, data27); 
        count = read16bitNum(fd_data, data28); 
        count = read16bitNum(fd_data, data29); 
        count = read16bitNum(fd_data, data30); 
        count = read16bitNum(fd_data, data31); 
        count = read16bitNum(fd_data, data32); 
      end

      if(_next_wr_param) begin
        // ker data
        countParam = read16bitNum(fd_param, param01);
        countParam = read16bitNum(fd_param, param02);
        countParam = read16bitNum(fd_param, param03);
        countParam = read16bitNum(fd_param, param04);
        countParam = read16bitNum(fd_param, param05);
        countParam = read16bitNum(fd_param, param06);
        countParam = read16bitNum(fd_param, param07);
        countParam = read16bitNum(fd_param, param08);
        countParam = read16bitNum(fd_param, param09);
        countParam = read16bitNum(fd_param, param10);
        countParam = read16bitNum(fd_param, param11);
        countParam = read16bitNum(fd_param, param12);
        countParam = read16bitNum(fd_param, param13);
        countParam = read16bitNum(fd_param, param14);
        countParam = read16bitNum(fd_param, param15);
        countParam = read16bitNum(fd_param, param16);
        countParam = read16bitNum(fd_param, param17);
        countParam = read16bitNum(fd_param, param18);
        countParam = read16bitNum(fd_param, param19);
        countParam = read16bitNum(fd_param, param20);
        countParam = read16bitNum(fd_param, param21);
        countParam = read16bitNum(fd_param, param22);
        countParam = read16bitNum(fd_param, param23);
        countParam = read16bitNum(fd_param, param24);
        countParam = read16bitNum(fd_param, param25);
        countParam = read16bitNum(fd_param, param26);
        countParam = read16bitNum(fd_param, param27);
        countParam = read16bitNum(fd_param, param28);
        countParam = read16bitNum(fd_param, param29);
        countParam = read16bitNum(fd_param, param30);
        countParam = read16bitNum(fd_param, param31);
        countParam = read16bitNum(fd_param, param32);
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
  localparam DDR_BANK_IMAGE   = 4'b0000;
  localparam DDR_BANK_FM1     = 4'b0001;
  localparam DDR_BANK_PARAM   = 4'b0010;
  localparam DDR_BANK_FM2     = 4'b0011;
  localparam DDR_BANK_EXP     = 4'b0101;
  localparam DDR_ROW      = 16'h0;
  localparam DDR_COL      = 10'h0;

  localparam WR_ADDR_STRIDE     = 4'd8;
  //image: fm_size*fm_size*in_channel*data_width(16)/64-8
  //// 1_1-->30'hbff8, 1_2-->30'hffff8, 2-1-->30'h3fff8, 2-2-->30'h7fff8, 3-1-->30'h1fff8, 3-2-->30'h3fff8,
  //// 3-3-->30'h3fff8, 4-1-->30'hfff8, 4-2-->30'h1fff8, 4-3-->30'h1fff8, 5-1-->30'h7ff8, 5-2-->30'h7ff8, 5-3-->30'h7ff8
  localparam WR_IMG_START_ADDR    = {DDR_BANK_FM2, DDR_ROW, DDR_COL}; //lasyer_index==0:DDR_BANK_IMAGE, odd: DDR_BANK_FM1, even: DDR_BANK_FM2 
  localparam WR_IMG_END_ADDR      = WR_IMG_START_ADDR + 30'h7ff8; 

  //param
  //bias:out_channel*data_width(16)/64-8
  //1_1-->30'h08, 1_2-->30'h08, 2-1-->30'h18, 2-2-->30'h18, 3-1-->30'h38, 3-2-->30'h38,
  //3-3-->30'h38, 4-1-->30'h78, 4-2-->30'h78, 4-3-->30'h78, 5-1-->30'h78, 5-2-->30'h78, 5-3-->0'h78
  //bias+ker: bias + in_channel*ker_size*ker_size*out_channel*data_width(8)/64-8
  //1_1-->30'heo, 1_2-->30'h1208, 2-1-->30'h2418, 2-2-->30'h4818, 3-1-->30'h9038,3-2-->30'h12038,
  //3-3-->30'h12038, 4-1-->30'h24078, 4-2-->30'h48078, 4-3-->30'h48078, 5-1-->30'h48078, 5-2-->30'h48078,5-3-->30'h48078,conv-->30'h1c12f0, all-->30'h503c70
  localparam WR_PARAM_START_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
//  localparam WR_KER_START_ADDR    = WR_PARAM_START_ADDR + 30'h80; //skip bias
//  localparam WR_BIAS_END_ADDR     = WR_PARAM_START_ADDR + 30'h78; //WR_PARAM_SATART_ADDR + bias
  localparam WR_KER_END_ADDR      = WR_PARAM_START_ADDR + 30'h503c70; //WR_PARAM_START_ADDR + bias + ker;

  //exp: (512+out_channel*8)/64-8
  //1_1-->30'h08, 1_2-->30'h08, 2_1-->30'h10, 2-2-->30'h10, 3-1-->30'h20, 3-2-->30'h20,
  //3-3-->30'h20, 4-1-->30'h40, 4-2-->30'h40, 4-3-->30'h40, 5-1-->30'h40, 5-2-->30'h40, 5-3-->30'h40, total-->30'h210
  localparam WR_EXP_START_ADDR  = {DDR_BANK_EXP, DDR_ROW, DDR_COL};
  localparam WR_EXP_END_ADDR    = WR_EXP_START_ADDR + 30'h210;

  localparam TB_RST       = 3'b000;
  localparam TB_WR_DATA   = 3'b001;
  localparam TB_WR_PARAM    = 3'b010;
  localparam TB_WR_EXP    = 3'b011;
  reg  [2:0]    _rdwr_state;
  reg  [2:0]    _next_state;
  reg  [29:0]   _wr_patch_addr;
  reg  [29:0]   _wr_param_addr;
  reg  [29:0]   _wr_exp_addr;
  
  // FF
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rdwr_state <= TB_RST;
    end else begin
      _rdwr_state <= _next_state;
    end
  end
  // state transition
  always@(_rdwr_state or init_calib_complete or _wr_patch_addr or _wr_param_addr or _wr_exp_addr) begin
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
          _next_state = TB_WR_PARAM;
        else
          _next_state = TB_WR_DATA;
      end
      TB_WR_PARAM: begin
        if(_wr_param_addr == WR_KER_END_ADDR)
          _next_state = TB_WR_EXP;
        else
          _next_state = TB_WR_PARAM;
      end
      TB_WR_EXP: begin
        if(_wr_exp_addr == WR_EXP_END_ADDR)
          _next_state = TB_RST;
        else
          _next_state = TB_WR_EXP;
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
          exp57 or exp58 or exp59 or exp60 or exp61 or exp62 or exp63 or exp64
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
          app_wdf_data  = {
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
          if(_wr_param_addr == WR_KER_END_ADDR) begin
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
          app_wdf_data  = {exp64,exp63,exp62,exp61,exp60,exp59,exp58,exp57,
                           exp56,exp55,exp54,exp53,exp52,exp51,exp50,exp49,
                           exp48,exp47,exp46,exp45,exp44,exp43,exp42,exp41,
                           exp40,exp39,exp38,exp37,exp36,exp35,exp34,exp33,
                           exp32,exp31,exp30,exp29,exp28,exp27,exp26,exp25,
                           exp24,exp23,exp22,exp21,exp20,exp19,exp18,exp17,
                           exp16,exp15,exp14,exp13,exp12,exp11,exp10,exp09,
                           exp08,exp07,exp06,exp05,exp04,exp03,exp02,exp01
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
      _wr_patch_addr <= WR_IMG_START_ADDR;
      _wr_param_addr <= WR_PARAM_START_ADDR;
      _wr_exp_addr <= WR_EXP_START_ADDR;
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

      if(_wr_exp_addr == WR_EXP_END_ADDR) begin
        tb_load_done <= 1'b1;
        //$finish; // any operation on address WR_PARAM_END_ADDR will be terminated
      end
//      if(tb_load_done) begin
//        closeFile(fd_data);
//        closeFile(fd_param);
//        closeFile(fd_exp);
//      end
    end
  end // write to ddr }}}

endmodule
