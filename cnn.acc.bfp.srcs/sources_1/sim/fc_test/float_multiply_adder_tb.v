`timescale 1 ns/1 ns
module float_multiply_adder_tb;

parameter EW = 8;
parameter MW = 23;
parameter FW = 32;

localparam FLOAT_WIDTH = EW+MW+1;

    reg     clk_i;
    reg     rstn_i;

    reg     [ FLOAT_WIDTH-1:0 ]     mul_data0_r;
    reg     [ FLOAT_WIDTH-1:0 ]     mul_data1_r;
    reg     [ FLOAT_WIDTH-1:0 ]     add_data2_r;
    reg     [ FLOAT_WIDTH-1:0 ]     mul_add_data_r;

    reg                             mul_data0_valid;
    reg                             mul_data1_valid;
    reg                             add_data2_valid;
    wire                            mul_add_data_valid;
    reg     [ FLOAT_WIDTH-1:0 ]     mul_data0_;
    reg     [ FLOAT_WIDTH-1:0 ]     mul_data1_;
    reg     [ FLOAT_WIDTH-1:0 ]     add_data2_;
    wire    [ FLOAT_WIDTH-1:0 ]     mul_add_data_;

    initial
    begin
        #0  clk_i   <= 1'b0;
            rstn_i  <= 1'b1;
        #5  rstn_i  <= 1'b0;
        #10 rstn_i  <= 1'b1;

        forever
            #10 clk_i   = ~clk_i;
    end

    integer file_test_float0;
    integer file_test_float1;
    integer file_test_float2;
    integer file_test_result;
    integer r;
    integer read_num;
    always @( negedge rstn_i or posedge clk_i )
    begin
        if( rstn_i == 1'b0 )
        begin
            read_num    <= 0;

            mul_data0_r <= {FLOAT_WIDTH{1'b0}};
            mul_data1_r <= {FLOAT_WIDTH{1'b0}};
            add_data2_r <= {FLOAT_WIDTH{1'b0}};
            mul_data0_valid = 1'b0;
            mul_data1_valid = 1'b0;
            add_data2_valid = 1'b0;

            file_test_float0    = $fopen( "../../../../../git-proj/VGG_verilog/test/data/random_test_float0.bin", "r" );
            file_test_float1    = $fopen( "../../../../../git-proj/VGG_verilog/test/data/random_test_float1.bin", "r" );
            file_test_float2    = $fopen( "../../../../../git-proj/VGG_verilog/test/data/random_test_float2.bin", "r" );
            file_test_result    = $fopen( "../../../../../git-proj/VGG_verilog/test/data/random_test_mul_add.bin", "r" );
        end
        else
        begin
            if( $feof( file_test_float0 ))
                $finish;
            r = $fread( mul_data0_r, file_test_float0 );    
            r = $fread( mul_data1_r, file_test_float1 );    
            r = $fread( add_data2_r, file_test_float2 );    
            r = $fread( mul_add_data_r, file_test_result);
            mul_data0_valid = 1'b1;
            mul_data1_valid = 1'b1;
            add_data2_valid = 1'b1;

            read_num    <= read_num + 1;
        end
    end
    always @( mul_data0_r or mul_data1_r or add_data2_r)
    begin
        mul_data0_[ 7:0 ]   <= mul_data0_r[ 31:24 ];
        mul_data0_[ 15:8 ]  <= mul_data0_r[ 23:16 ];
        mul_data0_[ 23:16 ] <= mul_data0_r[ 15:8 ];
        mul_data0_[ 31:24 ] <= mul_data0_r[ 7:0 ];

        mul_data1_[ 7:0 ]   <= mul_data1_r[ 31:24 ];
        mul_data1_[ 15:8 ]  <= mul_data1_r[ 23:16 ];
        mul_data1_[ 23:16 ] <= mul_data1_r[ 15:8 ];
        mul_data1_[ 31:24 ] <= mul_data1_r[ 7:0 ];

        add_data2_[ 7:0 ]   <= add_data2_r[ 31:24 ];
        add_data2_[ 15:8 ]  <= add_data2_r[ 23:16 ];
        add_data2_[ 23:16 ] <= add_data2_r[ 15:8 ];
        add_data2_[ 31:24 ] <= add_data2_r[ 7:0 ];
    end

    float_multiply_adder
    float_multiply_adder_U
    (
      .aclk (clk_i),                     
      .s_axis_a_tvalid     (mul_data0_valid),       
      .s_axis_a_tdata      (mul_data0_),         
      .s_axis_b_tvalid     (mul_data1_valid),       
      .s_axis_b_tdata      (mul_data1_),         
      .s_axis_c_tvalid     (add_data2_valid),       
      .s_axis_c_tdata      (add_data2_),         
      .m_axis_result_tvalid(mul_add_data_valid),
      .m_axis_result_tdata (mul_add_data_)   
    );

    integer file_sum_w;
    reg     [ FLOAT_WIDTH-1:0 ]     mul_add_data_w;
    always @( mul_add_data_ )
    begin
        mul_add_data_w[ 31:24 ] <= mul_add_data_[ 7:0 ];
        mul_add_data_w[ 23:16 ] <= mul_add_data_[ 15:8 ];
        mul_add_data_w[ 15:8 ]  <= mul_add_data_[ 23:16 ];
        mul_add_data_w[ 7:0 ]   <= mul_add_data_[ 31:24 ];
    end
    always @( negedge rstn_i or posedge clk_i )
    begin
        if( rstn_i == 1'b0 )
        begin
            file_sum_w = $fopen( "../../../../../git-proj/VGG_verilog/test/data/random_mul_add_verilog.bin", "wb+" );
        end
        else if( mul_add_data_valid == 1'b1 ) // because float_multiply_adder delay one clock
        begin
            $fwrite( file_sum_w,"%c",mul_add_data_w[ 31:24 ] );     
            $fwrite( file_sum_w,"%c",mul_add_data_w[ 23:16 ] );     
            $fwrite( file_sum_w,"%c",mul_add_data_w[ 15:8  ] );     
            $fwrite( file_sum_w,"%c",mul_add_data_w[ 7:0   ] );     
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
        $vcdpluson( 0, float_mul_tb );
        $vcdplusglitchon;
        $vcdplusflush;
    */
        $dumpfile( "float_test_result.vcd" );
        $dumpvars( 0, float_multiply_adder_tb );
    end
endmodule
