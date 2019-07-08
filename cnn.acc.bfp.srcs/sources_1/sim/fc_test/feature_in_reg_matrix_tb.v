/*--------------------------------------------------
 * This module is a testbench for feature_in_reg_matrix.v
 *
 * parameter:
 * EW: exponent width for float
 * MW: mantisa width for float
 * FW: float width
 * US:	unit store size
 * DW:	data width from read_op module
--------------------------------------------------*/
`timescale 1 ns/ 1 ns
module feature_in_reg_matrix_tb;
parameter EW = 8;
parameter MW = 23;
parameter FW = 32;
parameter US = 7;
parameter DW = 512;
`define SEEK_SET 0
`define SEEK_CUR 1
`define	SEEK_END 2

	reg									clk_i;
	reg									rstn_i;

	wire								en_i;
	wire								start_trigger_i;
	wire								first_shot_i;
	wire								sel_w_i;

	wire								sel_top_i;	
	wire	[ (2*US+2)*FW-1:0 ] 		data_top_i;

	wire								sel_ram_i;
	wire	[ (2*US+1)*FW-1:0 ] 		data_ram_i;

	wire								ddr_last_i;
	wire								sel_ddr_i;
	wire								col_last_i;
	wire								row_last_i;
	wire	[ 32-1:0 ]					data_valid_num_i;
	wire	[ DW-1:0 ] 					data_ddr_i;
	wire								read_finish;
	reg		[ DW-1:0 ]					data_ddr_buf;
	
	reg									 sel_r_i;
	reg		[ 8-1:0 ]					 addr_r_i;
	wire	[ 2-1:0	]					 reg_matrix_full;
	wire	[ (2*US+2)*(3*US+1)*FW-1:0 ] test_data_o; 
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
	integer	r;

	/*
	 * initial input clk and reset signal
	*/
	initial
	begin
		$display( "initial input clk and reset signal." );
		#0	rstn_i	<= 1'b1;
			clk_i	<= 1'b0;
		#5	rstn_i	<= 1'b0;
		#10	rstn_i	<= 1'b1;
		forever
			#10	clk_i	<= ~clk_i;
	end
	/*
	 * initial input signal from conv_op
	 * */
	initial
	begin
		#10	sel_r_i = 1'b0;
	end

	/*
	 * initial feature_in_reg_matrix module
	*/
	cnn_mem #
	(
		.FW( FW ),
		.US( US ),
		.DW( DW )
	)
	cnn_mem_U
	(
		.clk_i		( clk_i ),
		.en_i		( en_i  ),
		.rstn_i		( rstn_i ),

		.start_trigger_i	( start_trigger_i ),
		.first_shot_i		( first_shot_i 	  ),
		.sel_w_i			( sel_w_i		  ),

		.sel_top_i			( sel_top_i    	  ),
		.data_top_i			( data_top_i	  ),

		.sel_ram_i			( sel_ram_i	   	  ),
		.data_ram_i			( data_ram_i	  ),

		.sel_ddr_i			( sel_ddr_i	   	  ),
		.ddr_last_i			( ddr_last_i	  ),
		.col_last_i			( col_last_i	  ),
		.row_last_i			( row_last_i	  ),
		.data_valid_num_i	( data_valid_num_i ),
		.data_ddr_i			( data_ddr_i	  ),
		
		.sel_r_i			( sel_r_i		  ),
		.test_data_o		( test_data_o	  ),
		.reg_matrix_full_o	( reg_matrix_full )
	);

	feature_in_reg_matrix_bb #
	(
		.EW(EW),
		.MW(MW),
		.FW(FW),
		.US(US),
		.DW(DW)
	)
	feature_in_reg_matrix_bb_U
	(
		.clk_i( clk_i ),
		.rstn_i( rstn_i ),

		.en_o( en_i ),
		.start_trigger_o( start_trigger_i ),
		.first_shot_o( first_shot_i ),
		.sel_w_o( sel_w_i ),
		
		.sel_top_o( sel_top_i ),
		.data_top_o( data_top_i ),

		.sel_ram_o( sel_ram_i ),
		.data_ram_o( data_ram_i ),

		.sel_ddr_o( sel_ddr_i ),
		.ddr_last_o( ddr_last_i ),
		.col_last_o( col_last_i ),
		.row_last_o( row_last_i ),
		.data_valid_num_o( data_valid_num_i ),
		.data_ddr_o( data_ddr_i ),
		.read_finish_o( read_finish )
	);

	integer file_id;
	always @( reg_matrix_full )
	begin
		if( reg_matrix_full == 2'b01 )
		begin
			file_id = $fopen( "/home/niuyue/focus/2-test/2-data/recon_feature.bin", "r" );

			r = $fseek( file_id, 0, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US+1)*(3*US)*FW-1:(2*US)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US)*(3*US)*FW-1:(2*US-1)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 2*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-1)*(3*US)*FW-1:(2*US-2)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 3*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-2)*(3*US)*FW-1:(2*US-3)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 4*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-3)*(3*US)*FW-1:(2*US-4)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 5*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-4)*(3*US)*FW-1:(2*US-5)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 6*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-5)*(3*US)*FW-1:(2*US-6)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 7*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-6)*(3*US)*FW-1:(2*US-7)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 8*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-7)*(3*US)*FW-1:(2*US-8)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 9*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-8)*(3*US)*FW-1:(2*US-9)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 10*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-9)*(3*US)*FW-1:(2*US-10)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 11*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-10)*(3*US)*FW-1:(2*US-11)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 12*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-11)*(3*US)*FW-1:(2*US-12)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 13*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-12)*(3*US)*FW-1:(2*US-13)*(3*US)*FW ] = test_data_buf;

			r = $fseek( file_id, 14*32*US*FW/8, `SEEK_SET );
			r = $fread( test_data_buf, file_id );
			test_data_compare[ (2*US-13)*(3*US)*FW-1:(2*US-14)*(3*US)*FW ] = test_data_buf;

		end
	end
	/*
	 * compare data
	*/
	integer file_result_id;
	initial
	begin
		file_result_id = $fopen( "simv_display_result.txt" );
	end
	genvar i;
	genvar j;
	generate
		for( i = 0; i < (2*US+1); i = i + 1 )
		begin:compare_data
			for( j = 0; j < (3*US); j = j + 1 )
			begin
				always @( posedge clk_i )
				begin
					if( reg_matrix_full == 2'b01 )
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

	initial
	begin
		#600	$finish;
	end

	/*
	 * dump file
	*/
	initial
	begin
		$vcdplusfile( "sim_result.vpd" );
		$vcdpluson( 0, feature_in_reg_matrix_tb );
		$vcdplusglitchon;
		$vcdplusflush;
	/*
		$dumpfile( "sim_result.vcd" );
		$dumpvars( 0, feature_in_reg_matrix_tb );
	*/
	end

	
	/*
	 * recorde shift process
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


endmodule
