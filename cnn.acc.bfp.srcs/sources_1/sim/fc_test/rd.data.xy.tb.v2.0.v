// ---------------------------------------------------
// File       : rd.data.xy.tb.v
//
// Description: read bottom data from ddr
//
// Version    : 1.0
// ---------------------------------------------------

// extern C functin for simulation
extern "C" void feature_in_data_check( input int Offset, input int XPos, input int YPos, input bit [9-1:0] FeatureIndex, input bit [] VeriData );

`timescale 1ns/100fs
`define NULL 0
module top;
   	// {{{ parameter definition
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
		$vcdpluson( 0,top );
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
	integer fd_data, fd_ker, fd_bias, fd_result;
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

	initial 
	begin
	  fd_data = $fopen("/home/niuyue/focus/2-test/2-data/feature_map_bend.bin", "r");
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
	  	end
	end
	// }}}

	// write to ddr3 model
	// read from ddr3 model
	// {{{
	localparam TB_RST = 2'b0;
	localparam TB_WR  = 2'b1;
	localparam TB_RD  = 2'b10;
	localparam WR_END_ADDR = 30'd75264; // (fm_width*fm_height)*float_num_bit/ddr_data_width - ddr_burst_size
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
	// state transition {{{
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
	// }}}

	// logic {{{
	always@(_rdwr_state or ddr_rdy or ddr_wdf_rdy or _wr_addr or _rd_addr or
			data01 or data02 or data03 or data04 or data05 or data06 or data07 or data08 or
			data09 or data10 or data11 or data12 or data13 or data14 or data15 or data16
		   ) 
	begin
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
			TB_RST: 
			begin
		  		app_en = 1'b0;
			end
			TB_WR: 
			begin
		  		if(ddr_rdy && ddr_wdf_rdy) 
				begin
					app_en    = 1'b1;
					app_cmd   = 3'b0;
					app_addr  = _wr_addr;
					_next_wr  = 1'b1;
					app_wdf_mask  = 64'b0; // no mask
					app_wdf_data  = {data01,data02,data03,data04,
							 		data05,data06,data07,data08,
							 		data09,data10,data11,data12,
							 		data13,data14,data15,data16};
					app_wdf_wren  = 1'b1;
					app_wdf_end   = 1'b1;
		  		end
			end
	  	endcase
	end

	always@(posedge ddr_clk) 
	begin
	  	if(sync_rst) 
		begin
			_wr_addr <= 30'b0;
			_rd_addr <= 30'b0;
			tb_load_done <= 1'b0;
	  	end 
		else 
		begin
			if(_next_wr) 
			begin
		  		_wr_addr <= _wr_addr + WR_ADDR_STRIDE;
			end
			if(_wr_addr == WR_END_ADDR) 
			begin
		  		tb_load_done <= 1'b1;
		  		$display("%t: param writing done", $realtime);
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
	wire	[ (2*US+2)*(3*US+1)*FW-1:0 ] test_data_o; 
	reg		[ (2*US+2)*(3*US+1)*FW-1:0 ] test_data_reg; 
    wire                                 conv_en;
    wire                                 feature_sel;
    wire    [ 9-1:0 ]                    feature_index_proc;
    wire    [ 9-1:0 ]                    rd_ddr_x_proc;
    wire    [ 9-1:0 ]                    rd_ddr_y_proc;
	wire	[ 9-1:0 ]					 feature_index;
	wire	[ 32-1:0 ]					 x_pos_ddr;
	wire	[ 32-1:0 ]					 y_pos_ddr;
	reg		[ (2*US+1)*(3*US)*FW-1:0 ] 	 test_data_compare;
	reg		[ 3*US*FW-1:0 ]				 test_data_buf;
	wire	[ FW-1:0 ] feature0, feature1, feature2, feature3, feature4, feature5, feature6, feature7, feature8, feature9,
					   feature10, feature11, feature12, feature13, feature14, feature15, feature16, feature17, feature18, feature19,
					   feature20, feature21, feature22, feature23, feature24, feature25, feature26, feature27, feature28, feature29,
					   feature30, feature31, feature32, feature33, feature34, feature35, feature36, feature37, feature38, feature39,
					   feature40, feature41, feature42, feature43, feature44, feature45, feature46, feature47, feature48, feature49,
					   feature50, feature51, feature52, feature53, feature54, feature55, feature56, feature57, feature58, feature59,
					   feature60, feature61, feature62, feature63, feature64, feature65, feature66, feature67, feature68, feature69,
					   feature70, feature71, feature72, feature73, feature74, feature75, feature76, feature77, feature78, feature79,
					   feature80, feature81, feature82, feature83, feature84, feature85, feature86, feature87, feature88, feature89,
					   feature90, feature91, feature92, feature93, feature94, feature95, feature96, feature97, feature98, feature99,
					   feature100, feature101, feature102, feature103, feature104, feature105, feature106, feature107, feature108, feature109,
					   feature110, feature111, feature112, feature113, feature114, feature115, feature116, feature117, feature118, feature119,
					   feature120, feature121, feature122, feature123, feature124, feature125, feature126, feature127, feature128, feature129,
					   feature130, feature131, feature132, feature133, feature134, feature135, feature136, feature137, feature138, feature139,
					   feature140, feature141, feature142, feature143, feature144, feature145, feature146, feature147, feature148, feature149,
					   feature150, feature151, feature152, feature153, feature154, feature155, feature156, feature157, feature158, feature159,
					   feature160, feature161, feature162, feature163, feature164, feature165, feature166, feature167, feature168, feature169,
					   feature170, feature171, feature172, feature173, feature174, feature175, feature176, feature177, feature178, feature179,
					   feature180, feature181, feature182, feature183, feature184, feature185, feature186, feature187, feature188, feature189,
					   feature190, feature191, feature192, feature193, feature194, feature195, feature196, feature197, feature198, feature199,
					   feature200, feature201, feature202, feature203, feature204, feature205, feature206, feature207, feature208, feature209,
					   feature210, feature211, feature212, feature213, feature214, feature215, feature216, feature217, feature218, feature219,
					   feature220, feature221, feature222, feature223, feature224, feature225, feature226, feature227, feature228, feature229,
					   feature230, feature231, feature232, feature233, feature234, feature235, feature236, feature237, feature238, feature239,
					   feature240, feature241, feature242, feature243, feature244, feature245, feature246, feature247, feature248, feature249,
					   feature250, feature251, feature252, feature253, feature254, feature255, feature256, feature257, feature258, feature259,
					   feature260, feature261, feature262, feature263, feature264, feature265, feature266, feature267, feature268, feature269,
					   feature270, feature271, feature272, feature273, feature274, feature275, feature276, feature277, feature278, feature279,
					   feature280, feature281, feature282, feature283, feature284, feature285, feature286, feature287, feature288, feature289,
					   feature290, feature291, feature292, feature293, feature294, feature295, feature296, feature297, feature298, feature299,
					   feature300, feature301, feature302, feature303, feature304, feature305, feature306, feature307, feature308, feature309,
					   feature310, feature311, feature312, feature313, feature314, feature315, feature316, feature317, feature318, feature319,
					   feature320, feature321, feature322, feature323, feature324, feature325, feature326, feature327, feature328, feature329,
					   feature330, feature331, feature332, feature333, feature334, feature335, feature336, feature337, feature338, feature339,
					   feature340, feature341, feature342, feature343, feature344, feature345, feature346, feature347, feature348, feature349,
					   feature350, feature351;
	integer read_num;
	integer exchange_num;
	integer	re;

	assign ddr_en   = tb_load_done ? rd_ddr_en   : app_en;
	assign ddr_cmd  = tb_load_done ? rd_ddr_cmd  : app_cmd;
	assign ddr_addr = tb_load_done ? rd_ddr_addr : app_addr;

	/*
	rd_ddr_data rd_data(
	  // {{{
		.clk(ddr_clk),
		.rst_n(sys_rst_n),
		.ddr_rd_data(ddr_rd_data),
		.ddr_rd_data_valid(ddr_rd_data_valid),
		.ddr_rdy(ddr_rdy),
		.ddr_addr(rd_ddr_addr),
		.ddr_cmd(rd_ddr_cmd),
		.ddr_en(rd_ddr_en),

		.rd_data_bottom(rd_data_bottom),
		.rd_data_end_of_x(ENDOFX),
		.rd_data_end_of_y(ENDOFY),
		.rd_data_x(rd_data_x),
		.rd_data_y(rd_data_y),
		.rd_data_first_fm(1'b1),
		.rd_data_bottom_ith_offset(30'h0),
		.rd_data_bar_offset(32'h620),
		.rd_data_patch_bram_last(1'b1),
		.rd_data_patch_bram_valid(1'b1),
		.rd_data_bram(),
		.rd_data_data(rd_data_data),
		.rd_data_num_valid(),
		.rd_data_valid(rd_data_valid),
		.rd_data_full(rd_data_full)
	  // }}}
	  );
	  */
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
	  .test_data_o							( test_data_o 						)
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

	integer file_id;
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
	*/
	assign feature0 = test_data_o[ 1*FW-1:0*FW ];
	assign feature1 = test_data_o[ 2*FW-1:1*FW ];
	assign feature2 = test_data_o[ 3*FW-1:2*FW ];
	assign feature3 = test_data_o[ 4*FW-1:3*FW ];
	assign feature4 = test_data_o[ 5*FW-1:4*FW ];
	assign feature5 = test_data_o[ 6*FW-1:5*FW ];
	assign feature6 = test_data_o[ 7*FW-1:6*FW ];
	assign feature7 = test_data_o[ 8*FW-1:7*FW ];
	assign feature8 = test_data_o[ 9*FW-1:8*FW ];
	assign feature9 = test_data_o[ 10*FW-1:9*FW ];
	assign feature10 = test_data_o[ 11*FW-1:10*FW ];
	assign feature11 = test_data_o[ 12*FW-1:11*FW ];
	assign feature12 = test_data_o[ 13*FW-1:12*FW ];
	assign feature13 = test_data_o[ 14*FW-1:13*FW ];
	assign feature14 = test_data_o[ 15*FW-1:14*FW ];
	assign feature15 = test_data_o[ 16*FW-1:15*FW ];
	assign feature16 = test_data_o[ 17*FW-1:16*FW ];
	assign feature17 = test_data_o[ 18*FW-1:17*FW ];
	assign feature18 = test_data_o[ 19*FW-1:18*FW ];
	assign feature19 = test_data_o[ 20*FW-1:19*FW ];
	assign feature20 = test_data_o[ 21*FW-1:20*FW ];
	assign feature21 = test_data_o[ 22*FW-1:21*FW ];
	assign feature22 = test_data_o[ 23*FW-1:22*FW ];
	assign feature23 = test_data_o[ 24*FW-1:23*FW ];
	assign feature24 = test_data_o[ 25*FW-1:24*FW ];
	assign feature25 = test_data_o[ 26*FW-1:25*FW ];
	assign feature26 = test_data_o[ 27*FW-1:26*FW ];
	assign feature27 = test_data_o[ 28*FW-1:27*FW ];
	assign feature28 = test_data_o[ 29*FW-1:28*FW ];
	assign feature29 = test_data_o[ 30*FW-1:29*FW ];
	assign feature30 = test_data_o[ 31*FW-1:30*FW ];
	assign feature31 = test_data_o[ 32*FW-1:31*FW ];
	assign feature32 = test_data_o[ 33*FW-1:32*FW ];
	assign feature33 = test_data_o[ 34*FW-1:33*FW ];
	assign feature34 = test_data_o[ 35*FW-1:34*FW ];
	assign feature35 = test_data_o[ 36*FW-1:35*FW ];
	assign feature36 = test_data_o[ 37*FW-1:36*FW ];
	assign feature37 = test_data_o[ 38*FW-1:37*FW ];
	assign feature38 = test_data_o[ 39*FW-1:38*FW ];
	assign feature39 = test_data_o[ 40*FW-1:39*FW ];
	assign feature40 = test_data_o[ 41*FW-1:40*FW ];
	assign feature41 = test_data_o[ 42*FW-1:41*FW ];
	assign feature42 = test_data_o[ 43*FW-1:42*FW ];
	assign feature43 = test_data_o[ 44*FW-1:43*FW ];
	assign feature44 = test_data_o[ 45*FW-1:44*FW ];
	assign feature45 = test_data_o[ 46*FW-1:45*FW ];
	assign feature46 = test_data_o[ 47*FW-1:46*FW ];
	assign feature47 = test_data_o[ 48*FW-1:47*FW ];
	assign feature48 = test_data_o[ 49*FW-1:48*FW ];
	assign feature49 = test_data_o[ 50*FW-1:49*FW ];
	assign feature50 = test_data_o[ 51*FW-1:50*FW ];
	assign feature51 = test_data_o[ 52*FW-1:51*FW ];
	assign feature52 = test_data_o[ 53*FW-1:52*FW ];
	assign feature53 = test_data_o[ 54*FW-1:53*FW ];
	assign feature54 = test_data_o[ 55*FW-1:54*FW ];
	assign feature55 = test_data_o[ 56*FW-1:55*FW ];
	assign feature56 = test_data_o[ 57*FW-1:56*FW ];
	assign feature57 = test_data_o[ 58*FW-1:57*FW ];
	assign feature58 = test_data_o[ 59*FW-1:58*FW ];
	assign feature59 = test_data_o[ 60*FW-1:59*FW ];
	assign feature60 = test_data_o[ 61*FW-1:60*FW ];
	assign feature61 = test_data_o[ 62*FW-1:61*FW ];
	assign feature62 = test_data_o[ 63*FW-1:62*FW ];
	assign feature63 = test_data_o[ 64*FW-1:63*FW ];
	assign feature64 = test_data_o[ 65*FW-1:64*FW ];
	assign feature65 = test_data_o[ 66*FW-1:65*FW ];
	assign feature66 = test_data_o[ 67*FW-1:66*FW ];
	assign feature67 = test_data_o[ 68*FW-1:67*FW ];
	assign feature68 = test_data_o[ 69*FW-1:68*FW ];
	assign feature69 = test_data_o[ 70*FW-1:69*FW ];
	assign feature70 = test_data_o[ 71*FW-1:70*FW ];
	assign feature71 = test_data_o[ 72*FW-1:71*FW ];
	assign feature72 = test_data_o[ 73*FW-1:72*FW ];
	assign feature73 = test_data_o[ 74*FW-1:73*FW ];
	assign feature74 = test_data_o[ 75*FW-1:74*FW ];
	assign feature75 = test_data_o[ 76*FW-1:75*FW ];
	assign feature76 = test_data_o[ 77*FW-1:76*FW ];
	assign feature77 = test_data_o[ 78*FW-1:77*FW ];
	assign feature78 = test_data_o[ 79*FW-1:78*FW ];
	assign feature79 = test_data_o[ 80*FW-1:79*FW ];
	assign feature80 = test_data_o[ 81*FW-1:80*FW ];
	assign feature81 = test_data_o[ 82*FW-1:81*FW ];
	assign feature82 = test_data_o[ 83*FW-1:82*FW ];
	assign feature83 = test_data_o[ 84*FW-1:83*FW ];
	assign feature84 = test_data_o[ 85*FW-1:84*FW ];
	assign feature85 = test_data_o[ 86*FW-1:85*FW ];
	assign feature86 = test_data_o[ 87*FW-1:86*FW ];
	assign feature87 = test_data_o[ 88*FW-1:87*FW ];
	assign feature88 = test_data_o[ 89*FW-1:88*FW ];
	assign feature89 = test_data_o[ 90*FW-1:89*FW ];
	assign feature90 = test_data_o[ 91*FW-1:90*FW ];
	assign feature91 = test_data_o[ 92*FW-1:91*FW ];
	assign feature92 = test_data_o[ 93*FW-1:92*FW ];
	assign feature93 = test_data_o[ 94*FW-1:93*FW ];
	assign feature94 = test_data_o[ 95*FW-1:94*FW ];
	assign feature95 = test_data_o[ 96*FW-1:95*FW ];
	assign feature96 = test_data_o[ 97*FW-1:96*FW ];
	assign feature97 = test_data_o[ 98*FW-1:97*FW ];
	assign feature98 = test_data_o[ 99*FW-1:98*FW ];
	assign feature99 = test_data_o[ 100*FW-1:99*FW ];
	assign feature100 = test_data_o[ 101*FW-1:100*FW ];
	assign feature101 = test_data_o[ 102*FW-1:101*FW ];
	assign feature102 = test_data_o[ 103*FW-1:102*FW ];
	assign feature103 = test_data_o[ 104*FW-1:103*FW ];
	assign feature104 = test_data_o[ 105*FW-1:104*FW ];
	assign feature105 = test_data_o[ 106*FW-1:105*FW ];
	assign feature106 = test_data_o[ 107*FW-1:106*FW ];
	assign feature107 = test_data_o[ 108*FW-1:107*FW ];
	assign feature108 = test_data_o[ 109*FW-1:108*FW ];
	assign feature109 = test_data_o[ 110*FW-1:109*FW ];
	assign feature110 = test_data_o[ 111*FW-1:110*FW ];
	assign feature111 = test_data_o[ 112*FW-1:111*FW ];
	assign feature112 = test_data_o[ 113*FW-1:112*FW ];
	assign feature113 = test_data_o[ 114*FW-1:113*FW ];
	assign feature114 = test_data_o[ 115*FW-1:114*FW ];
	assign feature115 = test_data_o[ 116*FW-1:115*FW ];
	assign feature116 = test_data_o[ 117*FW-1:116*FW ];
	assign feature117 = test_data_o[ 118*FW-1:117*FW ];
	assign feature118 = test_data_o[ 119*FW-1:118*FW ];
	assign feature119 = test_data_o[ 120*FW-1:119*FW ];
	assign feature120 = test_data_o[ 121*FW-1:120*FW ];
	assign feature121 = test_data_o[ 122*FW-1:121*FW ];
	assign feature122 = test_data_o[ 123*FW-1:122*FW ];
	assign feature123 = test_data_o[ 124*FW-1:123*FW ];
	assign feature124 = test_data_o[ 125*FW-1:124*FW ];
	assign feature125 = test_data_o[ 126*FW-1:125*FW ];
	assign feature126 = test_data_o[ 127*FW-1:126*FW ];
	assign feature127 = test_data_o[ 128*FW-1:127*FW ];
	assign feature128 = test_data_o[ 129*FW-1:128*FW ];
	assign feature129 = test_data_o[ 130*FW-1:129*FW ];
	assign feature130 = test_data_o[ 131*FW-1:130*FW ];
	assign feature131 = test_data_o[ 132*FW-1:131*FW ];
	assign feature132 = test_data_o[ 133*FW-1:132*FW ];
	assign feature133 = test_data_o[ 134*FW-1:133*FW ];
	assign feature134 = test_data_o[ 135*FW-1:134*FW ];
	assign feature135 = test_data_o[ 136*FW-1:135*FW ];
	assign feature136 = test_data_o[ 137*FW-1:136*FW ];
	assign feature137 = test_data_o[ 138*FW-1:137*FW ];
	assign feature138 = test_data_o[ 139*FW-1:138*FW ];
	assign feature139 = test_data_o[ 140*FW-1:139*FW ];
	assign feature140 = test_data_o[ 141*FW-1:140*FW ];
	assign feature141 = test_data_o[ 142*FW-1:141*FW ];
	assign feature142 = test_data_o[ 143*FW-1:142*FW ];
	assign feature143 = test_data_o[ 144*FW-1:143*FW ];
	assign feature144 = test_data_o[ 145*FW-1:144*FW ];
	assign feature145 = test_data_o[ 146*FW-1:145*FW ];
	assign feature146 = test_data_o[ 147*FW-1:146*FW ];
	assign feature147 = test_data_o[ 148*FW-1:147*FW ];
	assign feature148 = test_data_o[ 149*FW-1:148*FW ];
	assign feature149 = test_data_o[ 150*FW-1:149*FW ];
	assign feature150 = test_data_o[ 151*FW-1:150*FW ];
	assign feature151 = test_data_o[ 152*FW-1:151*FW ];
	assign feature152 = test_data_o[ 153*FW-1:152*FW ];
	assign feature153 = test_data_o[ 154*FW-1:153*FW ];
	assign feature154 = test_data_o[ 155*FW-1:154*FW ];
	assign feature155 = test_data_o[ 156*FW-1:155*FW ];
	assign feature156 = test_data_o[ 157*FW-1:156*FW ];
	assign feature157 = test_data_o[ 158*FW-1:157*FW ];
	assign feature158 = test_data_o[ 159*FW-1:158*FW ];
	assign feature159 = test_data_o[ 160*FW-1:159*FW ];
	assign feature160 = test_data_o[ 161*FW-1:160*FW ];
	assign feature161 = test_data_o[ 162*FW-1:161*FW ];
	assign feature162 = test_data_o[ 163*FW-1:162*FW ];
	assign feature163 = test_data_o[ 164*FW-1:163*FW ];
	assign feature164 = test_data_o[ 165*FW-1:164*FW ];
	assign feature165 = test_data_o[ 166*FW-1:165*FW ];
	assign feature166 = test_data_o[ 167*FW-1:166*FW ];
	assign feature167 = test_data_o[ 168*FW-1:167*FW ];
	assign feature168 = test_data_o[ 169*FW-1:168*FW ];
	assign feature169 = test_data_o[ 170*FW-1:169*FW ];
	assign feature170 = test_data_o[ 171*FW-1:170*FW ];
	assign feature171 = test_data_o[ 172*FW-1:171*FW ];
	assign feature172 = test_data_o[ 173*FW-1:172*FW ];
	assign feature173 = test_data_o[ 174*FW-1:173*FW ];
	assign feature174 = test_data_o[ 175*FW-1:174*FW ];
	assign feature175 = test_data_o[ 176*FW-1:175*FW ];
	assign feature176 = test_data_o[ 177*FW-1:176*FW ];
	assign feature177 = test_data_o[ 178*FW-1:177*FW ];
	assign feature178 = test_data_o[ 179*FW-1:178*FW ];
	assign feature179 = test_data_o[ 180*FW-1:179*FW ];
	assign feature180 = test_data_o[ 181*FW-1:180*FW ];
	assign feature181 = test_data_o[ 182*FW-1:181*FW ];
	assign feature182 = test_data_o[ 183*FW-1:182*FW ];
	assign feature183 = test_data_o[ 184*FW-1:183*FW ];
	assign feature184 = test_data_o[ 185*FW-1:184*FW ];
	assign feature185 = test_data_o[ 186*FW-1:185*FW ];
	assign feature186 = test_data_o[ 187*FW-1:186*FW ];
	assign feature187 = test_data_o[ 188*FW-1:187*FW ];
	assign feature188 = test_data_o[ 189*FW-1:188*FW ];
	assign feature189 = test_data_o[ 190*FW-1:189*FW ];
	assign feature190 = test_data_o[ 191*FW-1:190*FW ];
	assign feature191 = test_data_o[ 192*FW-1:191*FW ];
	assign feature192 = test_data_o[ 193*FW-1:192*FW ];
	assign feature193 = test_data_o[ 194*FW-1:193*FW ];
	assign feature194 = test_data_o[ 195*FW-1:194*FW ];
	assign feature195 = test_data_o[ 196*FW-1:195*FW ];
	assign feature196 = test_data_o[ 197*FW-1:196*FW ];
	assign feature197 = test_data_o[ 198*FW-1:197*FW ];
	assign feature198 = test_data_o[ 199*FW-1:198*FW ];
	assign feature199 = test_data_o[ 200*FW-1:199*FW ];
	assign feature200 = test_data_o[ 201*FW-1:200*FW ];
	assign feature201 = test_data_o[ 202*FW-1:201*FW ];
	assign feature202 = test_data_o[ 203*FW-1:202*FW ];
	assign feature203 = test_data_o[ 204*FW-1:203*FW ];
	assign feature204 = test_data_o[ 205*FW-1:204*FW ];
	assign feature205 = test_data_o[ 206*FW-1:205*FW ];
	assign feature206 = test_data_o[ 207*FW-1:206*FW ];
	assign feature207 = test_data_o[ 208*FW-1:207*FW ];
	assign feature208 = test_data_o[ 209*FW-1:208*FW ];
	assign feature209 = test_data_o[ 210*FW-1:209*FW ];
	assign feature210 = test_data_o[ 211*FW-1:210*FW ];
	assign feature211 = test_data_o[ 212*FW-1:211*FW ];
	assign feature212 = test_data_o[ 213*FW-1:212*FW ];
	assign feature213 = test_data_o[ 214*FW-1:213*FW ];
	assign feature214 = test_data_o[ 215*FW-1:214*FW ];
	assign feature215 = test_data_o[ 216*FW-1:215*FW ];
	assign feature216 = test_data_o[ 217*FW-1:216*FW ];
	assign feature217 = test_data_o[ 218*FW-1:217*FW ];
	assign feature218 = test_data_o[ 219*FW-1:218*FW ];
	assign feature219 = test_data_o[ 220*FW-1:219*FW ];
	assign feature220 = test_data_o[ 221*FW-1:220*FW ];
	assign feature221 = test_data_o[ 222*FW-1:221*FW ];
	assign feature222 = test_data_o[ 223*FW-1:222*FW ];
	assign feature223 = test_data_o[ 224*FW-1:223*FW ];
	assign feature224 = test_data_o[ 225*FW-1:224*FW ];
	assign feature225 = test_data_o[ 226*FW-1:225*FW ];
	assign feature226 = test_data_o[ 227*FW-1:226*FW ];
	assign feature227 = test_data_o[ 228*FW-1:227*FW ];
	assign feature228 = test_data_o[ 229*FW-1:228*FW ];
	assign feature229 = test_data_o[ 230*FW-1:229*FW ];
	assign feature230 = test_data_o[ 231*FW-1:230*FW ];
	assign feature231 = test_data_o[ 232*FW-1:231*FW ];
	assign feature232 = test_data_o[ 233*FW-1:232*FW ];
	assign feature233 = test_data_o[ 234*FW-1:233*FW ];
	assign feature234 = test_data_o[ 235*FW-1:234*FW ];
	assign feature235 = test_data_o[ 236*FW-1:235*FW ];
	assign feature236 = test_data_o[ 237*FW-1:236*FW ];
	assign feature237 = test_data_o[ 238*FW-1:237*FW ];
	assign feature238 = test_data_o[ 239*FW-1:238*FW ];
	assign feature239 = test_data_o[ 240*FW-1:239*FW ];
	assign feature240 = test_data_o[ 241*FW-1:240*FW ];
	assign feature241 = test_data_o[ 242*FW-1:241*FW ];
	assign feature242 = test_data_o[ 243*FW-1:242*FW ];
	assign feature243 = test_data_o[ 244*FW-1:243*FW ];
	assign feature244 = test_data_o[ 245*FW-1:244*FW ];
	assign feature245 = test_data_o[ 246*FW-1:245*FW ];
	assign feature246 = test_data_o[ 247*FW-1:246*FW ];
	assign feature247 = test_data_o[ 248*FW-1:247*FW ];
	assign feature248 = test_data_o[ 249*FW-1:248*FW ];
	assign feature249 = test_data_o[ 250*FW-1:249*FW ];
	assign feature250 = test_data_o[ 251*FW-1:250*FW ];
	assign feature251 = test_data_o[ 252*FW-1:251*FW ];
	assign feature252 = test_data_o[ 253*FW-1:252*FW ];
	assign feature253 = test_data_o[ 254*FW-1:253*FW ];
	assign feature254 = test_data_o[ 255*FW-1:254*FW ];
	assign feature255 = test_data_o[ 256*FW-1:255*FW ];
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
	  if((rd_ddr_x_proc==30) && (rd_ddr_y_proc==30)) begin
		#100 $finish;
	  end
	end

	// ----------------------------------------mig and user design connection----------------------------------------

endmodule
