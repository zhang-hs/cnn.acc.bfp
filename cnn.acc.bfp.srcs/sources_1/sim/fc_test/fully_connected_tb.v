/*
  --test for fully_connected_op.v
*/
`define FAST_DDR
`include "common.v"

`ifndef FAST_DDR
`timescale 1 ps / 100 fs
`endif
//--DiretC API
`include "sim_tb.inc"

module fully_connected_tb;

    //--decide float width
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
    parameter APP_DATA_WIDTH = 512;

    localparam FW = EW + MW+1;
    localparam CDW = 64*FW; // data width from conv module
    //wire rstn_i;
    //wire clk_i;
    
    //--prepare ip data to bram
    reg  prepare_en;
    wire prepare_done;
    wire [CDW-1:0]prepare_data;
    wire prepare_data_valid;
    wire [12-1:0] prepare_data_addr;
    //--ddr arbitor
    wire arbitor_req;
    wire arbitor_ack;
    //--ip status
    wire conv_buf_free;
    wire ip_done;
    wire batch_done;
    //--export data
    wire exp_done;

    //====================================
    //  ddr model and rd_wr_interface
    //====================================
    `ifdef FAST_DDR
    `include "fast_ddr_model.inc"
    `else
    `include "ddr_model.inc"
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
    //  ddr arbitor
    //==================================== 
    //--pcie_write
    reg pcie_write_en;
    always @(posedge rst or posedge clk) begin
        if(rst) begin
            pcie_write_en <= 1'b1; 
        end
        else begin
            if(wr_ddr_done && pcie_write_en) begin
                pcie_write_en <= 1'b0;
            end
        end
    end

    ddr_iface_arbiter
    ddr_iface_arbiter_U
    (
        .clk(clk),
        .rst_n(~rst),
        //--ddr
        .ddr_rd_data_valid(app_rd_data_valid),
        .ddr_rdy          (app_rdy),
        .ddr_wdf_rdy      (app_wdf_rdy),
        .ddr_rd_data      (app_rd_data),
        .ddr_rd_data_end  (app_rd_data_end),
        .ddr_addr         (app_addr),
        .ddr_cmd          (app_cmd),
        .ddr_en           (app_en),
        .ddr_wdf_data     (app_wdf_data),
        .ddr_wdf_mask     (app_wdf_mask),
        .ddr_wdf_end      (app_wdf_end),
        .ddr_wdf_wren     (app_wdf_wren),
        .arb_data_ready   (wr_ddr_done),
        .arb_cnn_finish   (1'b0),
        //--pcie
        .arb_pcie_addr    (arb_app_addr),
        .arb_pcie_cmd     (arb_app_cmd),
        .arb_pcie_en      (arb_app_en&&pcie_write_en),
        .arb_pcie_wdf_data(arb_app_wdf_data),
        .arb_pcie_wdf_mask(arb_app_wdf_mask), // stuck at 64'b1
        .arb_pcie_wdf_end (arb_app_wdf_end),  // stuck at 1'b1
        .arb_pcie_wdf_wren(arb_app_wdf_wren),
        // vgg module conv.
        .arb_conv_req(1'b0),
        .arb_conv_grant(),
        .arb_conv_addr(30'd0),
        .arb_conv_cmd(3'd0),
        .arb_conv_en(1'b0),
        .arb_conv_wdf_data(512'd0),
        .arb_conv_wdf_mask(), // stuck at 64'b1
        .arb_conv_wdf_end(),  // stuck at 1'b1
        .arb_conv_wdf_wren(),
        // vgg module fc.
        .arb_fc_req     (arbitor_req),
        .arb_fc_grant   (arbitor_ack),
        .arb_fc_addr    (arb_app_addr),
        .arb_fc_cmd     (arb_app_cmd),
        .arb_fc_en      (arb_app_en),
        .arb_fc_wdf_data(arb_app_wdf_data),
        .arb_fc_wdf_mask(arb_app_wdf_mask), // stuck at 64'b1
        .arb_fc_wdf_end (arb_app_wdf_end),  // stuck at 1'b1
        .arb_fc_wdf_wren(arb_app_wdf_wren)
    );

    //====================================
    //  top fully-connected module
    //==================================== 
    vgg_fc
    #(
        .EW(EW),
        .MW(MW),
        .FW(FW),
        .WL(WL),
        .DW(DW),
        .CDW(CDW),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .APP_DATA_WIDTH(APP_DATA_WIDTH),
        .DATA_NUM_BITS(DATA_NUM_BITS)
    )
    vgg_fc_U
    (
        //--clock signal
        .clk_i (clk),
        .rst_i (rst),
        .init_calib_complete_i(init_calib_complete),
        //--ddr rd/wr interface
        .app_rdy_i            (app_rdy            ),
        .app_en_o             (arb_app_en         ),
        .app_cmd_o            (arb_app_cmd        ),
        .app_addr_o           (arb_app_addr       ),
        .ddr3_wr_en_i         (ddr3_wr_en         ),
        .wr_burst_num_i       (wr_burst_num       ),
        .wr_start_addr_i      (wr_start_addr      ),
        .wr_data_i            (ddr3_wr_data       ),
        .app_wdf_rdy_i        (app_wdf_rdy        ),
        .app_wdf_wren_o       (arb_app_wdf_wren   ),
        .app_wdf_data_o       (arb_app_wdf_data   ),
        .app_wdf_mask_o       (arb_app_wdf_mask   ),
        .app_wdf_end_o        (arb_app_wdf_end    ),
        .fetch_data_en_o      (fetch_data_en      ),
        .wr_ddr_done_o        (wr_ddr_done        ),
        .arbitor_req_o        (arbitor_req        ),
        .arbitor_ack_i        (arbitor_ack        ),
        .app_rd_data_valid_i  (app_rd_data_valid  ),
        .app_rd_data_i        (app_rd_data        ),
        .app_rd_data_end_i    (app_rd_data_end    ),
        //--conv buf data write
        .prepare_data_addr_i  (prepare_data_addr  ),
        .prepare_data_valid_i (prepare_data_valid ),
        .prepare_data_i       (prepare_data       ),
        .prepare_done_i       (prepare_done       ),
        //--ip status
        .conv_buf_free_o      (conv_buf_free      ),
        .ip_done_o            (ip_done            ),
        .batch_done_o         (batch_done         ),
        //--export data
        .exp_done_o           (exp_done           )
    );

    //====================================
    //  record simulation data
    //==================================== 
    initial begin
        $vcdplusfile( "sim_result.vpd" );
        $vcdpluson( 0, fully_connected_tb);
        $vcdplusmemon();
        $vcdplusglitchon;
        $vcdplusflush;

        //$dumpfile("top.vcd");
        //$dumpvars(0, fully_connected_tb);
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
                file_handle <= $fopen("./../test/data/fc6_input_fp16.bin", "r");
                `else
                file_handle <= $fopen("./../test/data/fc6_input.bin", "r");
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
                file_handle <= $fopen("./../src/test/data/ip_param.bin", "r");
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
    input [12-1:0] sim_ip_addr_i,
    input sim_ip_data_valid_i,
    input sim_ip_done_i,
    input sim_exp_done_i,
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

    always @(sim_exp_done_i) begin
        if(sim_exp_done_i) begin
             #1500 $finish;
        end
    end

endmodule
