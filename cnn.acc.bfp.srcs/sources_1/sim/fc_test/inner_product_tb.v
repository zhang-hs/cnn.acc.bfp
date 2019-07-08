//`timescale 1 ns / 1 ps
`include "common.v"

// DiretC API
`include "sim_tb.inc"

module inner_product_tb;

    // decide float width
    `ifdef FP16
    parameter EW = 5;
    parameter MW = 10;
    `else
    parameter EW = 8;
    parameter MW = 23;
    `endif

    parameter DW = 512;
    parameter WL = 32;
    parameter iNN = 25088;

    localparam FW = EW + MW+1;
    localparam CDW = 32*FW; // data width from conv module
    //wire rstn_i;
    //wire clk_i;
    
    wire ip_en;
    wire ip_layer_done;
    wire ip_done;

    wire rd_bram_en;
    wire [15-1:0] rd_bram_addr;
    wire [FW-1:0] rd_bram_data;
    
    wire rd_ddr_en;
    wire wr_buf_done;
    wire [3-1:0] cur_layer_index;
    wire [2-1:0] param_buf_full;
    wire [2-1:0] param_buf_busy;
    wire [9-1:0] ip_buf_addr;
    wire  [FW-1:0] ip_param;

    wire relu_en;
    wire output_valid;
    wire output_en;
    wire [12-1:0] ip_addr;
    wire [FW-1:0] ip_data;

    // prepare ip data to bram
    reg  prepare_en;
    wire prepare_done;
    wire [CDW-1:0]prepare_data;
    wire prepare_data_valid;
    wire [12-1:0] prepare_data_addr;

    //====================================
    //  ddr model and rd_wr_interface
    //====================================
    `include "ddr_model.inc"

    //====================================
    //  DirectC test
    //==================================== 
`ifdef SIM
    wire [FW-1:0] ip_data_sim;
    wire ip_data_valid_sim;
    wire [15-1:0] ip_bram_addr_sim;
    wire [FW-1:0] ip_weight_sim;
    wire ip_weight_valid_sim;
    wire [FW-1:0] ip_bias_sim;
    wire ip_bias_valid_sim;
    wire rd_buf_done_sim;
    wire [FW-1:0] accum_data_sim;
    reg  [32-1:0] ip_data_fp32_sim;
    reg  [32-1:0] block_pos;
    reg  [32-1:0] file_pos;

    reg  [32-1:0] err_energy_sim;
    reg  [32-1:0] sig_energy_sim;

    always @(ip_buf_addr or block_pos) begin
        file_pos = block_pos + WL-1 - {23'd0, ip_buf_addr};
    end
    
    `ifdef FP16
    always @(ip_data) begin
        to_float32(ip_data, ip_data_fp32_sim);
    end
    `endif
    always @(posedge rst or posedge clk) begin
        if(rst) begin
            block_pos <= 32'd0;

            err_energy_sim  <= {32{1'b0}};
            sig_energy_sim <= {32{1'b0}};
        end
        // else if(output_en) begin
        //     block_pos <= 32'd0;
        // end
        else if(rd_buf_done_sim) begin
            block_pos <= block_pos + WL; 
        end

        // check read in param
        if(ip_bias_valid_sim || ip_weight_valid_sim) begin
            param_in_check(ip_weight_valid_sim, ip_weight_sim, ip_bias_sim, file_pos);
            // directC_test();
        end

        /* data check in every read cycle
        if(ip_data_valid_sim) begin
            data_in_check(ip_data_sim, ip_bram_addr_sim);
        end

        if(ip_bias_valid_sim || (ip_weight_valid_sim && ip_data_valid_sim)) begin
            increment_out_check(ip_weight_valid_sim, ip_weight_sim, ip_bias_sim, ip_data_sim, accum_data_sim, file_pos);
        end
        */

        // check each output for current fully-connected layer
        if(output_valid) begin
            out_check(cur_layer_index, ip_addr, 
                      `ifdef FP16 ip_data_fp32_sim `else ip_data `endif, 
                      sig_energy_sim, err_energy_sim);
        end

        // show final noise to signal ratio(nsr) for current layer
        if(ip_layer_done) begin
            error_status(cur_layer_index, sig_energy_sim, err_energy_sim);
        end
    end
`endif


    initial begin
        #0  prepare_en <= 1'b0;
        #10 prepare_en <= 1'b1;
    end

    //====================================
    //  prepare input data for ip
    //====================================    
    prepare_ip_data_sim
    #(
        .FW(FW),
        .CDW(CDW),
        .iNN(iNN)
    )
    prepare_ip_data_sim_U
    (
        .tb_clk_i (clk ),
        .tb_rstn_i(~rst),
        .tb_en_i         (prepare_en        ),
        .tb_done_o       (prepare_done      ),
        .tb_data_o       (prepare_data      ), 
        .tb_addr_o       (prepare_data_addr ),
        .tb_data_valid_o (prepare_data_valid)
    );

    //====================================
    //  prepare param for ip
    //====================================    
    wr_ddr_op
    #(
        .ADDR_WIDTH   (ADDR_WIDTH   ),
        .DATA_WIDTH   (DATA_WIDTH   ),
        .DATA_NUM_BITS(DATA_NUM_BITS)
    )
    wr_ddr_op_U
    (
        .clk_i(clk),
        .rst_i(rst),
        .init_calib_complete_i(init_calib_complete),
        .wr_ddr_done_i        (wr_ddr_done        ),
        .wr_en_o              (ddr3_wr_en         ),
        .wr_burst_num_o       (wr_burst_num       ),
        .fetch_data_en_i      (fetch_data_en      ),
        .wr_start_addr_o      (wr_start_addr      ),
        .wr_data_o            (ddr3_wr_data       )
    );  

    //====================================
    //  read/write interface with ddr
    //====================================    
    rd_wr_interface#
    (

        .SIMULATION                (SIMULATION),
        .PORT_MODE                 (PORT_MODE),
        .DATA_MODE                 (DATA_MODE),
        .TST_MEM_INSTR_MODE        (TST_MEM_INSTR_MODE),
        .EYE_TEST                  (EYE_TEST),
        .DATA_PATTERN              (DATA_PATTERN),
        .CMD_PATTERN               (CMD_PATTERN),
        .BEGIN_ADDRESS             (BEGIN_ADDRESS),
        .END_ADDRESS               (END_ADDRESS),
        .PRBS_EADDR_MASK_POS       (PRBS_EADDR_MASK_POS),
        .COL_WIDTH                 (COL_WIDTH),
        .CS_WIDTH                  (CS_WIDTH),
        .DQ_WIDTH                  (DQ_WIDTH),
        .DQS_CNT_WIDTH             (DQS_CNT_WIDTH),
        .DRAM_WIDTH                (DRAM_WIDTH),
        .ECC_TEST                  (ECC_TEST),
        .RANKS                     (RANKS),
        .ROW_WIDTH                 (ROW_WIDTH),
        .ADDR_WIDTH                (ADDR_WIDTH),
        .BURST_MODE                (BURST_MODE),
        .TCQ                       (TCQ),
        .DRAM_TYPE                 (DRAM_TYPE),
        .nCK_PER_CLK               (nCK_PER_CLK),
        .DEBUG_PORT                (DEBUG_PORT),
        .RST_ACT_LOW               (RST_ACT_LOW),
        .DATA_NUM_BITS             (DATA_NUM_BITS)
    )
    rd_wr_interface_U
    (
        .ddr3_dq              (ddr3_dq_fpga),
        .ddr3_dqs_n           (ddr3_dqs_n_fpga),
        .ddr3_dqs_p           (ddr3_dqs_p_fpga),

        .ddr3_addr            (ddr3_addr_fpga), 
        .ddr3_ba              (ddr3_ba_fpga),
        .ddr3_ras_n           (ddr3_ras_n_fpga),
        .ddr3_cas_n           (ddr3_cas_n_fpga),
        .ddr3_we_n            (ddr3_we_n_fpga),
        .ddr3_reset_n         (ddr3_reset_n),
        .ddr3_ck_p            (ddr3_ck_p_fpga),
        .ddr3_ck_n            (ddr3_ck_n_fpga),
        .ddr3_cke             (ddr3_cke_fpga),
        .ddr3_cs_n            (ddr3_cs_n_fpga),
        .ddr3_odt             (ddr3_odt_fpga),

        .wr_en_i              (ddr3_wr_en    ),
        .rd_en_i              (ddr3_rd_en    ),
        .fetch_data_en_o      (fetch_data_en ),
        .wr_burst_num_i       (wr_burst_num  ),
        .wr_start_addr_i      (wr_start_addr ),
        .wr_data_i            (ddr3_wr_data  ),
        .wr_ddr_done_o        (wr_ddr_done   ),
        .rd_start_addr_i      (rd_start_addr ),
        .rd_burst_num_i       (rd_burst_num  ),
        .rd_data_valid_o      (ddr3_rd_data_valid ),
        .rd_data_o            (ddr3_rd_data  ),
        .rd_ddr_done_o        (rd_ddr_done   ),
      
       
        .sys_clk_p            (sys_clk_p     ),
        .sys_clk_n            (sys_clk_n     ),
      
        .clk_o                (clk           ),
        .rst_o                (rst           ),
        .init_calib_complete (init_calib_complete),
        .tg_compare_error    (tg_compare_error),
        .sys_rst             (sys_rst)
    );

    //====================================
    //  inner product top module
    //==================================== 
    assign ip_en = prepare_done;
    inner_product
    #(
        .EW(EW),
        .MW(MW),
        .FW(FW),
        .WL(WL),
        .ADDR_WIDTH   (ADDR_WIDTH   ),
        .DATA_WIDTH   (DATA_WIDTH   ),
        .DATA_NUM_BITS(DATA_NUM_BITS)
    )
    inner_product_U
    (
        .clk_i  (clk ),
        .rstn_i (~rst),
        .wr_ddr_done_i         (wr_ddr_done       ),
        .init_calib_complete_i (init_calib_complete),
`ifdef SIM
        .ip_data_sim_o         (ip_data_sim        ),
        .ip_data_valid_sim_o   (ip_data_valid_sim  ),
        .ip_bram_addr_sim_o    (ip_bram_addr_sim   ),
        .ip_weight_sim_o       (ip_weight_sim      ),
        .ip_weight_valid_sim_o (ip_weight_valid_sim),
        .ip_bias_sim_o         (ip_bias_sim        ),
        .ip_bias_valid_sim_o   (ip_bias_valid_sim  ),
        .rd_buf_done_sim_o     (rd_buf_done_sim    ),
        .accum_data_sim_o      (accum_data_sim     ),
`endif   
        .ip_en_i          (ip_en          ),
        .cur_layer_index_o(cur_layer_index),
        .ip_layer_done_o  (ip_layer_done  ),
        .ip_done_o        (ip_done        ),
        .rd_bram_en_o     (rd_bram_en     ),
        .rd_bram_addr_o   (rd_bram_addr   ),
        .rd_bram_data_i   (rd_bram_data   ),
        .rd_ddr_done_i    (rd_ddr_done    ),
        .rd_ddr_en_o      (ddr3_rd_en     ),
        .rd_burst_num_o   (rd_burst_num   ),
        .rd_start_addr_o  (rd_start_addr  ),
        .wr_buf_done_i    (wr_buf_done    ),
        .param_buf_full_o (param_buf_full ),
        .param_buf_busy_o (param_buf_busy ),
        .ip_buf_addr_o    (ip_buf_addr    ),
        .ip_param_i       (ip_param       ),
        .output_valid_o   (output_valid   ),
        .output_en_o      (output_en      ),
        .ip_addr_o        (ip_addr        ),
        .ip_data_o        (ip_data        )
    );

    //====================================
    //  buf selector
    //==================================== 
    wire conv_buf_en;
    wire ip_buf_0_en;
    wire ip_buf_1_en;

    wire [FW-1:0] conv_buf_rd_data; 
    wire [FW-1:0] ip_buf_0_rd_data; 
    wire [FW-1:0] ip_buf_1_rd_data; 

    wire ip_buf_0_valid;
    wire [FW-1:0] ip_buf_0_wr_data; 
    wire ip_buf_1_valid;
    wire [FW-1:0] ip_buf_1_wr_data; 

    wire [15-1:0] conv_buf_rd_addr;
    wire [12-1:0] ip_buf_0_addr;
    wire [10-1:0] ip_buf_1_addr;
    buf_sel
    #(
        .FW(FW)
    )
    buf_sel_U
    (
        .cur_layer_index_i  (cur_layer_index ),

        .rd_bram_en_i       (rd_bram_en      ),
        .wr_bram_en_i       (output_en       ),
        .conv_buf_en_o      (conv_buf_en     ),
        .ip_buf_0_en_o      (ip_buf_0_en     ),
        .ip_buf_1_en_o      (ip_buf_1_en     ),

        .conv_buf_data_i    (conv_buf_rd_data),
        .ip_buf_0_data_i    (ip_buf_0_rd_data),
        .ip_buf_1_data_i    (ip_buf_1_rd_data),
        .ip_data_in_o       (rd_bram_data    ), 

        .ip_data_out_i      (ip_data         ),
        .ip_data_valid_i    (output_valid    ),
        .ip_buf_0_valid_o   (ip_buf_0_valid  ),
        .ip_buf_0_data_o    (ip_buf_0_wr_data),
        .ip_buf_1_valid_o   (ip_buf_1_valid  ),
        .ip_buf_1_data_o    (ip_buf_1_wr_data),

        .rd_bram_addr_i     (rd_bram_addr    ),
        .wr_bram_addr_i     (ip_addr         ),
        .conv_buf_addr_o    (conv_buf_rd_addr),
        .ip_buf_0_addr_o    (ip_buf_0_addr   ),
        .ip_buf_1_addr_o    (ip_buf_1_addr   )
    );

    //====================================
    //  externel data and param  buffer
    //==================================== 
    ip_mem_interface
    #(
        .FW (FW ),
        .DW (DW ),
        .CDW(CDW),
        .WL (WL )
    )
    ip_mem_interface_U
    (
        .clk_i (clk ),
        .rstn_i(~rst),
        .param_buf_en_i  (ddr3_rd_data_valid    ),
        .param_buf_full_i(param_buf_full        ),
        .param_i         (ddr3_rd_data          ),
        .param_buf_busy_i(param_buf_busy        ),
        .param_buf_addr_i(ip_buf_addr           ),
        .wr_buf_done_o   (wr_buf_done           ),
        .ip_param_o      (ip_param              ),
        .conv_buf_ena_i  (1'b1                  ),
        .conv_buf_wea_i  (prepare_data_valid    ),
        .conv_buf_addra_i(prepare_data_addr[9:0]),
        .conv_buf_dina_i (prepare_data          ),
        .conv_buf_enb_i  (conv_buf_en           ),
        .conv_buf_addrb_i(conv_buf_rd_addr      ),
        .conv_buf_doub_o (conv_buf_rd_data      ),
        .ip_buf0_ena_i   (ip_buf_0_en           ),
        .ip_buf0_wea_i   (ip_buf_0_valid        ),
        .ip_buf0_addra_i (ip_buf_0_addr         ),
        .ip_buf0_dina_i  (ip_buf_0_wr_data      ),
        .ip_buf0_douta_o (ip_buf_0_rd_data      ),
        .ip_buf1_ena_i   (ip_buf_1_en           ),
        .ip_buf1_wea_i   (ip_buf_1_valid        ),
        .ip_buf1_addra_i (ip_buf_1_addr         ),
        .ip_buf1_dina_i  (ip_buf_1_wr_data      ),
        .ip_buf1_douta_o (ip_buf_1_rd_data      )
    );

    //====================================
    //  simulation control
    //==================================== 
    validate_module
    #(
        .FW(FW)
    )
    validate_model_U
    (
        .sim_clk_i (clk   ),
        .sim_rstn_i(~rst),
        .sim_ip_data_i         (ip_data            ),
        .sim_ip_addr_i         (ip_addr            ),
        .sim_ip_data_valid_i   (output_valid       ),
        .sim_ip_done_i         (ip_done            ),
`ifdef SIM
        .sim_cur_layer_index_i (cur_layer_index    ),
`endif
        .sim_ip_out_en_i       (output_en          )
    );

    //====================================
    //  record simulation data
    //==================================== 
    initial begin
        $vcdplusfile( "sim_result.vpd" );
        $vcdpluson( 0, inner_product_tb);
        $vcdplusmemon();
        $vcdplusglitchon;
        $vcdplusflush;

        //$dumpfile("top.vcd");
        //$dumpvars(0, inner_product_tb);
    end
endmodule


module prepare_ip_data_sim
#(
    parameter FW = 32,
    parameter CDW = 1024,
    parameter iNN = 25088
)
(
    input tb_clk_i,
    input tb_rstn_i,
    input tb_en_i,

    output reg          tb_done_o,
    output reg [CDW-1:0] tb_data_o,
    output     [12-1:0] tb_addr_o,
    output reg          tb_data_valid_o
);
    localparam PACKAGE_LEN =  CDW / FW;
    localparam RD_TOTAL = iNN / (PACKAGE_LEN);

    integer file_handle = 0;
    integer r;
    reg [12-1:0] rd_count;
    reg [CDW-1:0] tb_data_reg;
    assign tb_addr_o = rd_count;
    always @(negedge tb_rstn_i or posedge tb_clk_i) begin
        if(~tb_rstn_i) begin
            if(~file_handle) begin
                `ifdef FP16
                file_handle <= $fopen("/home/niuyue/cnn_vgg_proj/git-proj/VGG_verilog/test/data/fc6_input_fp16.bin", "r");
                `else
                file_handle <= $fopen("/home/niuyue/cnn_vgg_proj/git-proj/VGG_verilog/test/data/fc6_input.bin", "r");
                `endif
            end
            rd_count   <= 12'd0;
            tb_done_o  <= 1'b0;

            tb_data_reg     <= {CDW{1'b0}};
            tb_data_valid_o <= 1'b0;
        end
        else if (tb_en_i==1'b1 && tb_done_o == 1'b0) begin
            if(rd_count==RD_TOTAL) begin
                tb_data_reg     <= {CDW{1'b0}};
                tb_data_valid_o <= 1'b0;
                rd_count        <= 12'd0;

                tb_done_o        <= 1'b1;

                //r = $fclose(file_handle);
            end
            else begin
                r = $fread(tb_data_reg, file_handle);
                tb_data_valid_o <= 1'b1;

                tb_done_o <= 1'b0;
            end
            if(tb_data_valid_o==1'b1)
                rd_count  <= rd_count + 1'b1;
        end
    end
    generate
        genvar i;
        for(i=0; i < PACKAGE_LEN; i = i+1) begin
            always @(tb_data_reg) begin
`ifdef FP16
                tb_data_o[i*FW+15:i*FW+8]    = tb_data_reg[(PACKAGE_LEN-i-1)*FW+7:(PACKAGE_LEN-i-1)*FW];
                tb_data_o[i*FW+7:i*FW+0]     = tb_data_reg[(PACKAGE_LEN-i-1)*FW+15:(PACKAGE_LEN-i-1)*FW+8];
`else
                tb_data_o[i*FW+FW-1:i*FW+24] = tb_data_reg[(PACKAGE_LEN-i-1)*FW+7:(PACKAGE_LEN-i-1)*FW];
                tb_data_o[i*FW+23:i*FW+16]   = tb_data_reg[(PACKAGE_LEN-i-1)*FW+15:(PACKAGE_LEN-i-1)*FW+8];
                tb_data_o[i*FW+15:i*FW+8]    = tb_data_reg[(PACKAGE_LEN-i-1)*FW+23:(PACKAGE_LEN-i-1)*FW+16];
                tb_data_o[i*FW+7:i*FW+0]     = tb_data_reg[(PACKAGE_LEN-i-1)*FW+31:(PACKAGE_LEN-i-1)*FW+23];
`endif
            end
        end
    endgenerate

endmodule

module rd_ddr_sim
#(
    parameter FW = 32,
    parameter DW = 512,
    parameter WL = 288
)
(
    input  tb_clk_i,
    input  tb_rstn_i,
    input  tb_en_i,
    output [DW-1:0] tb_param_o,
    output          tb_param_valid_o
);
    localparam DDR_RD_TOTAL = WL / (DW/FW);

    integer r;
    integer file_handle = 0;
    integer ddr_rd_count;

    reg _rd_ddr_busy_;
    reg [DW-1:0] _tb_param_;
    reg          _tb_param_valid_;

    assign tb_param_o = _tb_param_;
    assign tb_param_valid_o = _tb_param_valid_;
    always @(negedge tb_rstn_i or posedge tb_clk_i) begin
        if(tb_rstn_i==1'b0) begin
            _rd_ddr_busy_ <= 1'b0;
            ddr_rd_count  <= 0;
            _tb_param_       <= {DW{1'b0}};
            _tb_param_valid_ <= 1'b0;

            if(~file_handle) begin
                file_handle <= $fopen("/home/niuyue/cnn_vgg_proj/git-proj/VGG_verilog/test/data/ip_param.bin", "r");
            end
        end
        else begin 
            if (tb_en_i==1'b1) begin
                _rd_ddr_busy_ <= 1'b1;
                ddr_rd_count  <= 0;
            end
            else if (ddr_rd_count == DDR_RD_TOTAL-1) begin
                _rd_ddr_busy_ <= 1'b0;
            end
            else if(ddr_rd_count == DDR_RD_TOTAL) begin
                //_rd_ddr_busy_ <= 1'b0;

                _tb_param_       <= {DW{1'b0}};
                _tb_param_valid_ <= 1'b0;
            end   
            if(_rd_ddr_busy_== 1'b1) begin
                _tb_param_valid_ <= 1'b1; 
                ddr_rd_count     <= ddr_rd_count + 1;

                #1 r = $fread(_tb_param_, file_handle);
            end
        end
    end

endmodule

module validate_module
#(
    parameter FW = 32
)
(
    input sim_clk_i,
    input sim_rstn_i,
    `ifdef SIM
    input [3-1:0]  sim_cur_layer_index_i,
    `endif
    input [FW-1:0] sim_ip_data_i,
    input [12-1:0] sim_ip_addr_i,
    input sim_ip_data_valid_i,
    input sim_ip_done_i,
    input sim_ip_out_en_i
);

    integer r;
    //integer file_handle = 0;
    integer data_count;
    reg [FW-1:0] _sim_ref_data_;
    wire [FW-1:0] _sim_ref_data_bend_;

    `ifdef FP16
    assign _sim_ref_data_bend_[15:8]  = _sim_ref_data_[7:0];
    assign _sim_ref_data_bend_[7:0]   = _sim_ref_data_[15:8];
    `else
    assign _sim_ref_data_bend_[31:24] = _sim_ref_data_[7:0];
    assign _sim_ref_data_bend_[23:16] = _sim_ref_data_[15:8];
    assign _sim_ref_data_bend_[15:8]  = _sim_ref_data_[23:16];
    assign _sim_ref_data_bend_[7:0]   = _sim_ref_data_[31:24];
    `endif
    always @(posedge sim_clk_i or negedge sim_rstn_i) begin
        if(~sim_rstn_i) begin
           //if(~file_handle)
            //    file_handle = $fopen("/home/niuyue/cnn_vgg_proj/git-proj/VGG_verilog/test/data/fc6_output.bin", "r");
            // data_count  = 0;
        end
        else if(sim_ip_data_valid_i == 1'b1) begin
            // out check is done by DirectC
            // r = $fread(_sim_ref_data_, file_handle);
            // if(_sim_ref_data_bend_ == sim_ip_data_i) begin
            //     $display("%t] Data check passed -> [ref: %x----veri: %x].", $time, _sim_ref_data_bend_, sim_ip_data_i);
            // end
            // else begin
            //     $display("%t] Data check failed -> [ref: %x----veri: %x].", $time, _sim_ref_data_bend_, sim_ip_data_i);
            // end
            // data_count <= data_count + 1;
            $display("%t] %dth layer: %dth neuron finished.", $time, `ifdef SIM sim_cur_layer_index_i `endif, sim_ip_addr_i);
        end
    end

    always @(sim_ip_done_i) begin
        if(sim_ip_done_i) begin
            $finish;
        end
    end

endmodule
