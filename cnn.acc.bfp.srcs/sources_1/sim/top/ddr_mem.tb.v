// ---------------------------------------------------
// File       : ddr_mem.tb.v
//
// Description: testbench of ddr memory
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
  extern void     printProcRam(input bit[16*16*32-1:0] procRAM, input bit procRamFull);
`endif // }}}
module top;

  // clocks
  reg  ddr_clk;
  reg  sys_rst_n;
  reg  init_calib_complete;
  initial begin
    sys_rst_n           = 1'b0;
    init_calib_complete = 1'b0;
    #50  sys_rst_n            = 1'b1;
    #100 init_calib_complete  = 1'b1;
  end
  initial ddr_clk = 1'b0;
  always ddr_clk = #10 ~ddr_clk;

  initial begin
  //if ($test$plusargs ("dump_all")) begin
  //  `ifdef NCV // Cadence TRN dump
  //      $recordsetup("design=board",
  //                   "compress",
  //                   "wrapsize=100M",
  //                   "version=1",
  //                   "run=1");
  //      $recordvars();

  //  `elsif VCS //Synopsys VPD dump
          $vcdplusfile("top.vpd");
          $vcdpluson;
          $vcdplusglitchon;
  //  `else
  //      // Verilog VC dump
  //      $dumpfile("top.vcd");
  //      $dumpvars(0, rd_ddr_op_tb);
  //  `endif
  //end
  end

  wire [29:0]   ddr_addr;
  wire [2:0]    ddr_cmd;
  wire          ddr_en;
  wire [511:0]  ddr_rd_data;
  wire          ddr_rd_data_end;
  wire          ddr_rd_data_valid;
  wire          ddr_rdy;
  wire [511:0]  ddr_wdf_data;
  wire [63:0]   ddr_wdf_mask;
  wire          ddr_wdf_end;
  wire          ddr_wdf_wren;
  wire          ddr_wdf_rdy;
  // simulation
  reg  [29:0]   app_addr;
  reg  [2:0]    app_cmd;
  reg           app_en;
  reg  [511:0]  app_wdf_data;
  reg  [63:0]   app_wdf_mask;
  reg           app_wdf_end;
  reg           app_wdf_wren;

  ddr_mem data_mem(
    .clk(ddr_clk),
    .ddr_addr(ddr_addr),
    .ddr_cmd(ddr_cmd),
    .ddr_en(ddr_en),
    .ddr_rd_data(ddr_rd_data),
    .ddr_rd_data_end(ddr_rd_data_end),
    .ddr_rd_data_valid(ddr_rd_data_valid),
    .ddr_rdy(ddr_rdy),

    .ddr_wdf_data(ddr_wdf_data),
    .ddr_wdf_mask(ddr_wdf_mask),
    .ddr_wdf_end(ddr_wdf_end),
    .ddr_wdf_wren(ddr_wdf_wren),
    .ddr_wdf_rdy(ddr_wdf_rdy)
  );

  // open file
  localparam EXP = 8;
  localparam MAN = 23;
  integer fd_data, fd_param;
  integer char_count, data_count, count, countParam;
  reg [EXP+MAN:0] data01,data02,data03,data04,data05,data06,data07,data08,
                  data09,data10,data11,data12,data13,data14,data15,data16;
  reg [EXP+MAN:0] param01,param02,param03,param04,param05,param06,param07,param08,
                  param09,param10,param11,param12,param13,param14,param15,param16;
  reg             _next_wr_patch, _next_wr_param;
  reg             tb_load_done; // data ready

  initial begin
    fd_data = getFileDescriptor("../../data/conv1_1/conv1_1.bottom.txt");
    fd_param= getFileDescriptor("../../data/conv1_1/conv1_1.param.txt");
    char_count = 0;
    data_count = 0;
    if((fd_data == `NULL) || (fd_param == `NULL)) begin
      $display("fd handle is NULL\n");
      $finish;
    end
    // data
    count = readFloatNum(fd_data, data01); char_count = char_count + count;
    count = readFloatNum(fd_data, data02); char_count = char_count + count;
    count = readFloatNum(fd_data, data03); char_count = char_count + count;
    count = readFloatNum(fd_data, data04); char_count = char_count + count;
    count = readFloatNum(fd_data, data05); char_count = char_count + count;
    count = readFloatNum(fd_data, data06); char_count = char_count + count;
    count = readFloatNum(fd_data, data07); char_count = char_count + count;
    count = readFloatNum(fd_data, data08); char_count = char_count + count;
    count = readFloatNum(fd_data, data09); char_count = char_count + count;
    count = readFloatNum(fd_data, data10); char_count = char_count + count;
    count = readFloatNum(fd_data, data11); char_count = char_count + count;
    count = readFloatNum(fd_data, data12); char_count = char_count + count;
    count = readFloatNum(fd_data, data13); char_count = char_count + count;
    count = readFloatNum(fd_data, data14); char_count = char_count + count;
    count = readFloatNum(fd_data, data15); char_count = char_count + count;
    count = readFloatNum(fd_data, data16); char_count = char_count + count;

    countParam = readFloatNum(fd_param, param01);
    countParam = readFloatNum(fd_param, param02);
    countParam = readFloatNum(fd_param, param03);
    countParam = readFloatNum(fd_param, param04);
    countParam = readFloatNum(fd_param, param05);
    countParam = readFloatNum(fd_param, param06);
    countParam = readFloatNum(fd_param, param07);
    countParam = readFloatNum(fd_param, param08);
    countParam = readFloatNum(fd_param, param09);
    countParam = readFloatNum(fd_param, param10);
    countParam = readFloatNum(fd_param, param11);
    countParam = readFloatNum(fd_param, param12);
    countParam = readFloatNum(fd_param, param13);
    countParam = readFloatNum(fd_param, param14);
    countParam = readFloatNum(fd_param, param15);
    countParam = readFloatNum(fd_param, param16);
  end

  // read from file
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if((sys_rst_n) && init_calib_complete) begin
      if(_next_wr_patch) begin
        // patch data
        count = readFloatNum(fd_data, data01);  char_count = char_count + count;
        count = readFloatNum(fd_data, data02);  char_count = char_count + count;
        count = readFloatNum(fd_data, data03);  char_count = char_count + count;
        count = readFloatNum(fd_data, data04);  char_count = char_count + count;
        count = readFloatNum(fd_data, data05);  char_count = char_count + count;
        count = readFloatNum(fd_data, data06);  char_count = char_count + count;
        count = readFloatNum(fd_data, data07);  char_count = char_count + count;
        count = readFloatNum(fd_data, data08);  char_count = char_count + count;
        count = readFloatNum(fd_data, data09);  char_count = char_count + count;
        count = readFloatNum(fd_data, data10);  char_count = char_count + count;
        count = readFloatNum(fd_data, data11);  char_count = char_count + count;
        count = readFloatNum(fd_data, data12);  char_count = char_count + count;
        count = readFloatNum(fd_data, data13);  char_count = char_count + count;
        count = readFloatNum(fd_data, data14);  char_count = char_count + count;
        count = readFloatNum(fd_data, data15);  char_count = char_count + count;
        count = readFloatNum(fd_data, data16);  char_count = char_count + count;
      end

      if(_next_wr_param) begin
        // param data
        countParam = readFloatNum(fd_param, param01);
        countParam = readFloatNum(fd_param, param02);
        countParam = readFloatNum(fd_param, param03);
        countParam = readFloatNum(fd_param, param04);
        countParam = readFloatNum(fd_param, param05);
        countParam = readFloatNum(fd_param, param06);
        countParam = readFloatNum(fd_param, param07);
        countParam = readFloatNum(fd_param, param08);
        countParam = readFloatNum(fd_param, param09);
        countParam = readFloatNum(fd_param, param10);
        countParam = readFloatNum(fd_param, param11);
        countParam = readFloatNum(fd_param, param12);
        countParam = readFloatNum(fd_param, param13);
        countParam = readFloatNum(fd_param, param14);
        countParam = readFloatNum(fd_param, param15);
        countParam = readFloatNum(fd_param, param16);
      end
    end
  end

  // write to ddr3 model {{{
  localparam TB_RST       = 2'b0;
  localparam TB_WR_DATA   = 2'b1;
  localparam TB_WR_PARAM  = 2'b10;

  localparam DDR_BANK_PARAM = 3'b010;
  localparam DDR_BANK_PATCH = 3'b000;
  localparam DDR_BANK_TOP   = 3'b001;
  localparam DDR_ROW      = 16'h0;
  localparam DDR_COL      = 10'h0;

  localparam WR_DATA_START_ADDR = {DDR_BANK_PATCH, DDR_ROW, DDR_COL};
  localparam WR_DATA_END_ADDR   = {DDR_BANK_PATCH, DDR_ROW, DDR_COL} + 30'h17ff8; //30'hfff8; //30'h1ffff8; // 30'h61f8; // channels*(fm_width*fm_height)*float_num_bit/ddr_data_width - ddr_burst_size
  localparam WR_PARAM_START_ADDR= {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
  localparam WR_KER_START_ADDR  = WR_PARAM_START_ADDR + 30'd32;
  localparam WR_PARAM_END_ADDR  = {DDR_BANK_PARAM, DDR_ROW, DDR_COL} + 30'h378; // 30'h4818; // (bias_num + 64*3*9)*float_num_bit/ddr_data_width - ddr_burst_size
  localparam CONV_TOP_ADDR      = {DDR_BANK_TOP, DDR_ROW, DDR_COL};
  localparam CONV_BOTTOM_ADDR   = WR_DATA_START_ADDR;
  localparam WR_ADDR_STRIDE     = 4'd8;

  reg  [1:0]    _rdwr_state;
  reg  [1:0]    _next_state;
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
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
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
  always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_patch_addr or _wr_param_addr or
          data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
          data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16 or
          param01 or param02 or param03 or param04 or param05 or param06 or param07 or param08 or
          param09 or param10 or param11 or param12 or param13 or param14 or param15 or param16
         ) begin
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
      TB_WR_DATA: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en    = 1'b1;
          app_cmd   = 3'b0; // write command
          app_addr  = _wr_patch_addr;
          app_wdf_mask  = 64'b0; // no mask
          app_wdf_data  = {data01,data02,data03,data04,
                           data05,data06,data07,data08,
                           data09,data10,data11,data12,
                           data13,data14,data15,data16};
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
          app_wdf_data  = {param01,param02,param03,param04,
                           param05,param06,param07,param08,
                           param09,param10,param11,param12,
                           param13,param14,param15,param16};
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

  always@(posedge ddr_clk) begin
    if(!sys_rst_n) begin
      _wr_patch_addr<= WR_DATA_START_ADDR;
      _wr_param_addr<= WR_PARAM_START_ADDR;
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

      if(_wr_param_addr == WR_PARAM_END_ADDR) begin
        tb_load_done <= 1'b1;
        //$display("%t: loading data done", $realtime);
        //#100 $finish; // any operation on address WR_PARAM_END_ADDR will be terminated
      end
    //if(tb_load_done) begin
    //  closeFile(fd_data);
    //  closeFile(fd_param);
    //end
    end
  end // write to ddr }}}

  localparam    ENDOFX = 16-1;
  localparam    ENDOFY = 16-1;
  reg  [15*21*32-1:0] procRAM; // procRamHeight*procRamWidth(for rd_ddr_data.v)*floatNumWidth - 1 : 0

  // conv layer ddr interface
  wire        conv_ddr_en;
  wire [2:0]  conv_ddr_cmd;
  wire [29:0] conv_ddr_addr;
  // write
  wire        conv_ddr_wdf_wren;
  wire        conv_ddr_wdf_end;
  wire [63:0] conv_ddr_wdf_mask;
  wire [511:0]conv_ddr_wdf_data;
//wire conv_ddr_rd_data; -> ddr_rd_data;
//wire conv_ddr_rdy; -> ddr_rdy;
//wire conv_ddr_rd_data_valid; -> ddr_rd_data_valid;
  assign ddr_en   = tb_load_done ? conv_ddr_en   : app_en;
  assign ddr_cmd  = tb_load_done ? conv_ddr_cmd  : app_cmd;
  assign ddr_addr = tb_load_done ? conv_ddr_addr : app_addr;
  assign ddr_wdf_wren = tb_load_done ? conv_ddr_wdf_wren : app_wdf_wren;
  assign ddr_wdf_end  = tb_load_done ? conv_ddr_wdf_end : app_wdf_end;
  assign ddr_wdf_mask = tb_load_done ? conv_ddr_wdf_mask : app_wdf_mask;
  assign ddr_wdf_data = tb_load_done ? conv_ddr_wdf_data : app_wdf_data;
  reg  _fm_start;
  reg  tb_load_done_reg;
  wire tb_load_done_rising_edge;
  assign tb_load_done_rising_edge = (tb_load_done && (!tb_load_done_reg));

  wire _fm_data_valid_last;
  wire [32*3*3*32-1:0]  _fm_mem_ker;
  wire [16*16*32-1:0]   _fm_mem_ram;

  conv conv_layer(
  // -------------------- simulation --------------------{
      .fm_mem_patch_proc_ram(_fm_mem_ram), // [16*16*(EXPONENT+MANTISSA+1)-1:0]
      .fm_mem_ker(_fm_mem_ker), // [32*3*3*(EXPONENT+MANTISSA+1)-1:0]
      .fm_data_valid_last(_fm_data_valid_last),
      .fm_cmp_top(1'b0),
      .fm_cmp_bottom_ker(1'b1),
  // -------------------- simulation --------------------}
      .clk(ddr_clk),
      .rst_n(sys_rst_n),
      .ddr_rd_data_valid(ddr_rd_data_valid),
      .ddr_rdy(ddr_rdy),
      .ddr_rd_data(ddr_rd_data),
      .ddr_addr(conv_ddr_addr),
      .ddr_cmd(conv_ddr_cmd),
      .ddr_en(conv_ddr_en),
      // top data to ddr
      .ddr_wdf_rdy(ddr_wdf_rdy),
      .ddr_wdf_wren(conv_ddr_wdf_wren),
      .ddr_wdf_data(conv_ddr_wdf_data),
      .ddr_wdf_mask(conv_ddr_wdf_mask),
      .ddr_wdf_end(conv_ddr_wdf_end),
      // layer configuration
      .fm_relu_en(1'b0), // <-x enable relu, should change the output data for top data checking
      .fm_pooling_en(1'b0),
      // bottom
      .fm_width(9'd16), // bottom data width / atomic_width
      .fm_height(9'd16), // bottom data height / atomic_height
      .fm_bottom_ddr_addr(CONV_BOTTOM_ADDR), // bottom data address to read from
      .fm_bottom_channels(10'd3), // num of bottom data channels
      .fm_size(30'd32768), // 64*4*num_of_atom_in_height*num_of_atom_in_width*float_num_width/ddr_data_width(32bit) // 14x14: 128
      .fm_1bar_size(30'd2048),  // 64*4*num_of_atom*float_num_width/ddr_data_width(32bit) // 14x14: 128
      .fm_half_bar_size(30'd1024), // 7*rd_data_max_x*float_num_width/ddr_data_width -> 64*2*num_of_atom*float_num_width/ddr_data_width(32bit) // 14x14: 64
      // kernel and bias
      .fm_bias_num(10'd64), // num of top data channels -> num of bias
      .fm_bias_ddr_burst_num(6'd4), // num of burst to read all bias data
      .fm_bias_offset(9'd2), // address occupied by bias data
      .fm_ker_ddr_addr(WR_KER_START_ADDR), // parameter data address
      // top
      .fm_top_ddr_addr(CONV_TOP_ADDR), // top data address to write to
      .fm_top_channels(10'd64), // top data channels
      .fm_top_fm_size(30'd32768), // top data fm size
      .fm_top_half_bar_size(30'd1024), // top data half bar size
      //
      .fm_data_ready(tb_load_done), // bottom data and kernel data is ready on ddr -> convolution start
      .fm_start(_fm_start), // conv layer operation start signal
      .fm_conv_done() // current layer convolution done
    );

  // print processing ram
  reg  _fm_print_ram;
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _fm_print_ram <= 1'b0;
    end else begin
      if(_fm_data_valid_last) begin
        _fm_print_ram <= 1'b1;
      end else begin
        _fm_print_ram <= 1'b0;
      end
    end
  end
  // print
  always@(posedge ddr_clk) begin
    if(_fm_print_ram) begin
      $display("%t: procRam:", $realtime);
      printProcRam(_fm_mem_ram, _fm_print_ram);
    end
  end

  always@(posedge ddr_clk or negedge sys_rst_n) begin

    tb_load_done_reg <= tb_load_done;

    if(!sys_rst_n) begin
      _fm_start <= 1'b0;
    end else begin
      if(tb_load_done_rising_edge) begin
        _fm_start <= 1'b1;
        $display("%t: bottom data and param data writing done", $realtime);
      end else begin
        _fm_start <= 1'b0;
      end
    end
  end

endmodule
