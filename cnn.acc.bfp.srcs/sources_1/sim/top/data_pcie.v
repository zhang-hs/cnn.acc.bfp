// ---------------------------------------------------
// File       : data_pcie.v
//
// Description: stimulate PCIe data transfer
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/100fs
`define NULL 0
//`define sim_ // simulation using directC
`ifdef sim_ // {{{
  // DirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
  extern int      readFloatcvt16bit(input pointer fileDescriptor, output bit[15:0]);
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
  integer fd_data, fd_param, fd_img;
  integer char_count, data_count, count, countParam, countImg;
  reg [15:0] imgData01,imgData02,imgData03,imgData04,imgData05,imgData06,imgData07,imgData08,
             imgData09,imgData10,imgData11,imgData12,imgData13,imgData14,imgData15,imgData16,
             imgData17,imgData18,imgData19,imgData20,imgData21,imgData22,imgData23,imgData24,
             imgData25,imgData26,imgData27,imgData28,imgData29,imgData30,imgData31,imgData32;
  reg [15:0] data01,data02,data03,data04,data05,data06,data07,data08,
             data09,data10,data11,data12,data13,data14,data15,data16,
             data17,data18,data19,data20,data21,data22,data23,data24,
             data25,data26,data27,data28,data29,data30,data31,data32;
  reg [15:0] param01,param02,param03,param04,param05,param06,param07,param08,
             param09,param10,param11,param12,param13,param14,param15,param16,
             param17,param18,param19,param20,param21,param22,param23,param24,
             param25,param26,param27,param28,param29,param30,param31,param32;
  reg        _next_wr_img, _next_wr_patch, _next_wr_param;

  initial begin
  //fd_img  = getFileDescriptor("../../data/conv_img/img.txt");
    fd_img  = getFileDescriptor("../../data/img/conv1_1.bottom.txt");
    fd_data = getFileDescriptor("../../data/conv5_3/conv5_3.bottom.txt");
    fd_param= getFileDescriptor("../../data/param/all.param.txt");
    char_count = 0;
    data_count = 0;
    if((fd_img == `NULL) || (fd_data == `NULL) || (fd_param == `NULL)) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // img
    $display("read image data\n");
    countImg = readFloatcvt16bit(fd_img, imgData01);
    countImg = readFloatcvt16bit(fd_img, imgData02);
    countImg = readFloatcvt16bit(fd_img, imgData03);
    countImg = readFloatcvt16bit(fd_img, imgData04);
    countImg = readFloatcvt16bit(fd_img, imgData05);
    countImg = readFloatcvt16bit(fd_img, imgData06);
    countImg = readFloatcvt16bit(fd_img, imgData07);
    countImg = readFloatcvt16bit(fd_img, imgData08);
    countImg = readFloatcvt16bit(fd_img, imgData09);
    countImg = readFloatcvt16bit(fd_img, imgData10);
    countImg = readFloatcvt16bit(fd_img, imgData11);
    countImg = readFloatcvt16bit(fd_img, imgData12);
    countImg = readFloatcvt16bit(fd_img, imgData13);
    countImg = readFloatcvt16bit(fd_img, imgData14);
    countImg = readFloatcvt16bit(fd_img, imgData15);
    countImg = readFloatcvt16bit(fd_img, imgData16);
    countImg = readFloatcvt16bit(fd_img, imgData17);
    countImg = readFloatcvt16bit(fd_img, imgData18);
    countImg = readFloatcvt16bit(fd_img, imgData19);
    countImg = readFloatcvt16bit(fd_img, imgData20);
    countImg = readFloatcvt16bit(fd_img, imgData21);
    countImg = readFloatcvt16bit(fd_img, imgData22);
    countImg = readFloatcvt16bit(fd_img, imgData23);
    countImg = readFloatcvt16bit(fd_img, imgData24);
    countImg = readFloatcvt16bit(fd_img, imgData25);
    countImg = readFloatcvt16bit(fd_img, imgData26);
    countImg = readFloatcvt16bit(fd_img, imgData27);
    countImg = readFloatcvt16bit(fd_img, imgData28);
    countImg = readFloatcvt16bit(fd_img, imgData29);
    countImg = readFloatcvt16bit(fd_img, imgData30);
    countImg = readFloatcvt16bit(fd_img, imgData31);
    countImg = readFloatcvt16bit(fd_img, imgData32);
    // data
    $display("read input/output fm data\n");
    count = readFloatcvt16bit(fd_data, data01); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data02); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data03); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data04); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data05); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data06); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data07); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data08); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data09); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data10); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data11); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data12); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data13); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data14); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data15); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data16); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data17); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data18); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data19); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data20); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data21); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data22); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data23); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data24); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data25); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data26); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data27); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data28); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data29); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data30); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data31); char_count = char_count + count;
    count = readFloatcvt16bit(fd_data, data32); char_count = char_count + count;
    $display("read parameter data\n");
    countParam = readFloatcvt16bit(fd_param, param01);
    countParam = readFloatcvt16bit(fd_param, param02);
    countParam = readFloatcvt16bit(fd_param, param03);
    countParam = readFloatcvt16bit(fd_param, param04);
    countParam = readFloatcvt16bit(fd_param, param05);
    countParam = readFloatcvt16bit(fd_param, param06);
    countParam = readFloatcvt16bit(fd_param, param07);
    countParam = readFloatcvt16bit(fd_param, param08);
    countParam = readFloatcvt16bit(fd_param, param09);
    countParam = readFloatcvt16bit(fd_param, param10);
    countParam = readFloatcvt16bit(fd_param, param11);
    countParam = readFloatcvt16bit(fd_param, param12);
    countParam = readFloatcvt16bit(fd_param, param13);
    countParam = readFloatcvt16bit(fd_param, param14);
    countParam = readFloatcvt16bit(fd_param, param15);
    countParam = readFloatcvt16bit(fd_param, param16);
    countParam = readFloatcvt16bit(fd_param, param17);
    countParam = readFloatcvt16bit(fd_param, param18);
    countParam = readFloatcvt16bit(fd_param, param19);
    countParam = readFloatcvt16bit(fd_param, param20);
    countParam = readFloatcvt16bit(fd_param, param21);
    countParam = readFloatcvt16bit(fd_param, param22);
    countParam = readFloatcvt16bit(fd_param, param23);
    countParam = readFloatcvt16bit(fd_param, param24);
    countParam = readFloatcvt16bit(fd_param, param25);
    countParam = readFloatcvt16bit(fd_param, param26);
    countParam = readFloatcvt16bit(fd_param, param27);
    countParam = readFloatcvt16bit(fd_param, param28);
    countParam = readFloatcvt16bit(fd_param, param29);
    countParam = readFloatcvt16bit(fd_param, param30);
    countParam = readFloatcvt16bit(fd_param, param31);
    countParam = readFloatcvt16bit(fd_param, param32);
  end

  // read from file
  always@(posedge clk or negedge rst_n) begin
    if((rst_n) && init_calib_complete) begin
      if(_next_wr_img) begin
        // img
        countImg = readFloatcvt16bit(fd_img, imgData01);
        countImg = readFloatcvt16bit(fd_img, imgData02);
        countImg = readFloatcvt16bit(fd_img, imgData03);
        countImg = readFloatcvt16bit(fd_img, imgData04);
        countImg = readFloatcvt16bit(fd_img, imgData05);
        countImg = readFloatcvt16bit(fd_img, imgData06);
        countImg = readFloatcvt16bit(fd_img, imgData07);
        countImg = readFloatcvt16bit(fd_img, imgData08);
        countImg = readFloatcvt16bit(fd_img, imgData09);
        countImg = readFloatcvt16bit(fd_img, imgData10);
        countImg = readFloatcvt16bit(fd_img, imgData11);
        countImg = readFloatcvt16bit(fd_img, imgData12);
        countImg = readFloatcvt16bit(fd_img, imgData13);
        countImg = readFloatcvt16bit(fd_img, imgData14);
        countImg = readFloatcvt16bit(fd_img, imgData15);
        countImg = readFloatcvt16bit(fd_img, imgData16);
        countImg = readFloatcvt16bit(fd_img, imgData17);
        countImg = readFloatcvt16bit(fd_img, imgData18);
        countImg = readFloatcvt16bit(fd_img, imgData19);
        countImg = readFloatcvt16bit(fd_img, imgData20);
        countImg = readFloatcvt16bit(fd_img, imgData21);
        countImg = readFloatcvt16bit(fd_img, imgData22);
        countImg = readFloatcvt16bit(fd_img, imgData23);
        countImg = readFloatcvt16bit(fd_img, imgData24);
        countImg = readFloatcvt16bit(fd_img, imgData25);
        countImg = readFloatcvt16bit(fd_img, imgData26);
        countImg = readFloatcvt16bit(fd_img, imgData27);
        countImg = readFloatcvt16bit(fd_img, imgData28);
        countImg = readFloatcvt16bit(fd_img, imgData29);
        countImg = readFloatcvt16bit(fd_img, imgData30);
        countImg = readFloatcvt16bit(fd_img, imgData31);
        countImg = readFloatcvt16bit(fd_img, imgData32);
      end

      if(_next_wr_patch) begin
        // patch data
        count = readFloatcvt16bit(fd_data, data01);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data02);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data03);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data04);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data05);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data06);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data07);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data08);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data09);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data10);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data11);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data12);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data13);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data14);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data15);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data16);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data17);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data18);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data19);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data20);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data21);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data22);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data23);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data24);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data25);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data26);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data27);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data28);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data29);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data30);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data31);  char_count = char_count + count;
        count = readFloatcvt16bit(fd_data, data32);  char_count = char_count + count;
      end

      if(_next_wr_param) begin
        // param data
        countParam = readFloatcvt16bit(fd_param, param01);
        countParam = readFloatcvt16bit(fd_param, param02);
        countParam = readFloatcvt16bit(fd_param, param03);
        countParam = readFloatcvt16bit(fd_param, param04);
        countParam = readFloatcvt16bit(fd_param, param05);
        countParam = readFloatcvt16bit(fd_param, param06);
        countParam = readFloatcvt16bit(fd_param, param07);
        countParam = readFloatcvt16bit(fd_param, param08);
        countParam = readFloatcvt16bit(fd_param, param09);
        countParam = readFloatcvt16bit(fd_param, param10);
        countParam = readFloatcvt16bit(fd_param, param11);
        countParam = readFloatcvt16bit(fd_param, param12);
        countParam = readFloatcvt16bit(fd_param, param13);
        countParam = readFloatcvt16bit(fd_param, param14);
        countParam = readFloatcvt16bit(fd_param, param15);
        countParam = readFloatcvt16bit(fd_param, param16);
        countParam = readFloatcvt16bit(fd_param, param17);
        countParam = readFloatcvt16bit(fd_param, param18);
        countParam = readFloatcvt16bit(fd_param, param19);
        countParam = readFloatcvt16bit(fd_param, param20);
        countParam = readFloatcvt16bit(fd_param, param21);
        countParam = readFloatcvt16bit(fd_param, param22);
        countParam = readFloatcvt16bit(fd_param, param23);
        countParam = readFloatcvt16bit(fd_param, param24);
        countParam = readFloatcvt16bit(fd_param, param25);
        countParam = readFloatcvt16bit(fd_param, param26);
        countParam = readFloatcvt16bit(fd_param, param27);
        countParam = readFloatcvt16bit(fd_param, param28);
        countParam = readFloatcvt16bit(fd_param, param29);
        countParam = readFloatcvt16bit(fd_param, param30);
        countParam = readFloatcvt16bit(fd_param, param31);
        countParam = readFloatcvt16bit(fd_param, param32);
      end
    end
  end

  // write to ddr3 model {{{
  localparam TB_RST       = 2'b0;
  localparam TB_WR_IMG    = 2'b1;
  localparam TB_WR_DATA   = 2'b10;
  localparam TB_WR_PARAM  = 2'b11;

  localparam DDR_BANK_IMAGE = 3'b000;
  localparam DDR_BANK_FM1   = 3'b001;
  localparam DDR_BANK_PARAM = 3'b010;
  localparam DDR_BANK_FM2   = 3'b011;
  localparam DDR_ROW      = 16'h0;
  localparam DDR_COL      = 10'h0;

  localparam WR_IMG_START_ADDR  = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL};
  localparam WR_IMG_END_ADDR    = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL} + 30'h2ffff8; // 30'hbff8; // conv1_1
//localparam WR_IMG_END_ADDR    = WR_IMG_START_ADDR;
  localparam WR_DATA_START_ADDR = {DDR_BANK_FM2, DDR_ROW, DDR_COL}; // conv1_2
  localparam WR_DATA_END_ADDR   = {DDR_BANK_FM2, DDR_ROW, DDR_COL} + 30'h7ff8; // conv1_2
  localparam WR_PARAM_START_ADDR= {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
  localparam WR_KER_START_ADDR  = WR_PARAM_START_ADDR + 30'd32;
//localparam WR_PARAM_END_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'h3821c8; // conv.all.param
  localparam WR_PARAM_END_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'h6c4b48;
  localparam WR_ADDR_STRIDE     = 4'd8;

  reg  [1:0]    _rdwr_state;
  reg  [1:0]    _next_state;
  reg  [29:0]   _wr_img_addr;
  reg  [29:0]   _wr_patch_addr;
  reg  [29:0]   _wr_param_addr;
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
  always@(_rdwr_state or init_calib_complete or _wr_img_addr or _wr_patch_addr or _wr_param_addr) begin
    _next_state= TB_RST;
    case(_rdwr_state)
      TB_RST: begin
        if(init_calib_complete && !tb_load_done) begin
          if(WR_IMG_START_ADDR!=WR_IMG_END_ADDR)
            _next_state = TB_WR_IMG;
          else
            _next_state = TB_WR_DATA;
        end else begin
          _next_state = TB_RST;
        end
      end
      TB_WR_IMG: begin
        if(_wr_img_addr == WR_IMG_END_ADDR)
          _next_state = TB_WR_DATA;
        else
          _next_state = TB_WR_IMG;
      end
      TB_WR_DATA: begin
        if(_wr_patch_addr == WR_DATA_END_ADDR)
          _next_state = TB_WR_PARAM;
        else
          _next_state = TB_WR_DATA;
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
  always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_img_addr or _wr_patch_addr or _wr_param_addr or
          imgData01 or imgData02 or imgData03 or imgData04 or imgData05 or imgData06 or imgData07 or imgData08 or
          imgData09 or imgData10 or imgData11 or imgData12 or imgData13 or imgData14 or imgData15 or imgData16 or
          imgData17 or imgData18 or imgData19 or imgData20 or imgData21 or imgData22 or imgData23 or imgData24 or
          imgData25 or imgData26 or imgData27 or imgData28 or imgData29 or imgData30 or imgData31 or imgData32 or
          data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
          data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16 or
          data17 or data18 or data19 or data20 or data21 or data22 or data23 or data24 or
          data25 or data26 or data27 or data28 or data29 or data30 or data31 or data32 or
          param01 or param02 or param03 or param04 or param05 or param06 or param07 or param08 or
          param09 or param10 or param11 or param12 or param13 or param14 or param15 or param16 or
          param17 or param18 or param19 or param20 or param21 or param22 or param23 or param24 or
          param25 or param26 or param27 or param28 or param29 or param30 or param31 or param32
         ) begin
    _next_wr_img   = 1'b0;
    _next_wr_patch = 1'b0;
    _next_wr_param = 1'b0;
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
      TB_WR_IMG: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en    = 1'b1;
          app_cmd   = 3'b0; // write command
          app_addr  = _wr_img_addr;
          app_wdf_mask  = 64'b0; // no mask
          app_wdf_data  = {imgData32,imgData31,imgData30,imgData29,
                           imgData28,imgData27,imgData26,imgData25,
                           imgData24,imgData23,imgData22,imgData21,
                           imgData20,imgData19,imgData18,imgData17,
                           imgData16,imgData15,imgData14,imgData13,
                           imgData12,imgData11,imgData10,imgData09,
                           imgData08,imgData07,imgData06,imgData05,
                           imgData04,imgData03,imgData02,imgData01
                           };
          app_wdf_wren  = 1'b1;
          app_wdf_end   = 1'b1;
          if(_wr_img_addr == WR_IMG_END_ADDR) begin
            _next_wr_img = 1'b0;
          end else begin
            _next_wr_img = 1'b1;
          end
        end
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
          if(_wr_patch_addr == WR_DATA_END_ADDR) begin
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
          app_wdf_param  ={param32,param31,param30,param29,
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
          if(_wr_param_addr == WR_PARAM_END_ADDR) begin
            _next_wr_param  = 1'b0;
          end else begin
            _next_wr_param  = 1'b1;
          end
        end
      end
    endcase
  end

  always@(posedge clk) begin
    if(!rst_n) begin
      _wr_img_addr  <= WR_IMG_START_ADDR;
      _wr_patch_addr<= WR_DATA_START_ADDR;
      _wr_param_addr<= WR_PARAM_START_ADDR;
      tb_load_done  <= 1'b0;
    end else begin
      if(_next_wr_img) begin
        _wr_img_addr <= _wr_img_addr + WR_ADDR_STRIDE;
      //$display("%t: img data addr: %x\n", $realtime, _wr_img_addr);
      end
      if(_next_wr_patch) begin
        _wr_patch_addr <= _wr_patch_addr + WR_ADDR_STRIDE;
      //$display("%t: bottom data addr: %x\n", $realtime, _wr_patch_addr);
      end
      if(_next_wr_param) begin
        _wr_param_addr <= _wr_param_addr + WR_ADDR_STRIDE;
      //$display("%t: param data addr: %x\n", $realtime, _wr_param_addr);
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
