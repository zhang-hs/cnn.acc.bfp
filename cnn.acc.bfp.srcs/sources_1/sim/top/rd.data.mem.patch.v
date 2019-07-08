// ---------------------------------------------------
// File       : rd_ddr_param.tb.v
//
// Description: read bottom data from ddr
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/100fs
`define NULL 0
`define usingDirectC
`ifdef usingDirectC
  // DirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
  extern void     readProcRam(input pointer fileDescriptor, input bit readBottomData,
                              input bit[8:0] xPos, input bit[8:0] yPos, input bit[8:0] xEndPos,
                              input bit[8:0] yEndPos, input bit[29:0] barOffset,
                              input bit[29:0] ithOffset, output bit[15*21*32-1:0] procRam);
                                                      // procRamHeight*procRamWidth*floatNum -1 : 0

  extern bit      cmpFloatNum(input bit dataValid, input bit[4:0] numOfValidData,
                              input bit[511:0] data, input bit[15*21*32-1:0] Ram,
                              input bit[8:0] cnt,  input bit[8:0] xPos,
                              input bit[8:0] yPos, input bit[9:0] ithFM); // compare float num data

//extern void     readControl(input bit dataFullOrLoadingDone, output bit readBottomData,
//                            inout bit[29:0] bottomDataAddr, inout bit[8:0] xEndPos,
//                            inout bit[8:0] yEndPos, inout bit[8:0] xPos, inout bit[8:0] yPos,
//                            output bit isFirstFM, inout bit[29:0] ithOffset, inout bit[9:0] ithFM,
//                            output bit readEnd); // control reading process
  extern void     readControl(input bit loadingDone, input bit dataFull, output bit readBottomData,
                              inout bit[29:0] bottomDataAddr, input bit[8:0] xEndPos,
                              input bit[8:0] yEndPos, inout bit[8:0] xPos, inout bit[8:0] yPos,
                              output bit isFirstFM, inout bit[29:0] ithOffset, inout bit[29:0] barOffset,
                              inout bit[9:0] ithFM, output bit readEnd); // control reading process
`endif
module top;
   //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   parameter SIMULATION            = "TRUE";
   parameter PORT_MODE             = "BI_MODE";
   parameter DATA_MODE             = 4'b0010;
   parameter TST_MEM_INSTR_MODE    = "R_W_INSTR_MODE";
   parameter EYE_TEST              = "FALSE";
                                     // set EYE_TEST = "TRUE" to probe memory
                                     // signals. Traffic Generator will only
                                     // write to one single location and no
                                     // read transactions will be generated.
   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter COL_WIDTH             = 10;
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1;
                                     // # of unique CS outputs to memory.
   parameter DM_WIDTH              = 8;
                                     // # of DM (data mask)
   parameter DQ_WIDTH              = 64;
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 8;
   parameter DQS_CNT_WIDTH         = 3;
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8;
                                     // # of DQ per DQS
   parameter ECC                   = "OFF";
   parameter RANKS                 = 1;
                                     // # of Ranks.
   parameter ODT_WIDTH             = 1;
                                     // # of ODT outputs to memory.
   parameter ROW_WIDTH             = 16;
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 30;
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_MODE            = "8";
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   parameter CA_MIRROR             = "OFF";
                                     // C/A mirror opt for DDR3 dual rank
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5; // 5000 ps
                                     // Input Clock Period


   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIM_BYPASS_INIT_CAL   = "FAST";
                                     // # = "SIM_INIT_CAL_FULL" -  Complete
                                     //              memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter TCQ                   = 0.100; // 100 ps
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter RST_ACT_LOW           = 0;
                                     // =1 for active low reset,
                                     // =0 for active high.

   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   parameter REFCLK_FREQ           = 200.0; // 200 MHz
                                     // IODELAYCTRL reference clock frequency
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter tCK                   = 1.250;  // 1250 ps
                                     // memory tCK paramter.
                     // # = Clock Period in pS.
   parameter nCK_PER_CLK           = 4;
                                     // # of memory CKs per fabric CLK
   //***************************************************************************
   // Debug and Internal parameters
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF";
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
   //***************************************************************************
   // Debug and Internal parameters
   //***************************************************************************
   parameter DRAM_TYPE             = "DDR3";
  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//

  localparam real TPROP_DQS          = 0.00;
                                       // Delay for DQS signal during Write Operation
  localparam real TPROP_DQS_RD       = 0.00;
                       // Delay for DQS signal during Read Operation
  localparam real TPROP_PCB_CTRL     = 0.00;
                       // Delay for Address and Ctrl signals
  localparam real TPROP_PCB_DATA     = 0.00;
                       // Delay for data signal during Write operation
  localparam real TPROP_PCB_DATA_RD  = 0.00;
                       // Delay for data signal during Read operation

  localparam MEMORY_WIDTH            = 8;
  localparam NUM_COMP                = DQ_WIDTH/MEMORY_WIDTH;
  localparam ECC_TEST                            = "OFF" ;
  localparam ERR_INSERT = (ECC_TEST == "ON") ? "OFF" : ECC ;

  localparam real REFCLK_PERIOD = (1000.0/(2*REFCLK_FREQ)); // ps: (1000000.0/(2*REFCLK_FREQ));
  localparam RESET_PERIOD = 200; // 200,000 ps
    
  //**************************************************************************//
  // Wire Declarations
  //**************************************************************************//
  reg                               sys_rst_n;
  wire                              sys_rst;

  reg                               sys_clk_i;
  wire                              sys_clk_p;
  wire                              sys_clk_n;

  reg                               clk_ref_i;
  
  wire                              ddr3_reset_n;
  wire [DQ_WIDTH-1:0]               ddr3_dq_fpga;
  wire [DQS_WIDTH-1:0]              ddr3_dqs_p_fpga;
  wire [DQS_WIDTH-1:0]              ddr3_dqs_n_fpga;
  wire [ROW_WIDTH-1:0]              ddr3_addr_fpga;
  wire [3-1:0]                      ddr3_ba_fpga;
  wire                              ddr3_ras_n_fpga;
  wire                              ddr3_cas_n_fpga;
  wire                              ddr3_we_n_fpga;
  wire [1-1:0]                      ddr3_cke_fpga;
  wire [1-1:0]                      ddr3_ck_p_fpga;
  wire [1-1:0]                      ddr3_ck_n_fpga;
  
  wire                              init_calib_complete;
  wire                              tg_compare_error;
  wire [(CS_WIDTH*1)-1:0]           ddr3_cs_n_fpga;
    
  wire [DM_WIDTH-1:0]               ddr3_dm_fpga;
    
  wire [ODT_WIDTH-1:0]              ddr3_odt_fpga;
  
  reg [(CS_WIDTH*1)-1:0]            ddr3_cs_n_sdram_tmp;
    
  reg [DM_WIDTH-1:0]                ddr3_dm_sdram_tmp;
    
  reg [ODT_WIDTH-1:0]               ddr3_odt_sdram_tmp;

  wire [DQ_WIDTH-1:0]               ddr3_dq_sdram;
  reg [ROW_WIDTH-1:0]               ddr3_addr_sdram [0:1];
  reg [3-1:0]                       ddr3_ba_sdram [0:1];
  reg                               ddr3_ras_n_sdram;
  reg                               ddr3_cas_n_sdram;
  reg                               ddr3_we_n_sdram;
  wire [(CS_WIDTH*1)-1:0]           ddr3_cs_n_sdram;
  wire [ODT_WIDTH-1:0]              ddr3_odt_sdram;
  reg [1-1:0]                       ddr3_cke_sdram;
  wire [DM_WIDTH-1:0]               ddr3_dm_sdram;
  wire [DQS_WIDTH-1:0]              ddr3_dqs_p_sdram;
  wire [DQS_WIDTH-1:0]              ddr3_dqs_n_sdram;
  reg [1-1:0]                       ddr3_ck_p_sdram;
  reg [1-1:0]                       ddr3_ck_n_sdram;

  //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
  initial begin
    sys_rst_n = 1'b1;
    #10
    sys_rst_n = 1'b0;
    #RESET_PERIOD
    sys_rst_n = 1'b1;
  end

  assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  //**************************************************************************//
  // Clock Generation
  //**************************************************************************//
  initial
    sys_clk_i = 1'b0;
  always
    sys_clk_i = #(CLKIN_PERIOD/2.0) ~sys_clk_i;

  assign sys_clk_p = sys_clk_i;
  assign sys_clk_n = ~sys_clk_i;

  initial
    clk_ref_i = 1'b0;
  always
    clk_ref_i = #REFCLK_PERIOD ~clk_ref_i;

  always @( * ) begin
    ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
    ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
    ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_addr_fpga[ROW_WIDTH-1:9],
                                                  ddr3_addr_fpga[7], ddr3_addr_fpga[8],
                                                  ddr3_addr_fpga[5], ddr3_addr_fpga[6],
                                                  ddr3_addr_fpga[3], ddr3_addr_fpga[4],
                                                  ddr3_addr_fpga[2:0]} :
                                                 ddr3_addr_fpga;
    ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) (CA_MIRROR == "ON") ?
                                                 {ddr3_ba_fpga[3-1:2],
                                                  ddr3_ba_fpga[0],
                                                  ddr3_ba_fpga[1]} :
                                                 ddr3_ba_fpga;
    ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
    ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
    ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
    ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
  end

  always @( * )
    ddr3_cs_n_sdram_tmp   <=  #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;
  assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;

  always @( * )
    ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
  assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;

  always @( * )
    ddr3_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;
  assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;

  // Controlling the bi-directional BUS
  genvar dqwd;
  generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
      (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
      )
      u_delay_dq
      (
        .A             (ddr3_dq_fpga[dqwd]),
        .B             (ddr3_dq_sdram[dqwd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
      );
    end
    // For ECC ON case error is inserted on LSB bit from DRAM to FPGA
      WireDelay #
      (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT (ERR_INSERT)
      )
      u_delay_dq_0
      (
        .A             (ddr3_dq_fpga[0]),
        .B             (ddr3_dq_sdram[0]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
      );
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
      (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
      )
      u_delay_dqs_p
      (
        .A             (ddr3_dqs_p_fpga[dqswd]),
        .B             (ddr3_dqs_p_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
      );

      WireDelay #
      (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
      )
      u_delay_dqs_n
      (
        .A             (ddr3_dqs_n_fpga[dqswd]),
        .B             (ddr3_dqs_n_sdram[dqswd]),
        .reset         (sys_rst_n),
        .phy_init_done (init_calib_complete)
      );
    end
  endgenerate

  //**************************************************************************//
  // Memory Models instantiations
  //**************************************************************************//
  genvar r,i;
  generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
        ddr3_model u_comp_ddr3
          (
           .rst_n   (ddr3_reset_n),
           .ck      (ddr3_ck_p_sdram[(i*MEMORY_WIDTH)/72]),
           .ck_n    (ddr3_ck_n_sdram[(i*MEMORY_WIDTH)/72]),
           .cke     (ddr3_cke_sdram[((i*MEMORY_WIDTH)/72)+(1*r)]),
           .cs_n    (ddr3_cs_n_sdram[((i*MEMORY_WIDTH)/72)+(1*r)]),
           .ras_n   (ddr3_ras_n_sdram),
           .cas_n   (ddr3_cas_n_sdram),
           .we_n    (ddr3_we_n_sdram),
           .dm_tdqs (ddr3_dm_sdram[i]),
           .ba      (ddr3_ba_sdram[r]),
           .addr    (ddr3_addr_sdram[r]),
           .dq      (ddr3_dq_sdram[MEMORY_WIDTH*(i+1)-1:MEMORY_WIDTH*(i)]),
           .dqs     (ddr3_dqs_p_sdram[i]),
           .dqs_n   (ddr3_dqs_n_sdram[i]),
           .tdqs_n  (),
           .odt     (ddr3_odt_sdram[((i*MEMORY_WIDTH)/72)+(1*r)])
           );
      end
    end
  endgenerate

  //***************************************************************************
  // Reporting the test case status
  // Status reporting logic exists both in simulation test bench (sim_tb_top)
  // and sim.do file for ModelSim. Any update in simulation run time or time out
  // in this file need to be updated in sim.do file as well.
  //***************************************************************************
  initial
  begin : Logging
    begin : calibration_done
       wait (init_calib_complete);
       $display("%t: Calibration Done", $realtime);
    end
  end

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
          $dumpvars(0, rd_ddr_op_tb);
      `endif
    end
  end

  // ----------------------------------------mig and user design connection----------------------------------------
  // not used
  wire app_sr_active;
  wire app_ref_ack;
  wire app_zq_ack;
  // ddr clock and reset
  wire ddr_clk;
  wire sync_rst;
  // control signal
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
  mig7series mig7(
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr_fpga),  // output [15:0]                ddr3_addr
    .ddr3_ba                        (ddr3_ba_fpga),  // output [2:0]                ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n_fpga),  // output                        ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n_fpga),  // output [0:0]                ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p_fpga),  // output [0:0]                ddr3_ck_p
    .ddr3_cke                       (ddr3_cke_fpga),  // output [0:0]                ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n_fpga),  // output                        ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output                        ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n_fpga),  // output                        ddr3_we_n
    .ddr3_dq                        (ddr3_dq_fpga),  // inout [63:0]                ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n_fpga),  // inout [7:0]                ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p_fpga),  // inout [7:0]                ddr3_dqs_p
    .init_calib_complete            (init_calib_complete),  // output                        init_calib_complete
    .ddr3_cs_n                      (ddr3_cs_n_fpga),  // output [0:0]                ddr3_cs_n
    .ddr3_dm                        (ddr3_dm_fpga),  // output [7:0]                ddr3_dm
    .ddr3_odt                       (ddr3_odt_fpga),  // output [0:0]                ddr3_odt
    // System Clock Ports
    .sys_clk_p                      (sys_clk_p),  // input                                sys_clk_p
    .sys_clk_n                      (sys_clk_n),  // input                                sys_clk_n
    .sys_rst                        (sys_rst), // input sys_rst
    // Application interface ports
    .app_addr                       (ddr_addr),  // input [29:0]                app_addr
    .app_cmd                        (ddr_cmd),  // input [2:0]                app_cmd
    .app_en                         (ddr_en),  // input                                app_en
    .app_rd_data                    (ddr_rd_data),  // output [511:0]                app_rd_data
    .app_rd_data_end                (ddr_rd_data_end),  // output                        app_rd_data_end
    .app_rd_data_valid              (ddr_rd_data_valid),  // output                        app_rd_data_valid
    .app_rdy                        (ddr_rdy),  // output                        app_rdy

    .app_wdf_data                   (app_wdf_data),  // input [511:0]                app_wdf_data
    .app_wdf_mask                   (app_wdf_mask),  // input [63:0]                app_wdf_mask
    .app_wdf_end                    (app_wdf_end),  // input                                app_wdf_end
    .app_wdf_wren                   (app_wdf_wren),  // input                                app_wdf_wren
    .app_wdf_rdy                    (ddr_wdf_rdy),  // output                        app_wdf_rdy
    .app_sr_req                     (1'b0),  // input                        app_sr_req
    .app_ref_req                    (1'b0),  // input                        app_ref_req
    .app_zq_req                     (1'b0),  // input                        app_zq_req
    .app_sr_active                  (app_sr_active),  // output                        app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output                        app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output                        app_zq_ack
    .ui_clk                         (ddr_clk),  // output                        ui_clk
    .ui_clk_sync_rst                (sync_rst)  // output                        ui_clk_sync_rst
    );
  // ----------------------------------------mig and user design connection----------------------------------------

  // open file
  localparam EXP = 8;
  localparam MAN = 23;
  integer fd_data, fd_result;
  integer char_count, data_count, count;
  reg [EXP+MAN:0] ker1;
  reg [EXP+MAN:0] ker2;
  reg [EXP+MAN:0] ker3;
  reg [EXP+MAN:0] data01,data02,data03,data04,data05,data06,data07,data08,
                  data09,data10,data11,data12,data13,data14,data15,data16;
  reg [EXP+MAN:0] bias;
  reg [EXP+MAN:0] result;
  reg             _next_wr;
  reg             _next_rd;
  reg             tb_load_done;

  initial begin
    fd_data = getFileDescriptor("../../data/data.tb.bin");
    char_count = 0;
    data_count = 0;
    if(fd_data == `NULL) begin
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
  end

  // read from file
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if((sys_rst_n) && init_calib_complete) begin
      if(_next_wr) begin
        // data
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
    end
  end
  // write to ddr3 model
  localparam TB_RST = 2'b0;
  localparam TB_WR  = 2'b1;
  localparam TB_RD  = 2'b10;
  localparam WR_END_ADDR = 30'h125f8; // 30'h61f8; (fm_width*fm_height)*float_num_bit/ddr_data_width - ddr_burst_size
  localparam WR_ADDR_STRIDE = 4'd8;
  reg  [1:0]    _rdwr_state;
  reg  [1:0]    _next_state;
  reg  [29:0]   _wr_addr;
  reg  [29:0]   _rd_addr;
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
  always@(_rdwr_state or init_calib_complete or _wr_addr or _rd_addr) begin
    _next_state= TB_RST;
    case(_rdwr_state)
      TB_RST: begin
        if(init_calib_complete && !tb_load_done)
          _next_state = TB_WR;
        else
          _next_state = TB_RST;
      end
      TB_WR: begin
        if(_wr_addr == WR_END_ADDR)
          _next_state = TB_RST;
        else
          _next_state = TB_WR;
      end
    endcase
  end
  // logic
  always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_addr or _rd_addr or
          data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
          data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16
         ) begin
    _next_wr = 1'b0;
    _next_rd = 1'b0;
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
      TB_WR: begin
        if(ddr_rdy && ddr_wdf_rdy) begin
          app_en    = 1'b1;
          app_cmd   = 3'b0;
          app_addr  = _wr_addr;
          app_wdf_mask  = 64'b0; // no mask
          app_wdf_data  = {data01,data02,data03,data04,
                           data05,data06,data07,data08,
                           data09,data10,data11,data12,
                           data13,data14,data15,data16};
          app_wdf_wren  = 1'b1;
          app_wdf_end   = 1'b1;
          if(_wr_addr == WR_END_ADDR) begin
            _next_wr  = 1'b0;
          end else begin
            _next_wr  = 1'b1;
          end
        end
      end
    endcase
  end

  always@(posedge ddr_clk) begin
    if(sync_rst) begin
      _wr_addr <= 30'b0;
      _rd_addr <= 30'b0;
      tb_load_done <= 1'b0;
    end else begin
      if(_next_wr) begin
        _wr_addr <= _wr_addr + WR_ADDR_STRIDE;
      end
      if(_wr_addr == WR_END_ADDR) begin
        tb_load_done <= 1'b1;
        //$finish; // any operation on address 12'hc40 will be terminated
      end
    end
  end

  // read ddr port
  wire          rd_ddr_en;
  wire [2:0]    rd_ddr_cmd;
  wire [29:0]   rd_ddr_addr;
  wire          rd_data_valid;
  wire [4:0]    rd_data_num_valid;
  wire          rd_data_full;
  wire [511:0]  rd_data_data;
  wire [31:0]   rd_data_data01,rd_data_data02,rd_data_data03,rd_data_data04,rd_data_data05,rd_data_data06,rd_data_data07,rd_data_data08,
                rd_data_data09,rd_data_data10,rd_data_data11,rd_data_data12,rd_data_data13,rd_data_data14,rd_data_data15,rd_data_data16;
  reg           rd_data_bottom;
  reg  [29:0]   rd_data_bottom_addr;
  reg  [8:0]    rd_data_x;
  reg  [8:0]    rd_data_y;
  reg           rd_data_first_fm;
  reg  [29:0]   rd_data_bottom_ith_offset;
  reg  [29:0]   rd_data_bar_offset;
  wire          rd_data_load_ddr_done_rising_edge;
  reg           rd_data_load_ddr_done_reg;
  localparam    ENDOFX = 16-1;
  localparam    ENDOFY = 16-1;
  reg  [15*21*32-1:0] procRAM; // procRamHeight*procRamWidth(for rd_ddr_data.v)*floatNumWidth - 1 : 0

  assign rd_data_data01 = rd_data_data[511:480]; assign rd_data_data02 = rd_data_data[479:448];
  assign rd_data_data03 = rd_data_data[447:416]; assign rd_data_data04 = rd_data_data[415:384];
  assign rd_data_data05 = rd_data_data[383:352]; assign rd_data_data06 = rd_data_data[351:320];
  assign rd_data_data07 = rd_data_data[319:288]; assign rd_data_data08 = rd_data_data[287:256];
  assign rd_data_data09 = rd_data_data[255:224]; assign rd_data_data10 = rd_data_data[223:192];
  assign rd_data_data11 = rd_data_data[191:160]; assign rd_data_data12 = rd_data_data[159:128];
  assign rd_data_data13 = rd_data_data[127:96];  assign rd_data_data14 = rd_data_data[95:64];
  assign rd_data_data15 = rd_data_data[63:32];   assign rd_data_data16 = rd_data_data[31:0];

  assign ddr_en   = tb_load_done ? rd_ddr_en   : app_en;
  assign ddr_cmd  = tb_load_done ? rd_ddr_cmd  : app_cmd;
  assign ddr_addr = tb_load_done ? rd_ddr_addr : app_addr;

  rd_ddr_data rd_data(
      .clk(ddr_clk),
      .rst_n(sys_rst_n),
      .ddr_rd_data(ddr_rd_data),
      .ddr_rd_data_valid(ddr_rd_data_valid),
      .ddr_rdy(ddr_rdy),
      .ddr_addr(rd_ddr_addr),
      .ddr_cmd(rd_ddr_cmd),
      .ddr_en(rd_ddr_en),

      .rd_data_bottom(rd_data_bottom),
      .rd_data_bottom_addr(rd_data_bottom_addr),
      .rd_data_end_of_x(ENDOFX),
      .rd_data_end_of_y(ENDOFY),
      .rd_data_x(rd_data_x),
      .rd_data_y(rd_data_y),
      .rd_data_first_fm(rd_data_first_fm),
      .rd_data_bottom_ith_offset(rd_data_bottom_ith_offset),
      .rd_data_bar_offset(rd_data_bar_offset),
      .rd_data_data(rd_data_data),
      .rd_data_num_valid(rd_data_num_valid),
      .rd_data_valid(rd_data_valid),
      .rd_data_full(rd_data_full)
    );

  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      rd_data_load_ddr_done_reg <= 1'b0;
    end else begin
      rd_data_load_ddr_done_reg <= tb_load_done;
    end
  end

  assign rd_data_load_ddr_done_rising_edge = ((!rd_data_load_ddr_done_reg) && tb_load_done);

  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(rd_data_load_ddr_done_rising_edge) begin
      $display("%t: param writing done", $realtime);
    end
  end

  // control
  reg [9:0]   ithFM;
  reg         readEnd;
  wire        loadingDone;
  assign      loadingDone = rd_data_load_ddr_done_rising_edge;
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      rd_data_bottom            <= 1'b0;
      rd_data_bottom_addr       <= 30'h0;
      rd_data_x                 <= 9'h0;
      rd_data_y                 <= 9'h0;
      rd_data_first_fm          <= 1'b0;
      rd_data_bottom_ith_offset <= 30'h0;
      rd_data_bar_offset        <= 30'h0;
      ithFM                     <= 10'h0;
      readEnd                   <= 1'b0;
    end else begin
      if(tb_load_done) begin
        if(rd_data_full || loadingDone) begin
          readControl(loadingDone, rd_data_full, rd_data_bottom, rd_data_bottom_addr,
                      ENDOFX, ENDOFY, rd_data_x, rd_data_y, rd_data_first_fm,
                      rd_data_bottom_ith_offset, rd_data_bar_offset, ithFM, readEnd);
        end else begin
          rd_data_bottom <= 1'b0;
        end
        readProcRam(fd_data, rd_data_bottom, rd_data_x, rd_data_y,
                    ENDOFX, ENDOFY, rd_data_bar_offset, rd_data_bottom_ith_offset, procRAM);
      end
    //if(rd_data_x==ENDOFX && (rd_data_y==3)) begin
    //  closeFile(fd_data);
    //  $finish;
    //end
    end
  end

  always@(readEnd) begin
    if(readEnd) begin
      closeFile(fd_data);
      $finish;
    end
  end

  // count data
  reg  [8:0]    _data_count;
  reg           _check_pass;
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _data_count <= 9'h0;
    end begin
      if(rd_data_bottom) begin
        _data_count <= 9'h0;
      end else if(rd_data_valid) begin
        _data_count <= _data_count + {5'b0,rd_data_num_valid};
      end
    end
  end
  // compare data
  always@(negedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _check_pass <= 1'b1;
    end else if(rd_data_valid) begin
      _check_pass <=  cmpFloatNum(rd_data_valid, rd_data_num_valid,
                                  // little endian -> big endian
                                  {rd_data_data16,rd_data_data15,rd_data_data14,rd_data_data13,
                                   rd_data_data12,rd_data_data11,rd_data_data10,rd_data_data09,
                                   rd_data_data08,rd_data_data07,rd_data_data06,rd_data_data05,
                                   rd_data_data04,rd_data_data03,rd_data_data02,rd_data_data01},
                                  procRAM, _data_count, rd_data_x, rd_data_y, ithFM);
    end
  end
  // check
  always@(posedge ddr_clk) begin
    if(sys_rst_n) begin
      if(!_check_pass) begin
        closeFile(fd_data);
        $finish;
      end
    end
  end

endmodule
