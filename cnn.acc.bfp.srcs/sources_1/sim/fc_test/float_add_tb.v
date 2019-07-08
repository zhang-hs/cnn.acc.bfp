`timescale 1 ns/1 ns
module float_add_tb;

parameter EW = 8;
parameter MW = 23;
parameter FW = 32;

localparam FLOAT_WIDTH = EW+MW+1;

	reg		clk_i;
	reg		rstn_i;

	reg		[ FLOAT_WIDTH-1:0 ]		add_data0_r;
	reg		[ FLOAT_WIDTH-1:0 ]		add_data1_r;
	reg		[ FLOAT_WIDTH-1:0 ]		sum_data_r;

	reg		[ FLOAT_WIDTH-1:0 ]		add_data0_;
	reg		[ FLOAT_WIDTH-1:0 ]		add_data1_;
	wire	[ FLOAT_WIDTH-1:0 ]		sum_data_;

	// init clock and reset signal {{{
	initial
	begin
		#0	clk_i	<= 1'b0;
			rstn_i	<= 1'b1;
		#5	rstn_i	<= 1'b0;
		#10	rstn_i	<= 1'b1;

		forever
			#10	clk_i	= ~clk_i;
	end
	// }}}
	// generate ramdom float data from file {{{
	integer file_test_float0;
	integer file_test_float1;
	integer file_test_sum;
	integer r;
	integer read_num;
	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin
			read_num	<= 0;

			add_data0_r	<= {FLOAT_WIDTH{1'b0}};
			add_data1_r	<= {FLOAT_WIDTH{1'b0}};
			file_test_float0	= $fopen( "../2-test/2-data/random_test_float0.bin", "r" );
			file_test_float1	= $fopen( "../2-test/2-data/random_test_float1.bin", "r" );
			file_test_sum		= $fopen( "../2-test/2-data/random_test_sum.bin", "r" );
		end
		else
		begin
			if( $feof( file_test_float0 ))
				$finish;
			r = $fread( add_data0_r, file_test_float0 );	
			r = $fread( add_data1_r, file_test_float1 );	
			r = $fread( sum_data_r, file_test_sum);

			read_num	<= read_num + 1;
		end
	end
	always @( add_data0_r or add_data1_r )
	begin
		add_data0_[ 7:0 ]	<= add_data0_r[ 31:24 ];
		add_data0_[ 15:8 ]	<= add_data0_r[ 23:16 ];
		add_data0_[ 23:16 ]	<= add_data0_r[ 15:8 ];
		add_data0_[ 31:24 ]	<= add_data0_r[ 7:0 ];

		add_data1_[ 7:0 ]	<= add_data1_r[ 31:24 ];
		add_data1_[ 15:8 ]	<= add_data1_r[ 23:16 ];
		add_data1_[ 23:16 ]	<= add_data1_r[ 15:8 ];
		add_data1_[ 31:24 ]	<= add_data1_r[ 7:0 ];
	end
	// }}}


	float_add2 // {{{
	#(
		.EW( EW ),
		.MW( MW ),
		.FW( FW )
	 )
	 float_add2_U
	 (
	 	.data_f0_i( add_data0_ ),
		.data_f1_i( add_data1_ ),
		.data_f_o ( sum_data_  )
	 );
	 // }}}
	/*
	fp_adder2 // {{{
	#(
		.EXPONENT( EW ),
		.MANTISSA( MW )
	 )
	 float_add2_U
	 (
	 	.a1( add_data0_ ),
		.a2( add_data1_ ),
		.adder_o ( sum_data_  )
	 );
	 // }}}
	 */
	

	// check sum_data {{{ 
	integer file_sum_w;
	reg		[ FLOAT_WIDTH-1:0 ]		sum_data_w;
	always @( sum_data_ )
	begin
		sum_data_w[ 31:24 ]	<= sum_data_[ 7:0 ];
		sum_data_w[ 23:16 ]	<= sum_data_[ 15:8 ];
		sum_data_w[ 15:8 ]	<= sum_data_[ 23:16 ];
		sum_data_w[ 7:0 ]	<= sum_data_[ 31:24 ];
	end
	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin
			file_sum_w = $fopen( "../2-test/2-data/random_sum_verilog.bin", "wb" );
		end
		else if( read_num > 0 )
		begin
			$fwrite( file_sum_w,"%c",sum_data_w[ 31:24 ] );		
			$fwrite( file_sum_w,"%c",sum_data_w[ 23:16 ] );		
			$fwrite( file_sum_w,"%c",sum_data_w[ 15:8  ] );		
			$fwrite( file_sum_w,"%c",sum_data_w[ 7:0   ] );		
		end
	end
	// }}}
	/*
	 * dump file
	*/
	initial
	begin
	/*
		$vcdplusfile( "float_test_result.vpd" );
		$vcdpluson( 0, float_add_tb );
		$vcdplusglitchon;
		$vcdplusflush;
	*/
		$dumpfile( "float_test_result.vcd" );
		$dumpvars( 0, float_add_tb );
	end

endmodule
