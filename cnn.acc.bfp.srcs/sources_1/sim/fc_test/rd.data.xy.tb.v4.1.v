// ---------------------------------------------------
// File       : rd.data.xy.tb.v
//
// Description: read bottom data from ddr
//
// Version    : 1.0
// ---------------------------------------------------

// extern C functin for simulation
extern "C" void feature_in_data_check( input int Offset, input int XPos, input int YPos, input bit [9-1:0] FeatureIndex, input bit [] VeriData );
extern "C" void bias_check( input bit [] BiasData );
extern "C" void weight_check( input int XPos, input int YPos, input bit [12-1:0] WeightSec, input bit [] WeightData );
extern "C" void feature_out_data_check( input int XPos, input int YPos, input bit [] VeriData );

`timescale 1ns/100fs
`define NULL 0
module top;
   	// {{{ paramete1 definition
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
  
	parameter EW = 8;
	parameter MW = 23;
	parameter FW = 32;
	parameter US = 7;
    parameter MS = 32;
    parameter KS = 3;
    parameter RL = 512;
	parameter DW = 512;
	// }}}
	`define SEEK_SET 0
	`define SEEK_CUR 1
	`define	SEEK_END 2
	
	// ddr3 section {{{
	//**************************************************************************//
	// Wire Declarations for ddr3 {{{
	//**************************************************************************//
	reg                               sys_rst_n;
	wire                              sys_rst;

	reg                               sys_ddr_clk;
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
	// }}}

	//**************************************************************************//
	// Reset Generation {{{
	//**************************************************************************//
	initial begin
	  sys_rst_n = 1'b1;
	  #10
	  sys_rst_n = 1'b0;
	  #RESET_PERIOD
	  sys_rst_n = 1'b1;
	end
	// }}}

	assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

	//**************************************************************************//
	// Clock Generation {{{
	//**************************************************************************//
	initial
	  sys_ddr_clk = 1'b0;
	always
	  sys_ddr_clk = #(CLKIN_PERIOD/2.0) ~sys_ddr_clk;

	assign sys_clk_p = sys_ddr_clk;
	assign sys_clk_n = ~sys_ddr_clk;

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
	// }}}

	// Controlling the bi-directional BUS {{{
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
	  // }}}

	genvar dqswd;
	generate // {{{
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
	// }}}

	//**************************************************************************//
	// Memory Models instantiations {{{
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
	// }}}
	// }}}

	//***************************************************************************
	// Reporting the test case status {{{
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
		$vcdplusfile("top.vpd");
		$vcdpluson( 2, 
                    top.cnn_AVS_top_U.update_op_U, 
                    top.cnn_AVS_top_U.cnn_control_U,
                    top.cnn_AVS_top_U.cnn_mem_U.feature_in_reg_matrix_U,
                    top.cnn_AVS_top_U.cnn_conv_op_U,
                    top.cnn_AVS_top_U.cnn_mem_U.feature_out_reg_matrix_U
                  );
		$vcdplusglitchon;
		$vcdplusflush;
	  /*
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
			$vcdpluson( 0,top );
			$vcdplusglitchon;
			$vcdplusflush;
		`else
			// Verilog VC dump
			$dumpfile("top.vcd");
			$dumpvars(0, rd_ddr_op_tb);
		`endif
	  end
	  */
	end
	// }}}

	// ----------------------------------------mig and user design connection----------------------------------------
	// {{{
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
	// }}}
	mig7series mig7(
	  // {{{
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
	  // }}}
	  );

	// open file {{{
	localparam EXP = 8;
	localparam MAN = 23;
	integer fd_data, fd_param, fd_ker, fd_bias, fd_result;
	integer char_count, data_count, count;
	reg [EXP+MAN:0] ker1;
	reg [EXP+MAN:0] ker2;
	reg [EXP+MAN:0] ker3;
	reg [EXP+MAN:0] data01,data02,data03,data04,data05,data06,data07,data08,
					data09,data10,data11,data12,data13,data14,data15,data16;
	reg [EXP+MAN:0] bias;
	reg [EXP+MAN:0] result;
	reg             _next_wr;
    reg             _next_param_wr;
	reg             _next_rd;
	reg             tb_load_done;

	initial 
	begin
	  fd_data  = $fopen("/home/niuyue/focus/2-test/2-data/conv1_bottom_bend.bin", "r");
	  fd_param = $fopen("/home/niuyue/focus/2-test/2-data/param_data_bias_weight_bend.bin", "r");
	  /*
	  fd_ker  = $fopen("../../../data/weight.bin","rb");
	  fd_bias = $fopen("../../../data/bias.bin","rb");
	  fd_result = $fopen("result.bin","wb");
	  char_count = 0;
	  data_count = 0;
	  if((fd_data == `NULL) || (fd_ker == `NULL) ||
		  (fd_bias == `NULL) || (fd_result == `NULL)) begin
		$display("fd handle is NULL\n");
		$finish;
	  end
	  */
	  // data
	  count = $fread(data01,fd_data); char_count = char_count + count;
	  count = $fread(data02,fd_data); char_count = char_count + count;
	  count = $fread(data03,fd_data); char_count = char_count + count;
	  count = $fread(data04,fd_data); char_count = char_count + count;
	  count = $fread(data05,fd_data); char_count = char_count + count;
	  count = $fread(data06,fd_data); char_count = char_count + count;
	  count = $fread(data07,fd_data); char_count = char_count + count;
	  count = $fread(data08,fd_data); char_count = char_count + count;
	  count = $fread(data09,fd_data); char_count = char_count + count;
	  count = $fread(data10,fd_data); char_count = char_count + count;
	  count = $fread(data11,fd_data); char_count = char_count + count;
	  count = $fread(data12,fd_data); char_count = char_count + count;
	  count = $fread(data13,fd_data); char_count = char_count + count;
	  count = $fread(data14,fd_data); char_count = char_count + count;
	  count = $fread(data15,fd_data); char_count = char_count + count;
	  count = $fread(data16,fd_data); char_count = char_count + count;
	end
	// }}}

	// read from file {{{
	always@(posedge ddr_clk or negedge sys_rst_n) 
	begin
	  	if((sys_rst_n) && init_calib_complete) 
		begin
			if(!$feof(fd_data) && _next_wr) 
			begin
				// data
				count = $fread(data01,fd_data); char_count = char_count + count;
				count = $fread(data02,fd_data); char_count = char_count + count;
				count = $fread(data03,fd_data); char_count = char_count + count;
				count = $fread(data04,fd_data); char_count = char_count + count;
				count = $fread(data05,fd_data); char_count = char_count + count;
				count = $fread(data06,fd_data); char_count = char_count + count;
				count = $fread(data07,fd_data); char_count = char_count + count;
				count = $fread(data08,fd_data); char_count = char_count + count;
				count = $fread(data09,fd_data); char_count = char_count + count;
				count = $fread(data10,fd_data); char_count = char_count + count;
				count = $fread(data11,fd_data); char_count = char_count + count;
				count = $fread(data12,fd_data); char_count = char_count + count;
				count = $fread(data13,fd_data); char_count = char_count + count;
				count = $fread(data14,fd_data); char_count = char_count + count;
				count = $fread(data15,fd_data); char_count = char_count + count;
				count = $fread(data16,fd_data); char_count = char_count + count;
			end
			if(!$feof(fd_param) && _next_param_wr) 
			begin
				// data
				count = $fread(data01,fd_param); char_count = char_count + count;
				count = $fread(data02,fd_param); char_count = char_count + count;
				count = $fread(data03,fd_param); char_count = char_count + count;
				count = $fread(data04,fd_param); char_count = char_count + count;
				count = $fread(data05,fd_param); char_count = char_count + count;
				count = $fread(data06,fd_param); char_count = char_count + count;
				count = $fread(data07,fd_param); char_count = char_count + count;
				count = $fread(data08,fd_param); char_count = char_count + count;
				count = $fread(data09,fd_param); char_count = char_count + count;
				count = $fread(data10,fd_param); char_count = char_count + count;
				count = $fread(data11,fd_param); char_count = char_count + count;
				count = $fread(data12,fd_param); char_count = char_count + count;
				count = $fread(data13,fd_param); char_count = char_count + count;
				count = $fread(data14,fd_param); char_count = char_count + count;
				count = $fread(data15,fd_param); char_count = char_count + count;
				count = $fread(data16,fd_param); char_count = char_count + count;
			end
	  	end
	end
	// }}}

	// write to ddr3 model
	// read from ddr3 model
	// {{{
	localparam TB_RST  = 2'b0;
	localparam TB_WR   = 2'b1;
    localparam TB_WR_P = 2'b10;
    localparam TB_IDLE = 2'b11;
	//localparam TB_RD  = 2'b10;
	localparam WR_END_ADDR = 30'd75264; // (fm_width*fm_height)*float_num_bit/ddr_data_width - ddr_burst_size
    localparam WR_PARAM_END_ADDR = 30'd896; // (64+64*3*3*3)*32/64
	localparam WR_ADDR_STRIDE = 4'd8;
	reg  [1:0]    _rdwr_state;
	reg  [1:0]    _next_state;
	reg  [29:0]   _wr_addr;
    reg  [29:0]   _wr_param_addr;
    reg  [29:0]   _wr_param_cnt;
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
	// state transition {{{
	always@(_rdwr_state or init_calib_complete or _wr_addr or _wr_param_cnt or 
            _rd_addr) begin
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
			_next_state = TB_IDLE;
		  else
			_next_state = TB_WR;
		end
        TB_IDLE:
        begin
            _next_state = TB_WR_P;
        end
        TB_WR_P: begin
          if( _wr_param_cnt == WR_PARAM_END_ADDR )
            _next_state = TB_RST;
          else
            _next_state = TB_WR_P;
        end
	  endcase
	end
	// }}}

	// logic {{{
	always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_addr or _wr_param_addr or 
            _rd_addr or
			data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
			data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16
		   ) 
	begin
	  	_next_wr = 1'b0;
        _next_param_wr = 1'b0;
	  	_next_rd = 1'b0;
	  	app_en   = 1'b0;
	  	app_cmd  = 3'b1; // read
	  	app_addr = 30'b0;
	  	app_wdf_wren = 1'b0;
	  	app_wdf_end  = 1'b1;
	  	app_wdf_mask = 64'b0;
	  	app_wdf_data = 512'b0;
	  	case(_rdwr_state)
			TB_RST: 
			begin
		  		app_en = 1'b0;

                _next_wr       = 1'b0;
                _next_param_wr = 1'b0;
			end
			TB_WR: 
			begin
		  		if(ddr_rdy && ddr_wdf_rdy) 
				begin
                    _next_param_wr = 1'b0;
					app_en         = 1'b1;
					app_cmd        = 3'b0;
					app_addr       = _wr_addr;
					_next_wr       = 1'b1;
					app_wdf_mask   = 64'b0; // no mask
					app_wdf_data   = {data01,data02,data03,data04,
							 		 data05,data06,data07,data08,
							 		 data09,data10,data11,data12,
							 		 data13,data14,data15,data16};
					app_wdf_wren   = 1'b1;
					app_wdf_end    = 1'b1;
		  		end
			end
            TB_IDLE:
            begin
                _next_param_wr = 1'b1;
                app_en         = 1'b1;
                app_cmd        = 3'b0;
                app_addr       = _wr_addr;
                _next_wr       = 1'b0;
                app_wdf_mask   = 64'b0; // no mask
                app_wdf_data   = {data01,data02,data03,data04,
                                 data05,data06,data07,data08,
                                 data09,data10,data11,data12,
                                 data13,data14,data15,data16};
                app_wdf_wren   = 1'b1;
                app_wdf_end    = 1'b1;
            end
			TB_WR_P: 
			begin
		  		if(ddr_rdy && ddr_wdf_rdy) 
				begin
                    _next_wr        = 1'b0;
					app_en          = 1'b1;
					app_cmd         = 3'b0;
					app_addr        = _wr_param_addr;
					_next_param_wr  = 1'b1;
					app_wdf_mask    = 64'b0; // no mask
					app_wdf_data    = {data01,data02,data03,data04,
							 		   data05,data06,data07,data08,
							 		   data09,data10,data11,data12,
							 		   data13,data14,data15,data16};
					app_wdf_wren    = 1'b1;
					app_wdf_end     = 1'b1;
		  		end
			end
	  	endcase
	end

	always@(posedge ddr_clk) 
	begin
	  	if(sync_rst) 
		begin
			_wr_addr <= 30'b0;
            _wr_param_addr <= 30'd80000;
            _wr_param_cnt  <= 30'd0;
			_rd_addr <= 30'b0;
			tb_load_done <= 1'b0;
	  	end 
		else 
		begin
			if(_next_wr) 
			begin
		  		_wr_addr <= _wr_addr + WR_ADDR_STRIDE;
			end
            if( _next_param_wr == 1'b1 && _rdwr_state == TB_WR_P )
            begin
                _wr_param_addr <= _wr_param_addr + WR_ADDR_STRIDE;
                _wr_param_cnt  <= _wr_param_cnt + WR_ADDR_STRIDE;
            end
			if(_wr_param_cnt == WR_PARAM_END_ADDR) 
			begin
		  		tb_load_done <= 1'b1;
		  		$display("%t: data and param writing done", $realtime);
		  		//$finish; // any operation on address 12'hc40 will be terminated
			end
	  	end
	end
	// }}}

	// read ddr port
	wire          rd_ddr_en;
	wire [2:0]    rd_ddr_cmd;
	wire [29:0]   rd_ddr_addr;
	wire          rd_data_valid;
	wire          rd_data_full;
	reg           rd_data_bottom;
	wire          rd_data_load_ddr_done_rising_edge;
	reg           rd_data_load_ddr_done_reg;
	localparam    ENDOFX = 16-1;
	localparam    ENDOFY = 16-1;

	wire	[ 2-1:0 ]					 reg_matrix_full;
	wire	[ (2*US+2)*(2*US+2)*FW-1:0 ] test_data_o; 
	reg		[ (2*US+2)*(2*US+2)*FW-1:0 ] test_data_reg; 
    reg     [ MS*KS*KS*FW-1:0 ]          test_weight_reg;
    reg     [ RL*FW-1:0 ]                test_bias_reg;
    wire                                 conv_en;
    wire                                 feature_sel;
    wire    [ 9-1:0 ]                    feature_index_proc;
    wire    [ 9-1:0 ]                    rd_ddr_x_proc;
    wire    [ 9-1:0 ]                    rd_ddr_y_proc;
    reg     [ 9-1:0 ]                    rd_ddr_x_proc_delay;
    reg     [ 9-1:0 ]                    rd_ddr_y_proc_delay;
	wire	[ 9-1:0 ]					 feature_index;
	wire	[ 32-1:0 ]					 x_pos_ddr;
	wire	[ 32-1:0 ]					 y_pos_ddr;
	//reg		[ (2*US+1)*(3*US)*FW-1:0 ] 	 test_data_compare;
    wire                                 last_bias_flag;
    wire    [ RL*FW-1:0 ]                test_bias_data;
    wire    [ 12-1:0 ]                   weight_sec_count;
    wire    [ MS*KS*KS*FW-1:0 ]          test_weight_data;
	wire    [ MS*(2*US*2*US)*FW-1:0 ]	 feature_out_data0;
	wire    [ MS*(2*US*2*US)*FW-1:0 ]	 feature_out_data1;
	reg     [ 2*MS*(2*US*2*US)*FW-1:0 ]	 feature_out_data_reg;
    wire                                 weight_sel;
    wire                                 wr_ddr_en;
    wire                                 cnn_conv_output_last;
	//reg		[ 3*US*FW-1:0 ]				 test_data_buf;
	integer read_num;
	integer exchange_num;
	integer	re;

	assign ddr_en   = tb_load_done ? rd_ddr_en   : app_en;
	assign ddr_cmd  = tb_load_done ? rd_ddr_cmd  : app_cmd;
	assign ddr_addr = tb_load_done ? rd_ddr_addr : app_addr;

	// user top design {{{
	cnn_AVS_top
	cnn_AVS_top_U
	(
	  .clk_i	( ddr_clk 	),
	  .rstn_i	( sys_rst_n ),

	  .ddr_rd_data_i						( ddr_rd_data 		),
	  .ddr_rd_data_valid_i					( ddr_rd_data_valid ),
	  .ddr_rdy_i							( ddr_rdy 			),
	  .ddr_addr_o							( rd_ddr_addr 		),
	  .ddr_cmd_o							( rd_ddr_cmd 		),
	  .ddr_en_o								( rd_ddr_en 		),

	  .reg_matrix_full_o					( reg_matrix_full 					),

	  // simulation ports
	  .tb_load_done_i						( tb_load_done 						),
	  .rd_data_load_ddr_done_rising_edge_i	( rd_data_load_ddr_done_rising_edge ),

      .conv_en_o                            ( conv_en                           ),
      .feature_proc_sel_o                   ( feature_sel                       ),
      .feature_index_proc_o                 ( feature_index_proc                ),
      .rd_ddr_x_proc_o                      ( rd_ddr_x_proc                     ),
      .rd_ddr_y_proc_o                      ( rd_ddr_y_proc                     ),
	  .x_pos_ddr_o							( x_pos_ddr							),
	  .y_pos_ddr_o							( y_pos_ddr							),
	  .feature_index_o						( feature_index						),
	  .test_data_o							( test_data_o 						),
      .last_bias_flag_o                     ( last_bias_flag                    ),
      .test_bias_o                          ( test_bias_data                    ),
      .weight_sec_count_o                   ( weight_sec_count                  ),
      .weight_proc_sel_o                    ( weight_sel                        ),
      .test_weight_o                        ( test_weight_data                  ),
      .feature_out_data0_o                  ( feature_out_data0                 ),
      .feature_out_data1_o                  ( feature_out_data1                 ),
      .cnn_conv_output_last_o               ( cnn_conv_output_last              ),
      .wr_ddr_en_o                          ( wr_ddr_en                         )
	);
	// }}}
	
	/*
	 * compare data {{{
	*/
	integer data_offset;
	integer x_pos_ddr_delay;
	integer y_pos_ddr_delay;
	reg	[ 9-1:0 ] feature_index_delay;
	always @( x_pos_ddr or y_pos_ddr or feature_index or
              rd_ddr_x_proc or rd_ddr_y_proc )
	begin
		if( feature_index == 9'd0 )
		begin
			if( x_pos_ddr == 0 )
			begin
				if( y_pos_ddr !=0 )
				begin
					x_pos_ddr_delay = 30;
					y_pos_ddr_delay = y_pos_ddr - 2;
				end
				else if( y_pos_ddr == 0 )
				begin
					x_pos_ddr_delay = x_pos_ddr;
					y_pos_ddr_delay = y_pos_ddr;
				end
			end
			else
			begin
				x_pos_ddr_delay = x_pos_ddr - 2;
				y_pos_ddr_delay = y_pos_ddr;
			end
			feature_index_delay = 9'd2;
		end
		else
		begin
			feature_index_delay = feature_index - 9'd1;	
			x_pos_ddr_delay = x_pos_ddr;
			y_pos_ddr_delay = y_pos_ddr;
		end

		data_offset	 = (rd_ddr_y_proc* 32 * US * US + (rd_ddr_x_proc) * US)*FW/8;
	end
    
    always @( negedge sys_rst_n or posedge ddr_clk )
    begin
        if( sys_rst_n == 1'b0 )
        begin
            rd_ddr_x_proc_delay <= 9'd0;
            rd_ddr_y_proc_delay <= 9'd0;
        end
        if( wr_ddr_en == 1'b1 )
        begin
            rd_ddr_x_proc_delay <= rd_ddr_x_proc;
            rd_ddr_y_proc_delay <= rd_ddr_y_proc;
        end
    end

	integer file_id;
    always @( posedge ddr_clk )
    begin
        feature_out_data_reg <= { feature_out_data1, feature_out_data0 };
    end
    always @( wr_ddr_en )
    begin
        if( wr_ddr_en == 1'b1 )
        begin
            feature_out_data_check( rd_ddr_x_proc_delay, rd_ddr_y_proc_delay, feature_out_data_reg );
        end
    end
    always @( weight_sel or conv_en )
    begin
        if( conv_en == 1'b1 )
        begin
            #1
            test_weight_reg = test_weight_data;
            weight_check( rd_ddr_x_proc, rd_ddr_y_proc, weight_sec_count, test_weight_reg );
        end
    end
    always @( last_bias_flag )
    begin
        if( last_bias_flag == 1'b1 )
        begin
            #25
            test_bias_reg  = test_bias_data;
            bias_check( test_bias_reg );
        end
    end
	always @( feature_sel or conv_en )
	begin
		if( conv_en == 1'b1 )
		begin
			#2
			test_data_reg = test_data_o;
			feature_in_data_check( data_offset, rd_ddr_x_proc, rd_ddr_y_proc, feature_index_proc, test_data_reg );	

			/*
			file_id = $fopen( "/home/niuyue/focus/2-test/2-data/recon_feature.bin", "r" );

			re = $fseek( file_id, 0+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US+1)*(3*US)*FW-1:(2*US)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US)*(3*US)*FW-1:(2*US-1)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 2*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-1)*(3*US)*FW-1:(2*US-2)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 3*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-2)*(3*US)*FW-1:(2*US-3)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 4*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-3)*(3*US)*FW-1:(2*US-4)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 5*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-4)*(3*US)*FW-1:(2*US-5)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 6*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-5)*(3*US)*FW-1:(2*US-6)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 7*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-6)*(3*US)*FW-1:(2*US-7)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 8*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-7)*(3*US)*FW-1:(2*US-8)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 9*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-8)*(3*US)*FW-1:(2*US-9)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 10*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-9)*(3*US)*FW-1:(2*US-10)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 11*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-10)*(3*US)*FW-1:(2*US-11)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 12*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-11)*(3*US)*FW-1:(2*US-12)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 13*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-12)*(3*US)*FW-1:(2*US-13)*(3*US)*FW ] = test_data_buf;

			re = $fseek( file_id, 14*32*US*FW/8+data_offset, `SEEK_SET );
			re = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-13)*(3*US)*FW-1:(2*US-14)*(3*US)*FW ] = test_data_buf;
			*/

		end
	end
	integer file_result_id;
	initial
	begin
		file_result_id = $fopen( "simv_display_result.txt" );
	end
	//genvar i;
	genvar j;
	/*
	generate
		always @( reg_matrix_full )
		begin
			if( reg_matrix_full == 2'b01 || reg_matrix_full == 2'b10 )
				$fdisplay( file_result_id, "x_position(%d)----y_position(%d)", x_pos_ddr-2, y_pos_ddr );
		end
		for( i = 0; i < (2*US+1); i = i + 1 )
		begin:compare_data
			for( j = 0; j < (3*US); j = j + 1 )
			begin
				always @( posedge ddr_clk )
				begin
					if( reg_matrix_full == 2'b01 || reg_matrix_full == 2'b10 )
					begin
						#10;
						$fdisplay( file_result_id, " test_data_compare(%d)----test_data_o(%d):%x----%x.",
								 (i*(3*US)+j+1)-1,((i+1)*(3*US+1)+(j+1)+1)-1,
								 test_data_compare[ ((2*US-i)*(3*US)+(3*US-1-j)+1)*FW-1:((2*US-i)*(3*US)+(3*US-1-j))*FW ],
								 test_data_o[ ((i+1)*(3*US+1)+(j+1)+1)*FW-1:((i+1)*(3*US+1)+j+1)*FW ]);
						if( test_data_compare[ ((2*US-i)*(3*US)+(3*US-1-j)+1)*FW-1:((2*US-i)*(3*US)+(3*US-1-j))*FW ] == 
							test_data_o[ ((i+1)*(3*US+1)+(j+1)+1)*FW-1:((i+1)*(3*US+1)+j+1)*FW ] )
							$fdisplay( file_result_id, "feature data check passed." );
						else if( test_data_compare[ ((2*US-i)*(3*US)+(3*US-1-j)+1)*FW-1:((2*US-i)*(3*US)+(3*US-1-j))*FW ] != 
								 test_data_o[ ((i+1)*(3*US+1)+(j+1)+1)*FW-1:((i+1)*(3*US+1)+j+1)*FW ] )
							$fdisplay( file_result_id, "feature data check failed." );
					end
				end
			end
		end // end compare_data
	endgenerate
	*/
	// }}}

	/*
	 * recorde shift process{{{
    /*
	assign feature256 = test_data_o[ 257*FW-1:256*FW ];
	assign feature257 = test_data_o[ 258*FW-1:257*FW ];
	assign feature258 = test_data_o[ 259*FW-1:258*FW ];
	assign feature259 = test_data_o[ 260*FW-1:259*FW ];
	assign feature260 = test_data_o[ 261*FW-1:260*FW ];
	assign feature261 = test_data_o[ 262*FW-1:261*FW ];
	assign feature262 = test_data_o[ 263*FW-1:262*FW ];
	assign feature263 = test_data_o[ 264*FW-1:263*FW ];
	assign feature264 = test_data_o[ 265*FW-1:264*FW ];
	assign feature265 = test_data_o[ 266*FW-1:265*FW ];
	assign feature266 = test_data_o[ 267*FW-1:266*FW ];
	assign feature267 = test_data_o[ 268*FW-1:267*FW ];
	assign feature268 = test_data_o[ 269*FW-1:268*FW ];
	assign feature269 = test_data_o[ 270*FW-1:269*FW ];
	assign feature270 = test_data_o[ 271*FW-1:270*FW ];
	assign feature271 = test_data_o[ 272*FW-1:271*FW ];
	assign feature272 = test_data_o[ 273*FW-1:272*FW ];
	assign feature273 = test_data_o[ 274*FW-1:273*FW ];
	assign feature274 = test_data_o[ 275*FW-1:274*FW ];
	assign feature275 = test_data_o[ 276*FW-1:275*FW ];
	assign feature276 = test_data_o[ 277*FW-1:276*FW ];
	assign feature277 = test_data_o[ 278*FW-1:277*FW ];
	assign feature278 = test_data_o[ 279*FW-1:278*FW ];
	assign feature279 = test_data_o[ 280*FW-1:279*FW ];
	assign feature280 = test_data_o[ 281*FW-1:280*FW ];
	assign feature281 = test_data_o[ 282*FW-1:281*FW ];
	assign feature282 = test_data_o[ 283*FW-1:282*FW ];
	assign feature283 = test_data_o[ 284*FW-1:283*FW ];
	assign feature284 = test_data_o[ 285*FW-1:284*FW ];
	assign feature285 = test_data_o[ 286*FW-1:285*FW ];
	assign feature286 = test_data_o[ 287*FW-1:286*FW ];
	assign feature287 = test_data_o[ 288*FW-1:287*FW ];
	assign feature288 = test_data_o[ 289*FW-1:288*FW ];
	assign feature289 = test_data_o[ 290*FW-1:289*FW ];
	assign feature290 = test_data_o[ 291*FW-1:290*FW ];
	assign feature291 = test_data_o[ 292*FW-1:291*FW ];
	assign feature292 = test_data_o[ 293*FW-1:292*FW ];
	assign feature293 = test_data_o[ 294*FW-1:293*FW ];
	assign feature294 = test_data_o[ 295*FW-1:294*FW ];
	assign feature295 = test_data_o[ 296*FW-1:295*FW ];
	assign feature296 = test_data_o[ 297*FW-1:296*FW ];
	assign feature297 = test_data_o[ 298*FW-1:297*FW ];
	assign feature298 = test_data_o[ 299*FW-1:298*FW ];
	assign feature299 = test_data_o[ 300*FW-1:299*FW ];
	assign feature300 = test_data_o[ 301*FW-1:300*FW ];
	assign feature301 = test_data_o[ 302*FW-1:301*FW ];
	assign feature302 = test_data_o[ 303*FW-1:302*FW ];
	assign feature303 = test_data_o[ 304*FW-1:303*FW ];
	assign feature304 = test_data_o[ 305*FW-1:304*FW ];
	assign feature305 = test_data_o[ 306*FW-1:305*FW ];
	assign feature306 = test_data_o[ 307*FW-1:306*FW ];
	assign feature307 = test_data_o[ 308*FW-1:307*FW ];
	assign feature308 = test_data_o[ 309*FW-1:308*FW ];
	assign feature309 = test_data_o[ 310*FW-1:309*FW ];
	assign feature310 = test_data_o[ 311*FW-1:310*FW ];
	assign feature311 = test_data_o[ 312*FW-1:311*FW ];
	assign feature312 = test_data_o[ 313*FW-1:312*FW ];
	assign feature313 = test_data_o[ 314*FW-1:313*FW ];
	assign feature314 = test_data_o[ 315*FW-1:314*FW ];
	assign feature315 = test_data_o[ 316*FW-1:315*FW ];
	assign feature316 = test_data_o[ 317*FW-1:316*FW ];
	assign feature317 = test_data_o[ 318*FW-1:317*FW ];
	assign feature318 = test_data_o[ 319*FW-1:318*FW ];
	assign feature319 = test_data_o[ 320*FW-1:319*FW ];
	assign feature320 = test_data_o[ 321*FW-1:320*FW ];
	assign feature321 = test_data_o[ 322*FW-1:321*FW ];
	assign feature322 = test_data_o[ 323*FW-1:322*FW ];
	assign feature323 = test_data_o[ 324*FW-1:323*FW ];
	assign feature324 = test_data_o[ 325*FW-1:324*FW ];
	assign feature325 = test_data_o[ 326*FW-1:325*FW ];
	assign feature326 = test_data_o[ 327*FW-1:326*FW ];
	assign feature327 = test_data_o[ 328*FW-1:327*FW ];
	assign feature328 = test_data_o[ 329*FW-1:328*FW ];
	assign feature329 = test_data_o[ 330*FW-1:329*FW ];
	assign feature330 = test_data_o[ 331*FW-1:330*FW ];
	assign feature331 = test_data_o[ 332*FW-1:331*FW ];
	assign feature332 = test_data_o[ 333*FW-1:332*FW ];
	assign feature333 = test_data_o[ 334*FW-1:333*FW ];
	assign feature334 = test_data_o[ 335*FW-1:334*FW ];
	assign feature335 = test_data_o[ 336*FW-1:335*FW ];
	assign feature336 = test_data_o[ 337*FW-1:336*FW ];
	assign feature337 = test_data_o[ 338*FW-1:337*FW ];
	assign feature338 = test_data_o[ 339*FW-1:338*FW ];
	assign feature339 = test_data_o[ 340*FW-1:339*FW ];
	assign feature340 = test_data_o[ 341*FW-1:340*FW ];
	assign feature341 = test_data_o[ 342*FW-1:341*FW ];
	assign feature342 = test_data_o[ 343*FW-1:342*FW ];
	assign feature343 = test_data_o[ 344*FW-1:343*FW ];
	assign feature344 = test_data_o[ 345*FW-1:344*FW ];
	assign feature345 = test_data_o[ 346*FW-1:345*FW ];
	assign feature346 = test_data_o[ 347*FW-1:346*FW ];
	assign feature347 = test_data_o[ 348*FW-1:347*FW ];
	assign feature348 = test_data_o[ 349*FW-1:348*FW ];
	assign feature349 = test_data_o[ 350*FW-1:349*FW ];
	assign feature350 = test_data_o[ 351*FW-1:350*FW ];
	assign feature351 = test_data_o[ 352*FW-1:351*FW ];
    */
	// }}}

	always@(posedge ddr_clk or negedge sys_rst_n) begin
	  if(!sys_rst_n) begin
		rd_data_load_ddr_done_reg <= 1'b0;
	  end else begin
		rd_data_load_ddr_done_reg <= tb_load_done;
	  end
	end

	assign rd_data_load_ddr_done_rising_edge = ((!rd_data_load_ddr_done_reg) && tb_load_done);

	always@(posedge ddr_clk or negedge sys_rst_n) begin
	  /*
	  if(!sys_rst_n) begin
		rd_data_x <= 9'h0;
		rd_data_y <= 9'h0;
		rd_data_bottom <= 1'b0;
	  end else begin
		if(tb_load_done) begin
		  if(rd_data_full) begin
			if(rd_data_x == ENDOFX) begin
			  rd_data_x <= 9'h0;
			end else begin
			  rd_data_x <= rd_data_x + 1'b1;
			end
			if(rd_data_y == ENDOFY) begin
			  rd_data_y <= 9'h0;
			end else begin
			  if(rd_data_x == ENDOFX) begin
				rd_data_y <= rd_data_y + 1'b1;
			  end
			end
		  end
		  if(rd_data_load_ddr_done_rising_edge || rd_data_full) begin
			rd_data_bottom <= 1'b1;
		  end else begin
			rd_data_bottom <= 1'b0;
		  end
		end else begin
		  rd_data_bottom <= 1'b0;
		end
	  end
	  */
	  if((rd_ddr_x_proc==30) && (rd_ddr_y_proc==30) && 
         (feature_index_proc==9'd2) && (weight_sec_count==12'd5)) begin
		#20 $finish;
	  end
	end

	// ----------------------------------------mig and user design connection----------------------------------------

endmodule
