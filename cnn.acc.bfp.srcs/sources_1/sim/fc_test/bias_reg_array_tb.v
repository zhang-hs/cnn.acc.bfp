/*--------------------------------------------------
 * This module is a testbench for bias_reg_array.v
 *
 * parameter:
 * EW: exponent width for float
 * MW: mantisa width for float
 * FW: float width
 * DW: data width from read_op module
 * RL: register array len
--------------------------------------------------*/
`timescale 1 ns/1 ns
module bias_reg_array_tb;

parameter EW = 8;
parameter MW = 23;
parameter FW = 32;
parameter DW = 512;
parameter RL = 512;
localparam	PACKAGE_LEN = DW / FW; // data number in one input data data_i
localparam 	PACKAGE_NUM = RL / PACKAGE_LEN;
`define SEEK_SET 0
`define SEEK_CUR 1
`define	SEEK_END 2

	reg						last_data_i;
	reg		[ 1-1:0 ] 		en_i;
	reg 	[ 1-1:0 ] 		clk_i;
	reg 	[ 1-1:0 ] 		rstn_i;
	reg 	[ DW-1:0 ]		data_i;

	wire	[ RL*FW-1:0 ]	bias;
	reg		[ RL*FW-1:0 ]	bias_compare;
	wire	[ FW-1:0 ] 		bias0,   bias1,   bias2,   bias3,   bias4,   bias5,   bias6,   bias7,   bias8,   bias9,
							bias10,  bias11,  bias12,  bias13,  bias14,  bias15,  bias16,  bias17,  bias18,  bias19,
							bias20,  bias21,  bias22,  bias23,  bias24,  bias25,  bias26,  bias27,  bias28,  bias29,
							bias30,  bias31,  bias32,  bias33,  bias34,  bias35,  bias36,  bias37,  bias38,  bias39,
							bias40,  bias41,  bias42,  bias43,  bias44,  bias45,  bias46,  bias47,  bias48,  bias49,
							bias50,  bias51,  bias52,  bias53,  bias54,  bias55,  bias56,  bias57,  bias58,  bias59,
							bias60,  bias61,  bias62,  bias63,  bias64;
	integer read_num;


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
		#0	en_i <= 1'b0;
		#50 en_i <= 1'b1;

		wait( read_num == PACKAGE_NUM-1 )
			last_data_i	<= 1'b1;
		wait( read_num == PACKAGE_NUM )
			en_i 		<= 1'b0;
	end

	/*
	 * read bias data from parameter file
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
		end
		else if( en_i == 1'b1 )
		begin
			if( read_num != PACKAGE_NUM )
			begin
				read_num <= read_num + 1;
			end
			$fread( data_i, file_id );
		end
		if( read_num == PACKAGE_NUM-1 )
		begin
			//en_i <= 1'b0;
			$fclose( file_id );
			file_id = $fopen( "../2-test/2-data/param_data_bend.bin","r" );
			$fread( bias_compare, file_id );
			#10;
			if( bias_compare == bias )
				$display( "bias data check \033[31mpassed\033[0m." );
			else
				$display( "bias data check \033[31mfailed\033[0m." );
			#10 $finish;
		end
	end

	/*
	 * dump file
	*/
	initial
	begin
	/*
		$vcdplusfile( "sim_result.vpd" );
		$vcdpluson( 0, bias_reg_array_tb );
		$vcdplusglitchon;
		$vcdplusflush;
	*/
		$dumpfile( "sim_result.vcd" );
		$dumpvars( 0, bias_reg_array_tb );
	end

	/*
	 * initial bias_reg_array module
	*/
	bias_reg_array #
	( 
		.EW( EW ),
		.MW( MW ),
		.FW( FW ),
		.DW( DW ),
		.RL( RL ) 
	)
	bias_reg_array_u 
	(
		.en_i		( en_i 		 	),
		.last_data_i( last_data_i	),
		.clk_i		( clk_i 		),
		.rstn_i		( rstn_i 		),
		.data_i		( data_i 		),
		.bias_o		( bias 			)
	);
	assign bias0	= bias[ 1*FW-1:0*FW ];
	assign bias1	= bias[ 2*FW-1:1*FW ];
	assign bias2	= bias[ 3*FW-1:2*FW ];
	assign bias3	= bias[ 4*FW-1:3*FW ];
	assign bias4	= bias[ 5*FW-1:4*FW ];
	assign bias5	= bias[ 6*FW-1:5*FW ];
	assign bias6	= bias[ 7*FW-1:6*FW ];
	assign bias7	= bias[ 8*FW-1:7*FW ];
	assign bias8	= bias[ 9*FW-1:8*FW ];
	assign bias9	= bias[ 10*FW-1:9*FW ];
	assign bias10	= bias[ 11*FW-1:10*FW ];
	assign bias11	= bias[ 12*FW-1:11*FW ];
	assign bias12	= bias[ 13*FW-1:12*FW ];
	assign bias13	= bias[ 14*FW-1:13*FW ];
	assign bias14	= bias[ 15*FW-1:14*FW ];
	assign bias15	= bias[ 16*FW-1:15*FW ];
	assign bias16	= bias[ 17*FW-1:16*FW ];
	assign bias17	= bias[ 18*FW-1:17*FW ];
	assign bias18	= bias[ 19*FW-1:18*FW ];
	assign bias19	= bias[ 20*FW-1:19*FW ];
	assign bias20	= bias[ 21*FW-1:20*FW ];
	assign bias21	= bias[ 22*FW-1:21*FW ];
	assign bias22	= bias[ 23*FW-1:22*FW ];
	assign bias23	= bias[ 24*FW-1:23*FW ];
	assign bias24	= bias[ 25*FW-1:24*FW ];
	assign bias25	= bias[ 26*FW-1:25*FW ];
	assign bias26	= bias[ 27*FW-1:26*FW ];
	assign bias27	= bias[ 28*FW-1:27*FW ];
	assign bias28	= bias[ 29*FW-1:28*FW ];
	assign bias29	= bias[ 30*FW-1:29*FW ];
	assign bias30	= bias[ 31*FW-1:30*FW ];
	assign bias31	= bias[ 32*FW-1:31*FW ];
	assign bias32	= bias[ 33*FW-1:32*FW ];
	assign bias33	= bias[ 34*FW-1:33*FW ];
	assign bias34	= bias[ 35*FW-1:34*FW ];
	assign bias35	= bias[ 36*FW-1:35*FW ];
	assign bias36	= bias[ 37*FW-1:36*FW ];
	assign bias37	= bias[ 38*FW-1:37*FW ];
	assign bias38	= bias[ 39*FW-1:38*FW ];
	assign bias39	= bias[ 40*FW-1:39*FW ];
	assign bias40	= bias[ 41*FW-1:40*FW ];
	assign bias41	= bias[ 42*FW-1:41*FW ];
	assign bias42	= bias[ 43*FW-1:42*FW ];
	assign bias43	= bias[ 44*FW-1:43*FW ];
	assign bias44	= bias[ 45*FW-1:44*FW ];
	assign bias45	= bias[ 46*FW-1:45*FW ];
	assign bias46	= bias[ 47*FW-1:46*FW ];
	assign bias47	= bias[ 48*FW-1:47*FW ];
	assign bias48	= bias[ 49*FW-1:48*FW ];
	assign bias49	= bias[ 50*FW-1:49*FW ];
	assign bias50	= bias[ 51*FW-1:50*FW ];
	assign bias51	= bias[ 52*FW-1:51*FW ];
	assign bias52	= bias[ 53*FW-1:52*FW ];
	assign bias53	= bias[ 54*FW-1:53*FW ];
	assign bias54	= bias[ 55*FW-1:54*FW ];
	assign bias55	= bias[ 56*FW-1:55*FW ];
	assign bias56	= bias[ 57*FW-1:56*FW ];
	assign bias57	= bias[ 58*FW-1:57*FW ];
	assign bias58	= bias[ 59*FW-1:58*FW ];
	assign bias59	= bias[ 60*FW-1:59*FW ];
	assign bias60	= bias[ 61*FW-1:60*FW ];
	assign bias61	= bias[ 62*FW-1:61*FW ];
	assign bias62	= bias[ 63*FW-1:62*FW ];
	assign bias63	= bias[ 64*FW-1:63*FW ];
	
endmodule
