/*--------------------------------------------------
 * This module is a testbench for weight_reg_matrix.v
 *
 * parameter:
 * EW: exponent width for float
 * MW: mantisa width for float
 * FW: float width
 * DW: data width from read_op module
 * MS: weight reg matrix size
 * KS: convolution kernel size
--------------------------------------------------*/
`timescale 1 ns/1 ns
module weight_reg_matrix_tb;

parameter EW = 8;
parameter MW = 23;
parameter FW = 32;
parameter DW = 512;
parameter MS = 32;
parameter KS = 3;
localparam	PACKAGE_LEN = DW / FW; // data number in one input data data_i
localparam	MATRIX_LEN	= MS*KS*KS;
localparam 	PACKAGE_NUM = MATRIX_LEN / PACKAGE_LEN;
`define SEEK_SET 0
`define SEEK_CUR 1
`define	SEEK_END 2

	reg		 				en_i;
	reg 	 				clk_i;
	reg 			 		rstn_i;
	reg						sel_w_i;
	reg 	[ DW-1:0 ]		data_i;
	reg						sel_r_i;
	

	wire	[ MATRIX_LEN*FW-1:0 ]	weight;
	reg		[ MATRIX_LEN*FW-1:0 ]	weight_compare;
	wire	[ FW-1:0 ] 		weight0,   weight1,   weight2,   weight3,   weight4,   weight5,   weight6,   weight7,   weight8,   weight9,
							weight10,  weight11,  weight12,  weight13,  weight14,  weight15,  weight16,  weight17,  weight18,  weight19,
							weight20,  weight21,  weight22,  weight23,  weight24,  weight25,  weight26,  weight27,  weight28,  weight29,
							weight30,  weight31,  weight32,  weight33,  weight34,  weight35,  weight36,  weight37,  weight38,  weight39,
							weight40,  weight41,  weight42,  weight43,  weight44,  weight45,  weight46,  weight47,  weight48,  weight49,
							weight50,  weight51,  weight52,  weight53,  weight54,  weight55,  weight56,  weight57,  weight58,  weight59,
							weight60,  weight61,  weight62,  weight63,  weight64;
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
	 * initial enable and data signal
	*/
	initial
	begin
		$display( "initial enable and data signal." );
		#0	en_i 	<= 1'b0;
			sel_r_i	<= 1'b0;
		#50 en_i 	<= 1'b1;
			sel_w_i	<= 1'b0;

		wait( read_num == PACKAGE_NUM )
		begin
			en_i <= 1'b0;
			#20 sel_r_i	<=	~sel_r_i;
			 	sel_w_i	<= 	~sel_w_i;
			#20	en_i <= 1'b1;
		end
		wait( exchange_num == 2 )
		begin
			en_i	<= 1'b0;
			#10 $finish;
		end
	end

	/*
	 * read weight data from parameter file
	*/
	initial
	begin
	end
	integer file_id;
	always @( negedge rstn_i or posedge clk_i )
	begin
		if ( rstn_i == 1'b0 )
		begin
			data_i	<= {DW{1'b0}};
			file_id = $fopen( "../2-test/2-data/param_data_bend.bin", "r" );

			read_num = 0;
			exchange_num = 0;
		end
		else if( en_i == 1'b1 )
		begin
			if( read_num != PACKAGE_NUM )
			begin
				read_num <= read_num + 1;
			end
			else
			begin
				read_num <= 1;
				exchange_num <= exchange_num + 1;
			end
			r = $fread( data_i, file_id );
		end
		if( read_num == PACKAGE_NUM-1 )
		begin
			//en_i <= 1'b0;
			//$fclose( file_id );
			//file_id = $fopen( "../2-test/2-data/param_data_bend.bin","r" );
			r = $fseek( file_id, exchange_num*MATRIX_LEN*FW/8, `SEEK_SET );
			r = $fread( weight_compare, file_id );
			#10;
			if( weight_compare == weight )
				$display( "weight data check \033[31mpassed\033[0m." );
			else
				$display( "weight data check \033[31mfailed\033[0m." );
		end
	end

	/*
	 * dump file
	*/
	initial
	begin
	/*
		$vcdplusfile( "sim_result.vpd" );
		$vcdpluson( 0, weight_reg_matrix_tb );
		$vcdplusglitchon;
		$vcdplusflush;
	*/
		$dumpfile( "sim_result.vcd" );
		$dumpvars( 0, weight_reg_matrix_tb );
	end

	/*
	 * initial weight_reg_matrix module
	*/
	weight_reg_matrix #
	( 
		.EW( EW ),
		.MW( MW ),
		.FW( FW ),
		.DW( DW ),
		.MS( MS ),
		.KS( KS )
	)
	weight_reg_matrix_u 
	(
		.en_i		( en_i 		),
		.clk_i		( clk_i 	),
		.rstn_i		( rstn_i 	),
		.sel_w_i	( sel_w_i 	),
		.data_i		( data_i 	),
		.sel_r_i	( sel_r_i 	),
		.weight_o	( weight 	)
	);
	assign weight0	= weight[ 1*FW-1:0*FW ];
	assign weight1	= weight[ 2*FW-1:1*FW ];
	assign weight2	= weight[ 3*FW-1:2*FW ];
	assign weight3	= weight[ 4*FW-1:3*FW ];
	assign weight4	= weight[ 5*FW-1:4*FW ];
	assign weight5	= weight[ 6*FW-1:5*FW ];
	assign weight6	= weight[ 7*FW-1:6*FW ];
	assign weight7	= weight[ 8*FW-1:7*FW ];
	assign weight8	= weight[ 9*FW-1:8*FW ];
	assign weight9	= weight[ 10*FW-1:9*FW ];
	assign weight10	= weight[ 11*FW-1:10*FW ];
	assign weight11	= weight[ 12*FW-1:11*FW ];
	assign weight12	= weight[ 13*FW-1:12*FW ];
	assign weight13	= weight[ 14*FW-1:13*FW ];
	assign weight14	= weight[ 15*FW-1:14*FW ];
	assign weight15	= weight[ 16*FW-1:15*FW ];
	assign weight16	= weight[ 17*FW-1:16*FW ];
	assign weight17	= weight[ 18*FW-1:17*FW ];
	assign weight18	= weight[ 19*FW-1:18*FW ];
	assign weight19	= weight[ 20*FW-1:19*FW ];
	assign weight20	= weight[ 21*FW-1:20*FW ];
	assign weight21	= weight[ 22*FW-1:21*FW ];
	assign weight22	= weight[ 23*FW-1:22*FW ];
	assign weight23	= weight[ 24*FW-1:23*FW ];
	assign weight24	= weight[ 25*FW-1:24*FW ];
	assign weight25	= weight[ 26*FW-1:25*FW ];
	assign weight26	= weight[ 27*FW-1:26*FW ];
	assign weight27	= weight[ 28*FW-1:27*FW ];
	assign weight28	= weight[ 29*FW-1:28*FW ];
	assign weight29	= weight[ 30*FW-1:29*FW ];
	assign weight30	= weight[ 31*FW-1:30*FW ];
	assign weight31	= weight[ 32*FW-1:31*FW ];
	assign weight32	= weight[ 33*FW-1:32*FW ];
	assign weight33	= weight[ 34*FW-1:33*FW ];
	assign weight34	= weight[ 35*FW-1:34*FW ];
	assign weight35	= weight[ 36*FW-1:35*FW ];
	assign weight36	= weight[ 37*FW-1:36*FW ];
	assign weight37	= weight[ 38*FW-1:37*FW ];
	assign weight38	= weight[ 39*FW-1:38*FW ];
	assign weight39	= weight[ 40*FW-1:39*FW ];
	assign weight40	= weight[ 41*FW-1:40*FW ];
	assign weight41	= weight[ 42*FW-1:41*FW ];
	assign weight42	= weight[ 43*FW-1:42*FW ];
	assign weight43	= weight[ 44*FW-1:43*FW ];
	assign weight44	= weight[ 45*FW-1:44*FW ];
	assign weight45	= weight[ 46*FW-1:45*FW ];
	assign weight46	= weight[ 47*FW-1:46*FW ];
	assign weight47	= weight[ 48*FW-1:47*FW ];
	assign weight48	= weight[ 49*FW-1:48*FW ];
	assign weight49	= weight[ 50*FW-1:49*FW ];
	assign weight50	= weight[ 51*FW-1:50*FW ];
	assign weight51	= weight[ 52*FW-1:51*FW ];
	assign weight52	= weight[ 53*FW-1:52*FW ];
	assign weight53	= weight[ 54*FW-1:53*FW ];
	assign weight54	= weight[ 55*FW-1:54*FW ];
	assign weight55	= weight[ 56*FW-1:55*FW ];
	assign weight56	= weight[ 57*FW-1:56*FW ];
	assign weight57	= weight[ 58*FW-1:57*FW ];
	assign weight58	= weight[ 59*FW-1:58*FW ];
	assign weight59	= weight[ 60*FW-1:59*FW ];
	assign weight60	= weight[ 61*FW-1:60*FW ];
	assign weight61	= weight[ 62*FW-1:61*FW ];
	assign weight62	= weight[ 63*FW-1:62*FW ];
	assign weight63	= weight[ 64*FW-1:63*FW ];
	
endmodule
