// ---------------------------------------------------
// File       : wr.data.tb.v
//
// Description: read bottom data from ddr
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/100fs
`define NULL 0
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

    .app_wdf_data                   (ddr_wdf_data),  // input [511:0]                app_wdf_data
    .app_wdf_mask                   (ddr_wdf_mask),  // input [63:0]                app_wdf_mask
    .app_wdf_end                    (ddr_wdf_end),  // input                                app_wdf_end
    .app_wdf_wren                   (ddr_wdf_wren),  // input                                app_wdf_wren
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

  // parameters
  localparam ATOMIC_H = 14;
  localparam ATOMIC_W = 14;
  localparam KER_C    = 32;
  localparam DATA_WIDTH = 32;
  localparam EXP = 8;
  localparam MAN = 23;

  // channel data
  reg  [DATA_WIDTH-1 : 0] _wr_data[0 : ATOMIC_H*ATOMIC_W-1];
  reg  [DATA_WIDTH-1 : 0] _wr_data_reg;

  // ------------------------- tasks -------------------------
  task TASK_GEN_DATA; // generate data
    input  [8:0] wr_x;
    input  [8:0] wr_y;
    input  [9:0] wr_channel_index;
    reg    [7:0] idx_r;
    reg    [7:0] idx_c;
    reg    [7:0] idx; // entry
    integer i;

    begin
      idx = 0;
      // top left
      for(idx_r=0; idx_r<ATOMIC_H/2; idx_r=idx_r+1) begin
        for(idx_c=0; idx_c<ATOMIC_W/2; idx_c=idx_c+1) begin
          _wr_data[idx_r*ATOMIC_W + idx_c] = {wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]};
          idx = idx+1;
        end
      end
      // top right
      for(idx_r=0; idx_r<ATOMIC_H/2; idx_r=idx_r+1) begin
        for(idx_c=ATOMIC_W/2; idx_c<ATOMIC_W; idx_c=idx_c+1) begin
          _wr_data[idx_r*ATOMIC_W + idx_c] = {wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]};
          idx = idx+1;
        end
      end
      // bottom left
      for(idx_r=ATOMIC_H/2; idx_r<ATOMIC_H; idx_r=idx_r+1) begin
        for(idx_c=0; idx_c<ATOMIC_W/2; idx_c=idx_c+1) begin
          _wr_data[idx_r*ATOMIC_W + idx_c] = {wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]};
          idx = idx+1;
        end
      end
      //
      for(idx_r=ATOMIC_H/2; idx_r<ATOMIC_H; idx_r=idx_r+1) begin
        for(idx_c=ATOMIC_W/2; idx_c<ATOMIC_W; idx_c=idx_c+1) begin
          _wr_data[idx_r*ATOMIC_W + idx_c] = {wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]};
          idx = idx+1;
        end
      end

      _wr_data_reg = {wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]};

      for(i=0; i<ATOMIC_H*ATOMIC_W; i=i+ATOMIC_W) begin
        $display("%t, %.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x_%.32x", $realtime,
                  _wr_data[i+ 0],_wr_data[i+ 1],_wr_data[i+ 2],_wr_data[i+ 3],
                  _wr_data[i+ 4],_wr_data[i+ 5],_wr_data[i+ 6],_wr_data[i+ 7],
                  _wr_data[i+ 8],_wr_data[i+ 9],_wr_data[i+10],_wr_data[i+11],
                  _wr_data[i+12],_wr_data[i+13]);
      end
      $display("%t, %.8x, %.8x, %.8x, %.8x", $realtime, wr_channel_index[7:0], wr_y[7:0], wr_x[7:0], idx[7:0]);
    end

  endtask

  task TASK_WR_CONTROL; // write control
    $display("TASK_WR_CONTROL IS NOT IMPLEMENTED");
  endtask
  // ------------------------- tasks -------------------------
  // ------------------------- read/write -------------------------
  // simulation
  //  rd
  reg  [29:0]   app_addr_rd;
  reg  [2:0]    app_cmd_rd;
  reg           app_en_rd;
  //  wr
  wire [29:0]   app_addr_wr;
  wire [2:0]    app_cmd_wr;
  wire          app_en_wr;
  wire [511:0]  app_wdf_data;
  wire [63:0]   app_wdf_mask;
  wire          app_wdf_end;
  wire          app_wdf_wren;
  reg           tb_wr_done;

  assign ddr_en       = tb_wr_done ? app_en_rd   : app_en_wr;
  assign ddr_cmd      = tb_wr_done ? app_cmd_rd  : app_cmd_wr;
  assign ddr_addr     = tb_wr_done ? app_addr_rd : app_addr_wr;
  assign ddr_wdf_data = tb_wr_done ? {512{1'b1}} : app_wdf_data;
  assign ddr_wdf_mask = tb_wr_done ? {64{1'b1}}  : app_wdf_mask;
  assign ddr_wdf_end  = tb_wr_done ? 1'b0        : app_wdf_end;
  assign ddr_wdf_wren = tb_wr_done ? 1'b0        : app_wdf_wren;

  localparam  WR_TOP_ADDR    = 30'h0; // write address
  localparam  WR_CHANNEL_NUM = 3;
  localparam  WR_END_CHANNEL = WR_CHANNEL_NUM - 1;
  localparam  WR_END_X       = 3;
  localparam  WR_END_Y       = 3;
  localparam  WR_HALF_BAR_SZ = 30'h100; // half bar size, 64*2*num_of_atom_in_bar*data_width/ddr_data_width
  localparam  WR_FM_SZ       = 30'h800; // feature map size, 64*4*num_of_atom_in_bar*num_of_bars*data_width/ddr_data_width

  reg         _wr_data_top;
  reg         _rd_data_top;
  wire [ATOMIC_H*ATOMIC_W*DATA_WIDTH-1 : 0] _wr_data_i;
  reg  [8:0]  _wr_data_x;
  reg  [8:0]  _wr_data_y;
  reg  [9:0]  _wr_channel_idx;
  reg  [8:0]  _gen_data_x;
  reg  [8:0]  _gen_data_y;
  reg  [9:0]  _gen_channel_idx;
  wire        _wr_data_end_of_channel;
  wire        _wr_data_next_channel;
  wire        _wr_data_next_pos; // connect to wr_ddr_data port, move to next position
  assign      _wr_data_end_of_channel = (_wr_channel_idx == WR_END_CHANNEL);
  
  initial begin
    TASK_GEN_DATA(9'h0, 9'h0, 10'h0);
  end

  // channel num
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _wr_channel_idx   <= 10'h0;
      _gen_channel_idx  <= 10'h1; // lead by one
    end else begin
      if(_wr_data_next_channel) begin
        if(_wr_data_end_of_channel && _wr_data_next_pos) begin
          _wr_channel_idx <= 10'h0;
        end else begin
          _wr_channel_idx <= _wr_channel_idx+1;
        end
        if(_gen_channel_idx==WR_END_CHANNEL) begin
          _gen_channel_idx<= 10'h0;
        end else begin
          _gen_channel_idx<= _gen_channel_idx+1;
        end
        TASK_GEN_DATA(_gen_data_x, _gen_data_y, _gen_channel_idx);
      end
    end
  end
  // channel data
  generate
//genvar i;
    for(i=0; i<ATOMIC_H*ATOMIC_W; i=i+ATOMIC_W) begin
      assign _wr_data_i[(ATOMIC_H*ATOMIC_W-i)*DATA_WIDTH-1 : (ATOMIC_H*ATOMIC_W-i-14)*DATA_WIDTH] =
                {_wr_data[i + 0],_wr_data[i + 1],_wr_data[i + 2],_wr_data[i + 3],_wr_data[i + 4],_wr_data[i + 5],_wr_data[i + 6],
                 _wr_data[i + 7],_wr_data[i + 8],_wr_data[i + 9],_wr_data[i +10],_wr_data[i +11],_wr_data[i +12],_wr_data[i +13]};
    end
  endgenerate
  wire [63:0]  _wr_data_1x64_0;
  wire [63:0]  _wr_data_1x64_1;
  assign _wr_data_1x64_0 = _wr_data_i[(ATOMIC_H*ATOMIC_W)*DATA_WIDTH-1-  0: (ATOMIC_H*ATOMIC_W)*DATA_WIDTH- 64];
  assign _wr_data_1x64_1 = _wr_data_i[(ATOMIC_H*ATOMIC_W)*DATA_WIDTH-1- 64: (ATOMIC_H*ATOMIC_W)*DATA_WIDTH-128];
  // position
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _wr_data_x <= 9'h0;
      _wr_data_y <= 9'h0;
      _gen_data_x <= 9'h0; // lead by one
      _gen_data_y <= 9'h0; // lead by one
    end else begin
      if(_wr_data_next_pos) begin
      // wr_data position
        if(_wr_data_x == WR_END_X) begin
          _wr_data_x <= 9'h0;
        end else begin
          _wr_data_x <= _wr_data_x + 1;
        end
        if(_wr_data_x == WR_END_X) begin
          _wr_data_y <= _wr_data_y + 1;
        end
      end
      if(_wr_data_next_channel) begin
        if(_gen_channel_idx==WR_END_CHANNEL) begin
        // gen_data position
          if(_gen_data_x == WR_END_X) begin
            _gen_data_x <= 9'h0;
          end else begin
            _gen_data_x <= _gen_data_x + 1;
          end
          if(_gen_data_x == WR_END_X) begin
            _gen_data_y <= _gen_data_y + 1;
          end
        end
      end
    end
  end
  // write
  reg   init_calib_complete_reg;
  wire  init_done;
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      init_calib_complete_reg <= 1'b0;
    end else begin
      init_calib_complete_reg <= init_calib_complete;
    end
  end
  assign init_done = (init_calib_complete && (!init_calib_complete_reg));
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _wr_data_top <= 1'b0;
      _rd_data_top <= 1'b0;
      tb_wr_done   <= 1'b0;
    end else begin
      if(init_done) begin
        _wr_data_top <= 1'b1;
        $display("%t, initialization finished", $realtime);
      end
      if((_wr_data_y==WR_END_Y) && (_wr_data_x==WR_END_X) && _wr_data_next_pos)  begin
        _wr_data_top <= 1'b0;
        tb_wr_done   <= 1'b1;
      //$finish; // end of data writing
      end
    end
  end
  
  wr_ddr_data wr_data_instance(
    .clk(ddr_clk),
    .rst_n(sys_rst_n),

    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),
    .ddr_wdf_data(app_wdf_data),
    .ddr_wdf_mask(app_wdf_mask),
    .ddr_wdf_end(app_wdf_end),
    .ddr_wdf_wren(app_wdf_wren),
    .ddr_addr(app_addr_wr),
    .ddr_cmd(app_cmd_wr),
    .ddr_en(app_en_wr),

    .wr_data_top(_wr_data_top), // write top data
    .wr_data_top_addr(WR_TOP_ADDR), // writing address
    .wr_data_top_channels(WR_CHANNEL_NUM), // num of top data channels
    .wr_data_data_i(_wr_data_i), // ATOMIC_H*ATOMIC_W*DATA_WIDTH
    .wr_data_x(_wr_data_x), // patch coordinate in the fm
    .wr_data_y(_wr_data_y),
    .wr_data_end_of_x(WR_END_X), // end of position
    .wr_data_end_of_y(WR_END_Y),
  //.wr_data_pooling(), // is pooling layer output
    .wr_data_half_bar_size(WR_HALF_BAR_SZ), // size of half bar
    .wr_data_fm_size(WR_FM_SZ),
  //.wr_data_bar_size(), // size of 1 bar
    .wr_data_next_channel(_wr_data_next_channel), // current channel finished, writing the last datum to ddr
    .wr_data_done(_wr_data_next_pos) // data writing done
  );

  // read data from ddr, write into file
  reg  [3:0]  _wr_data_rd_state;
  reg  [3:0]  _wr_data_rd_next_state;
  reg  [29:0] _rd_data_offset;
  reg  [29:0] _wr_data_rd_addr;
  reg  [29:0] _rd_data_valid_cnt;
  reg         _rd_data_next;
  localparam WR_RD_RST  = 0;
  localparam WR_RD_DATA = 1;
  localparam WR_RD_BURST_STRIDE = 8;
  // (fm_num*end_of_x*end_of_y*mini_num_of_atom*bursts_of_mini_patch*burst_stride)0x1800 - 0x8
  localparam WR_RD_END_ADDR = 30'h17f8;
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _wr_data_rd_state <= WR_RD_RST;
    end else begin
      _wr_data_rd_state <= _wr_data_rd_next_state;
    end
  end
  always@(_wr_data_rd_state or tb_wr_done or _rd_data_offset or ddr_rd_data_valid) begin
    _wr_data_rd_next_state = WR_RD_RST;
    case(_wr_data_rd_state)
      WR_RD_RST: begin
        if(tb_wr_done && (_rd_data_offset!=(WR_RD_END_ADDR+WR_RD_BURST_STRIDE))) begin
          _wr_data_rd_next_state = WR_RD_DATA;
        end else begin
          _wr_data_rd_next_state = WR_RD_RST;
        end
      end
      WR_RD_DATA: begin
        if((_rd_data_offset == WR_RD_END_ADDR) && ddr_rd_data_valid) begin
          _wr_data_rd_next_state = WR_RD_RST;
        end else begin
          _wr_data_rd_next_state = WR_RD_DATA;
        end
      end
    endcase
  end
  always@(_wr_data_rd_state or _rd_data_offset or ddr_rdy) begin
    app_en_rd   = 1'b0;
    app_cmd_rd  = 3'b1; // read
    app_addr_rd = 30'h0;
    _rd_data_next = 1'b0;
    case(_wr_data_rd_state)
      WR_RD_RST: begin
        app_cmd_rd  = 3'b1; // read
      end
      WR_RD_DATA: begin
        if(ddr_rdy) begin
          app_en_rd   = 1'b1;
          app_cmd_rd  = 3'b1; // read
          app_addr_rd = _rd_data_offset;
          _rd_data_next = 1'b1;
        end else begin
          app_en_rd   = 1'b0;
          app_cmd_rd  = 3'b1; // read
          app_addr_rd = _rd_data_offset;
        end
      end
    endcase
  end
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
      _rd_data_offset <= 30'h0;
      _rd_data_valid_cnt <= 30'h0;
    end else begin
      if(_rd_data_next) begin
        _rd_data_offset <= _rd_data_offset + WR_RD_BURST_STRIDE;
      end
      if(ddr_rd_data_valid) begin
        _rd_data_valid_cnt <= _rd_data_valid_cnt + WR_RD_BURST_STRIDE;
      end
      if(_rd_data_valid_cnt == (WR_RD_END_ADDR+WR_RD_BURST_STRIDE)) begin
        $finish;
      end
    //if(_rd_data_offset == (WR_RD_END_ADDR+WR_RD_BURST_STRIDE)) begin
    //  $finish;
    //end
    end
  end
  //  write to file
  integer fd_result;
  initial begin
    fd_result = $fopen("wr.then.rd.bin","wb");
    if(fd_result == `NULL) begin
      $display("fd handle is NULL\n");
      $finish;
    end
  end

  wire [EXP+MAN:0]  data01,data02,data03,data04,data05,data06,data07,data08,
                    data09,data10,data11,data12,data13,data14,data15,data16;
  assign data01 = ddr_rd_data[512-1 -  0: 512- 32];
  assign data02 = ddr_rd_data[512-1 - 32: 512- 64];
  assign data03 = ddr_rd_data[512-1 - 64: 512- 96];
  assign data04 = ddr_rd_data[512-1 - 96: 512-128];
  assign data05 = ddr_rd_data[512-1 -128: 512-160];
  assign data06 = ddr_rd_data[512-1 -160: 512-192];
  assign data07 = ddr_rd_data[512-1 -192: 512-224];
  assign data08 = ddr_rd_data[512-1 -224: 512-256];
  assign data09 = ddr_rd_data[512-1 -256: 512-288];
  assign data10 = ddr_rd_data[512-1 -288: 512-320];
  assign data11 = ddr_rd_data[512-1 -320: 512-352];
  assign data12 = ddr_rd_data[512-1 -352: 512-384];
  assign data13 = ddr_rd_data[512-1 -384: 512-416];
  assign data14 = ddr_rd_data[512-1 -416: 512-448];
  assign data15 = ddr_rd_data[512-1 -448: 512-480];
  assign data16 = ddr_rd_data[512-1 -480: 512-512];
  always@(posedge ddr_clk or negedge sys_rst_n) begin
    if(sys_rst_n) begin
      if(ddr_rd_data_valid) begin
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
      end
    end
  end
  // ------------------------- read/write -------------------------

endmodule
