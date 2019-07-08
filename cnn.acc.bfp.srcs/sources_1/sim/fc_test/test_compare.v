extern "C" void test_compare( bit [] veri_data );

module test_data;

localparam US = 7;
localparam FW = 32;

reg		[ US*US*FW-1:0 ] 	 test_data_compare;

initial
begin
	test_data_compare[ 1*FW-1:0*FW ] = 32'd0;
	test_data_compare[ 2*FW-1:1*FW ] = 32'd1;
	test_data_compare[ 3*FW-1:2*FW ] = 32'd2;
	test_data_compare[ 4*FW-1:3*FW ] = 32'd3;
	test_data_compare[ 5*FW-1:4*FW ] = 32'd4;
	test_data_compare[ 6*FW-1:5*FW ] = 32'd5;
	test_data_compare[ 7*FW-1:6*FW ] = 32'd6;
	test_data_compare[ 8*FW-1:7*FW ] = 32'd7;
	test_data_compare[ 9*FW-1:8*FW ] = 32'd8;
	test_data_compare[ 10*FW-1:9*FW ] = 32'd9;
	test_data_compare[ 11*FW-1:10*FW ] = 32'd10;
	test_data_compare[ 12*FW-1:11*FW ] = 32'd11;
	test_data_compare[ 13*FW-1:12*FW ] = 32'd12;
	test_data_compare[ 14*FW-1:13*FW ] = 32'd13;
	test_data_compare[ 15*FW-1:14*FW ] = 32'd14;
	test_data_compare[ 16*FW-1:15*FW ] = 32'd15;
	test_data_compare[ 17*FW-1:16*FW ] = 32'd16;
	test_data_compare[ 18*FW-1:17*FW ] = 32'd17;
	test_data_compare[ 19*FW-1:18*FW ] = 32'd18;
	test_data_compare[ 20*FW-1:19*FW ] = 32'd19;
	test_data_compare[ 21*FW-1:20*FW ] = 32'd20;
	test_data_compare[ 22*FW-1:21*FW ] = 32'd21;
	test_data_compare[ 23*FW-1:22*FW ] = 32'd22;
	test_data_compare[ 24*FW-1:23*FW ] = 32'd23;
	test_data_compare[ 25*FW-1:24*FW ] = 32'd24;
	test_data_compare[ 26*FW-1:25*FW ] = 32'd25;
	test_data_compare[ 27*FW-1:26*FW ] = 32'd26;
	test_data_compare[ 28*FW-1:27*FW ] = 32'd27;
	test_data_compare[ 29*FW-1:28*FW ] = 32'd28;
	test_data_compare[ 30*FW-1:29*FW ] = 32'd29;
	test_data_compare[ 31*FW-1:30*FW ] = 32'd30;
	test_data_compare[ 32*FW-1:31*FW ] = 32'd31;
	test_data_compare[ 33*FW-1:32*FW ] = 32'd32;
	test_data_compare[ 34*FW-1:33*FW ] = 32'd33;
	test_data_compare[ 35*FW-1:34*FW ] = 32'd34;
	test_data_compare[ 36*FW-1:35*FW ] = 32'd35;
	test_data_compare[ 37*FW-1:36*FW ] = 32'd36;
	test_data_compare[ 38*FW-1:37*FW ] = 32'd37;
	test_data_compare[ 39*FW-1:38*FW ] = 32'd38;
	test_data_compare[ 40*FW-1:39*FW ] = 32'd39;
	test_data_compare[ 41*FW-1:40*FW ] = 32'd40;
	test_data_compare[ 42*FW-1:41*FW ] = 32'd41;
	test_data_compare[ 43*FW-1:42*FW ] = 32'd42;
	test_data_compare[ 44*FW-1:43*FW ] = 32'd43;
	test_data_compare[ 45*FW-1:44*FW ] = 32'd44;
	test_data_compare[ 46*FW-1:45*FW ] = 32'd45;
	test_data_compare[ 47*FW-1:46*FW ] = 32'd46;
	test_data_compare[ 48*FW-1:47*FW ] = 32'd47;
	test_data_compare[ 49*FW-1:48*FW ] = 32'd48;

	test_compare( test_data_compare );
end

endmodule
