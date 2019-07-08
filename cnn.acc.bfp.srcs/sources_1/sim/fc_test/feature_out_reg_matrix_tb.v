/*--------------------------------------------------
 * This module is a testbench for feature_in_reg_matrix.v
 *
 * parameter:
 * EW: exponent width for float
 * MW: mantisa width for float
 * FW: float width
 * US:	unit store size
 * MS:	feature out reg matrix size
 * DW:	data width to write_op module
--------------------------------------------------*/
module feature_out_reg_matrix_tb;
parameter EW = 8;
parameter MW = 23;
parameter FW = 32;
parameter US = 7;
parameter MS = 32;
parameter KN = 512;
parameter DW = 512;
parameter STOP_ACCUM = 100;

	reg		rstn_i;
	reg		clk_i;

	reg									accum_en_i;
	reg		[ MS*FW-1:0 ]				accum_data_i;
	reg		[ 4-1:0 ]					addr_x_i;
	reg		[ 4-1:0 ]					addr_y_i;
	reg		[ 4-1:0 ]					grp_sel_i;

	reg									bias_full_i;
	reg		[ KN*FW-1:0 ]				bias_data_i;

	reg									wr_en_i;
	wire	[ MS*(2*US*2*US)*FW-1:0 ]	feature_out_data_o;

	// inittial global reset and clock signal {{{
	initial
	begin
		#0	rstn_i 	<= 1'b1;
			clk_i	<= 1'b0;
		#5	rstn_i	<= 1'b0;
		#5	rstn_i	<= 1'b1;

		forever
			#10	clk_i	<= ~clk_i; 
	end
	// }}}
	
	// generate test data from file {{{
	integer	file_test_data;
	integer file_test_sum;
	integer r;
	integer	accum_num;
	genvar  i;
	wire	[ MS*FW-1:0 ]				accum_data_cur;
	wire	[ MS*(2*US*2*US)*FW-1:0 ]	feature_out_data_write;

	// transform float data form {{{
	generate
	for( i = 0; i < MS; i = i + 1 )	
		begin
			assign accum_data_cur[ i*FW+7:i*FW ] 		= accum_data_i[ i*FW+31:i*FW+24 ];
			assign accum_data_cur[ i*FW+15:i*FW+8 ] 	= accum_data_i[ i*FW+23:i*FW+16 ];
			assign accum_data_cur[ i*FW+23:i*FW+16 ] 	= accum_data_i[ i*FW+15:i*FW+8 ];
			assign accum_data_cur[ i*FW+31:i*FW+24 ] 	= accum_data_i[ i*FW+7:i*FW ];
		end
	endgenerate

	generate
		for( i = 0; i < MS*(4*US*US); i = i + 1 )
		begin
			/*
			assign feature_out_data_write[ (MS*(4*US*US)-1-i)*FW+7:(MS*(4*US*US)-1-i)*FW+0 ] 	= feature_out_data_o[ i*FW+31:i*FW+24 ];
			assign feature_out_data_write[ (MS*(4*US*US)-1-i)*FW+15:(MS*(4*US*US)-1-i)*FW+8 ] 	= feature_out_data_o[ i*FW+23:i*FW+16 ];
			assign feature_out_data_write[ (MS*(4*US*US)-1-i)*FW+23:(MS*(4*US*US)-1-i)*FW+16 ] 	= feature_out_data_o[ i*FW+15:i*FW+8 ];
			assign feature_out_data_write[ (MS*(4*US*US)-1-i)*FW+31:(MS*(4*US*US)-1-i)*FW+24 ] 	= feature_out_data_o[ i*FW+7:i*FW+0 ];
			*/
			
			assign feature_out_data_write[ i*FW+31:i*FW+24 ] 		= feature_out_data_o[ i*FW+31:i*FW+24 ];
			assign feature_out_data_write[ i*FW+23:i*FW+16 ] 	= feature_out_data_o[ i*FW+23:i*FW+16 ];
			assign feature_out_data_write[ i*FW+15:i*FW+8 ] 	= feature_out_data_o[ i*FW+15:i*FW+8 ];
			assign feature_out_data_write[ i*FW+7:i*FW+0 ] 	= feature_out_data_o[ i*FW+7:i*FW+0 ];
		end
	endgenerate
	// }}}

	always @( posedge wr_en_i ) 
	begin
		$fwrite( file_test_sum, "%u", feature_out_data_write );
	end

	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin
			accum_en_i		<= 1'b0;
			accum_data_i	<= { (MS*FW){1'b0} };
			addr_x_i		<= 4'd15;
			addr_y_i		<= 4'd0;
			grp_sel_i		<= 4'd0;
			accum_num		<= 0;

			bias_full_i		<= 1'b0;
			bias_data_i		<= { (KN*FW){1'b0} };

			wr_en_i			<= 1'b0;

			file_test_data	= $fopen( "../2-test/2-data/test_float_add2_data.bin", "rb" );
			file_test_sum	= $fopen( "../2-test/2-data/test_float_add2_sum_data_sim.bin", "wb" );
		end
		else if( wr_en_i == 1'b0 )
		begin // read data from file {{{
			if( addr_x_i == 4'd13 )
			begin
				if( addr_y_i == 4'd13 )
				begin
					addr_y_i 	<= 4'd0;
					if( accum_num == STOP_ACCUM )
					begin
						accum_num 	<= 0;
					end
					else
					begin
						$display( "%dth accumulation record.", accum_num );
						accum_num	<= accum_num + 1;
					end
				end
				else
				begin
					addr_y_i		<= addr_y_i + 4'd1;
				end
				addr_x_i		<= 4'd0;
			end
			else
			begin
				addr_x_i		<= addr_x_i + 4'd1;
			end
			if( addr_x_i == 4'd13 && addr_y_i == 4'd13 && accum_num == STOP_ACCUM-1 )
				accum_en_i	<= 1'b0;
			else
				accum_en_i	<= 1'b1;

			if( accum_num == STOP_ACCUM )
				wr_en_i 	<= 1'b1;
			else if( accum_num != STOP_ACCUM )
				wr_en_i		<= 1'b0;

			r = $fread( accum_data_i, file_test_data );
		end // }}}
		else if( wr_en_i == 1'b1 )
		begin
			#100	$finish;
		end
	end
	// }}}
	
	// initialize test module {{{
	feature_out_reg_matrix
	#(
		.EW( EW ),
		.MW( MW ),
		.FW( FW ),
		.US( US ),
		.MS( MS ),
		.DW( DW )
	 )
	 (
	 	.clk_i	( clk_i 	),
		.rstn_i	( rstn_i 	),
		.accum_en_i				( accum_en_i 			),
		.accum_data_i			( accum_data_cur		),
		.addr_x_i				( addr_x_i 				),
		.addr_y_i				( addr_y_i 				),
		.grp_sel_i				( grp_sel_i				),
		.bias_full_i			( bias_full_i 			),
		.bias_data_i			( bias_data_i 			),
		.wr_en_i				( wr_en_i 				),
		.feature_out_data0_o	( feature_out_data_o	)
	 );
	 // }}}

	 // data display {{{
	 wire [ FW-1:0 ]	feature0_0,feature0_1,feature0_2,feature0_3,feature0_4,feature0_5,feature0_6,feature0_7,feature0_8,feature0_9,
	 					feature0_10,feature0_11,feature0_12,feature0_13,feature0_14,feature0_15,feature0_16,feature0_17,feature0_18,feature0_19,
	 					feature0_20,feature0_21,feature0_22,feature0_23,feature0_24,feature0_25,feature0_26,feature0_27,feature0_28,feature0_29,
	 					feature0_30,feature0_31,feature0_32,feature0_33,feature0_34,feature0_35,feature0_36,feature0_37,feature0_38,feature0_39,
	 					feature0_40,feature0_41,feature0_42,feature0_43,feature0_44,feature0_45,feature0_46,feature0_47,feature0_48,feature0_49,
	 					feature0_50,feature0_51,feature0_52,feature0_53,feature0_54,feature0_55,feature0_56,feature0_57,feature0_58,feature0_59,
	 					feature0_60,feature0_61,feature0_62,feature0_63,feature0_64,feature0_65,feature0_66,feature0_67,feature0_68,feature0_69,
	 					feature0_70,feature0_71,feature0_72,feature0_73,feature0_74,feature0_75,feature0_76,feature0_77,feature0_78,feature0_79,
	 					feature0_80,feature0_81,feature0_82,feature0_83,feature0_84,feature0_85,feature0_86,feature0_87,feature0_88,feature0_89,
	 					feature0_90,feature0_91,feature0_92,feature0_93,feature0_94,feature0_95,feature0_96,feature0_97,feature0_98,feature0_99,
	 					feature0_100,feature0_101,feature0_102,feature0_103,feature0_104,feature0_105,feature0_106,feature0_107,feature0_108,feature0_109,
	 					feature0_110,feature0_111,feature0_112,feature0_113,feature0_114,feature0_115,feature0_116,feature0_117,feature0_118,feature0_119,
	 					feature0_120,feature0_121,feature0_122,feature0_123,feature0_124,feature0_125,feature0_126,feature0_127,feature0_128,feature0_129,
	 					feature0_130,feature0_131,feature0_132,feature0_133,feature0_134,feature0_135,feature0_136,feature0_137,feature0_138,feature0_139,
	 					feature0_140,feature0_141,feature0_142,feature0_143,feature0_144,feature0_145,feature0_146,feature0_147,feature0_148,feature0_149,
	 					feature0_150,feature0_151,feature0_152,feature0_153,feature0_154,feature0_155,feature0_156,feature0_157,feature0_158,feature0_159,
	 					feature0_160,feature0_161,feature0_162,feature0_163,feature0_164,feature0_165,feature0_166,feature0_167,feature0_168,feature0_169,
	 					feature0_170,feature0_171,feature0_172,feature0_173,feature0_174,feature0_175,feature0_176,feature0_177,feature0_178,feature0_179,
	 					feature0_180,feature0_181,feature0_182,feature0_183,feature0_184,feature0_185,feature0_186,feature0_187,feature0_188,feature0_189,
	 					feature0_190,feature0_191,feature0_192,feature0_193,feature0_194,feature0_195;
	assign feature0_0 = feature_out_data_o[ 1*FW-1:0*FW ];
	assign feature0_1 = feature_out_data_o[ 2*FW-1:1*FW ];
	assign feature0_2 = feature_out_data_o[ 3*FW-1:2*FW ];
	assign feature0_3 = feature_out_data_o[ 4*FW-1:3*FW ];
	assign feature0_4 = feature_out_data_o[ 5*FW-1:4*FW ];
	assign feature0_5 = feature_out_data_o[ 6*FW-1:5*FW ];
	assign feature0_6 = feature_out_data_o[ 7*FW-1:6*FW ];
	assign feature0_7 = feature_out_data_o[ 8*FW-1:7*FW ];
	assign feature0_8 = feature_out_data_o[ 9*FW-1:8*FW ];
	assign feature0_9 = feature_out_data_o[ 10*FW-1:9*FW ];
	assign feature0_10 = feature_out_data_o[ 11*FW-1:10*FW ];
	assign feature0_11 = feature_out_data_o[ 12*FW-1:11*FW ];
	assign feature0_12 = feature_out_data_o[ 13*FW-1:12*FW ];
	assign feature0_13 = feature_out_data_o[ 14*FW-1:13*FW ];
	assign feature0_14 = feature_out_data_o[ 15*FW-1:14*FW ];
	assign feature0_15 = feature_out_data_o[ 16*FW-1:15*FW ];
	assign feature0_16 = feature_out_data_o[ 17*FW-1:16*FW ];
	assign feature0_17 = feature_out_data_o[ 18*FW-1:17*FW ];
	assign feature0_18 = feature_out_data_o[ 19*FW-1:18*FW ];
	assign feature0_19 = feature_out_data_o[ 20*FW-1:19*FW ];
	assign feature0_20 = feature_out_data_o[ 21*FW-1:20*FW ];
	assign feature0_21 = feature_out_data_o[ 22*FW-1:21*FW ];
	assign feature0_22 = feature_out_data_o[ 23*FW-1:22*FW ];
	assign feature0_23 = feature_out_data_o[ 24*FW-1:23*FW ];
	assign feature0_24 = feature_out_data_o[ 25*FW-1:24*FW ];
	assign feature0_25 = feature_out_data_o[ 26*FW-1:25*FW ];
	assign feature0_26 = feature_out_data_o[ 27*FW-1:26*FW ];
	assign feature0_27 = feature_out_data_o[ 28*FW-1:27*FW ];
	assign feature0_28 = feature_out_data_o[ 29*FW-1:28*FW ];
	assign feature0_29 = feature_out_data_o[ 30*FW-1:29*FW ];
	assign feature0_30 = feature_out_data_o[ 31*FW-1:30*FW ];
	assign feature0_31 = feature_out_data_o[ 32*FW-1:31*FW ];
	assign feature0_32 = feature_out_data_o[ 33*FW-1:32*FW ];
	assign feature0_33 = feature_out_data_o[ 34*FW-1:33*FW ];
	assign feature0_34 = feature_out_data_o[ 35*FW-1:34*FW ];
	assign feature0_35 = feature_out_data_o[ 36*FW-1:35*FW ];
	assign feature0_36 = feature_out_data_o[ 37*FW-1:36*FW ];
	assign feature0_37 = feature_out_data_o[ 38*FW-1:37*FW ];
	assign feature0_38 = feature_out_data_o[ 39*FW-1:38*FW ];
	assign feature0_39 = feature_out_data_o[ 40*FW-1:39*FW ];
	assign feature0_40 = feature_out_data_o[ 41*FW-1:40*FW ];
	assign feature0_41 = feature_out_data_o[ 42*FW-1:41*FW ];
	assign feature0_42 = feature_out_data_o[ 43*FW-1:42*FW ];
	assign feature0_43 = feature_out_data_o[ 44*FW-1:43*FW ];
	assign feature0_44 = feature_out_data_o[ 45*FW-1:44*FW ];
	assign feature0_45 = feature_out_data_o[ 46*FW-1:45*FW ];
	assign feature0_46 = feature_out_data_o[ 47*FW-1:46*FW ];
	assign feature0_47 = feature_out_data_o[ 48*FW-1:47*FW ];
	assign feature0_48 = feature_out_data_o[ 49*FW-1:48*FW ];
	assign feature0_49 = feature_out_data_o[ 50*FW-1:49*FW ];
	assign feature0_50 = feature_out_data_o[ 51*FW-1:50*FW ];
	assign feature0_51 = feature_out_data_o[ 52*FW-1:51*FW ];
	assign feature0_52 = feature_out_data_o[ 53*FW-1:52*FW ];
	assign feature0_53 = feature_out_data_o[ 54*FW-1:53*FW ];
	assign feature0_54 = feature_out_data_o[ 55*FW-1:54*FW ];
	assign feature0_55 = feature_out_data_o[ 56*FW-1:55*FW ];
	assign feature0_56 = feature_out_data_o[ 57*FW-1:56*FW ];
	assign feature0_57 = feature_out_data_o[ 58*FW-1:57*FW ];
	assign feature0_58 = feature_out_data_o[ 59*FW-1:58*FW ];
	assign feature0_59 = feature_out_data_o[ 60*FW-1:59*FW ];
	assign feature0_60 = feature_out_data_o[ 61*FW-1:60*FW ];
	assign feature0_61 = feature_out_data_o[ 62*FW-1:61*FW ];
	assign feature0_62 = feature_out_data_o[ 63*FW-1:62*FW ];
	assign feature0_63 = feature_out_data_o[ 64*FW-1:63*FW ];
	assign feature0_64 = feature_out_data_o[ 65*FW-1:64*FW ];
	assign feature0_65 = feature_out_data_o[ 66*FW-1:65*FW ];
	assign feature0_66 = feature_out_data_o[ 67*FW-1:66*FW ];
	assign feature0_67 = feature_out_data_o[ 68*FW-1:67*FW ];
	assign feature0_68 = feature_out_data_o[ 69*FW-1:68*FW ];
	assign feature0_69 = feature_out_data_o[ 70*FW-1:69*FW ];
	assign feature0_70 = feature_out_data_o[ 71*FW-1:70*FW ];
	assign feature0_71 = feature_out_data_o[ 72*FW-1:71*FW ];
	assign feature0_72 = feature_out_data_o[ 73*FW-1:72*FW ];
	assign feature0_73 = feature_out_data_o[ 74*FW-1:73*FW ];
	assign feature0_74 = feature_out_data_o[ 75*FW-1:74*FW ];
	assign feature0_75 = feature_out_data_o[ 76*FW-1:75*FW ];
	assign feature0_76 = feature_out_data_o[ 77*FW-1:76*FW ];
	assign feature0_77 = feature_out_data_o[ 78*FW-1:77*FW ];
	assign feature0_78 = feature_out_data_o[ 79*FW-1:78*FW ];
	assign feature0_79 = feature_out_data_o[ 80*FW-1:79*FW ];
	assign feature0_80 = feature_out_data_o[ 81*FW-1:80*FW ];
	assign feature0_81 = feature_out_data_o[ 82*FW-1:81*FW ];
	assign feature0_82 = feature_out_data_o[ 83*FW-1:82*FW ];
	assign feature0_83 = feature_out_data_o[ 84*FW-1:83*FW ];
	assign feature0_84 = feature_out_data_o[ 85*FW-1:84*FW ];
	assign feature0_85 = feature_out_data_o[ 86*FW-1:85*FW ];
	assign feature0_86 = feature_out_data_o[ 87*FW-1:86*FW ];
	assign feature0_87 = feature_out_data_o[ 88*FW-1:87*FW ];
	assign feature0_88 = feature_out_data_o[ 89*FW-1:88*FW ];
	assign feature0_89 = feature_out_data_o[ 90*FW-1:89*FW ];
	assign feature0_90 = feature_out_data_o[ 91*FW-1:90*FW ];
	assign feature0_91 = feature_out_data_o[ 92*FW-1:91*FW ];
	assign feature0_92 = feature_out_data_o[ 93*FW-1:92*FW ];
	assign feature0_93 = feature_out_data_o[ 94*FW-1:93*FW ];
	assign feature0_94 = feature_out_data_o[ 95*FW-1:94*FW ];
	assign feature0_95 = feature_out_data_o[ 96*FW-1:95*FW ];
	assign feature0_96 = feature_out_data_o[ 97*FW-1:96*FW ];
	assign feature0_97 = feature_out_data_o[ 98*FW-1:97*FW ];
	assign feature0_98 = feature_out_data_o[ 99*FW-1:98*FW ];
	assign feature0_99 = feature_out_data_o[ 100*FW-1:99*FW ];
	assign feature0_100 = feature_out_data_o[ 101*FW-1:100*FW ];
	assign feature0_101 = feature_out_data_o[ 102*FW-1:101*FW ];
	assign feature0_102 = feature_out_data_o[ 103*FW-1:102*FW ];
	assign feature0_103 = feature_out_data_o[ 104*FW-1:103*FW ];
	assign feature0_104 = feature_out_data_o[ 105*FW-1:104*FW ];
	assign feature0_105 = feature_out_data_o[ 106*FW-1:105*FW ];
	assign feature0_106 = feature_out_data_o[ 107*FW-1:106*FW ];
	assign feature0_107 = feature_out_data_o[ 108*FW-1:107*FW ];
	assign feature0_108 = feature_out_data_o[ 109*FW-1:108*FW ];
	assign feature0_109 = feature_out_data_o[ 110*FW-1:109*FW ];
	 // }}}

	 // dump file {{{
	 initial
	 begin
		/*
		$vcdplusfile( "feature_out_reg_matrix_tb.vpd" );
		$vcdpluson( 0, feature_out_reg_matrix_tb );
		$vcdplusglitchon;
		$vcdplusflush;
		*/
		/*
		$dumpfile( "feature_out_reg_matrix_tb.vcd" );
		$dumpvars( 0, feature_out_reg_matrix_tb );
		*/
	 end
	 // }}}

endmodule
