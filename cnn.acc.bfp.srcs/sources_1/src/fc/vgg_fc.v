/*
  --fully-connected top simulation model
*/
//`define SIM

module vgg_fc
#(
    parameter EW = 5,
    parameter MW = 10,
    parameter FW = 16,
    parameter WL = 32,
    parameter DW = 512,
    parameter CDW = 64*16,  //data from llayer of conv
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,   //ddr data width 
    parameter APP_DATA_WIDTH = 512, 
    parameter DATA_NUM_BITS  = 20
)
(
    //--clock signal
    input                         clk_i,
    input                         rst_i,
    input                         init_calib_complete_i,
    //--ddr rd/wr interface
    input                         app_rdy_i,
    output                        app_en_o,
    output [3-1:0]                app_cmd_o,
    output [ADDR_WIDTH-1:0]       app_addr_o,
    input                         ddr3_wr_en_i,     //0
    input  [DATA_NUM_BITS-1:0]    wr_burst_num_i,   //0
    input  [ADDR_WIDTH-1:0]       wr_start_addr_i,  //0
    input  [DATA_WIDTH-1:0]       wr_data_i,        //0
    input                         app_wdf_rdy_i,
    output                        app_wdf_wren_o,
    output [DATA_WIDTH-1:0]       app_wdf_data_o, //ddr out
    output [64-1:0]               app_wdf_mask_o,
    output                        app_wdf_end_o,
    output                        arbitor_req_o,
    input                         arbitor_ack_i,
    input                         app_rd_data_valid_i, //ddr in
    input  [DATA_WIDTH-1:0]       app_rd_data_i,
    input                         app_rd_data_end_i,
    output                        fetch_data_en_o,
    output                        wr_ddr_done_o,
    //--conv buf write data
    input                         prepare_data_valid_i, //data from llayer of conv
    input  [10-1:0]               prepare_data_addr_i,
    input  [CDW-1:0]              prepare_data_i,
    input                         prepare_done_i,
    //--ip status
    output                        conv_buf_free_o,
    /*(*mark_debug="TRUE"*)*/output   ip_done_o,      //inner product
    //--export data
    /*(*mark_debug="TRUE"*)*/output   exp_done_o  //finished exporting data of last fc layer 
);

    `ifdef SIM
    //--sim port
    wire [12-1:0]       pixel_pos_sim;
    wire [5-1:0]        channel_pos_sim;
    wire [4-1:0]        sec_pos_sim;
    wire [FW-1:0]       ip_data_in_sim;
    wire                ip_data_in_valid_sim;
    wire [15-1:0]       ip_bram_addr_sim;
    wire [9-1:0]        ip_buf_addr_sim; 
    wire [FW-1:0]       ip_weight_sim;
    wire                ip_weight_valid_sim;
    wire [FW-1:0]       ip_bias_sim;
    wire                ip_bias_valid_sim;
    wire                rd_buf_done_sim;
    wire [FW-1:0]       accum_data_sim;
    wire                ip_out_valid_sim;
    wire                ip_out_en_sim;
    wire [FW-1:0]       ip_data_out_sim;
    wire [12-1:0]       ip_addr_out_sim;
    reg  [32-1:0]       ip_data_fp32_sim;
    wire [3-1:0]        cur_layer_index_sim;
    wire                ip_layer_done_sim;
    wire                ip_done_sim; //all fc layers are done
    `endif

    fc
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
    fc_layer
    (
        `ifdef SIM
        .pixel_pos_sim_o       (pixel_pos_sim       ),
        .channel_pos_sim_o     (channel_pos_sim     ),
        .sec_pos_sim_o         (sec_pos_sim         ),
        .ip_data_in_sim_o      (ip_data_in_sim      ),
        .ip_data_in_valid_sim_o(ip_data_in_valid_sim),
        .ip_bram_addr_sim_o    (ip_bram_addr_sim    ),
        .ip_buf_addr_sim_o     (ip_buf_addr_sim     ),
        .ip_weight_sim_o       (ip_weight_sim       ),
        .ip_weight_valid_sim_o (ip_weight_valid_sim ),
        .ip_bias_sim_o         (ip_bias_sim         ),
        .ip_bias_valid_sim_o   (ip_bias_valid_sim   ),
        .rd_buf_done_sim_o     (rd_buf_done_sim     ),
        .accum_data_sim_o      (accum_data_sim      ),
        .ip_out_valid_sim_o    (ip_out_valid_sim    ),
        .ip_out_en_sim_o       (ip_out_en_sim       ),
        .ip_data_out_sim_o     (ip_data_out_sim     ),
        .ip_addr_out_sim_o     (ip_addr_out_sim     ),
        .cur_layer_index_sim_o (cur_layer_index_sim ),
        .ip_layer_done_sim_o   (ip_layer_done_sim   ),
        .ip_done_sim_o         (ip_done_sim         ),
        `endif
        //--clock signal
        .clk_i (clk_i),
        .rst_i (rst_i),
        .init_calib_complete_i(init_calib_complete_i),
        //--ddr rd/wr interface
        .app_rdy_i            (app_rdy_i         ),
        .app_en_o             (app_en_o          ),
        .app_cmd_o            (app_cmd_o         ),
        .app_addr_o           (app_addr_o        ),
        .ddr3_wr_en_i         (ddr3_wr_en_i      ), //0
        .wr_burst_num_i       (wr_burst_num_i    ), //0
        .wr_start_addr_i      (wr_start_addr_i   ), //0
        .wr_data_i            (wr_data_i         ), //0
        .app_wdf_rdy_i        (app_wdf_rdy_i     ),
        .app_wdf_wren_o       (app_wdf_wren_o    ),
        .app_wdf_data_o       (app_wdf_data_o    ),
        .app_wdf_mask_o       (app_wdf_mask_o    ),
        .app_wdf_end_o        (app_wdf_end_o     ),
        .fetch_data_en_o      (fetch_data_en_o   ),
        .wr_ddr_done_o        (wr_ddr_done_o      ),
        .arbitor_req_o        (arbitor_req_o      ),
        .arbitor_ack_i        (arbitor_ack_i      ),
        .app_rd_data_valid_i  (app_rd_data_valid_i),
        .app_rd_data_i        (app_rd_data_i      ),
        .app_rd_data_end_i    (app_rd_data_end_i  ),
        //--conv buf data write
        .prepare_data_addr_i  (prepare_data_addr_i ),
        .prepare_data_valid_i (prepare_data_valid_i),
        .prepare_data_i       (prepare_data_i      ),
        .prepare_done_i       (prepare_done_i      ),
        //--ip status
        .conv_buf_free_o      (conv_buf_free_o),
        .ip_done_o            (ip_done_o      ),
        //--export data
        .exp_done_o           (exp_done_o     )
    );

    `ifdef SIM
    //====================================
    //  simulation control
    //==================================== 
    validate
    #(
        .FW(FW)
    )
    validate_U
    (
        .sim_clk_i (clk_i ),
        .sim_rstn_i(~rst_i),
        .sim_ip_done_i         (ip_done_sim         ),
        .sim_exp_done_i        (exp_done_o          ),
        .sim_ip_data_in_valid_i(ip_data_in_valid_sim),
        .sim_ip_bias_valid_i   (ip_bias_valid_sim   ),
        .sim_ip_weight_valid_i (ip_weight_valid_sim ),
        .sim_ip_out_valid_i    (ip_out_valid_sim    ),
        .sim_ip_out_en_i       (ip_out_en_sim       ),
        .sim_rd_buf_done_i     (rd_buf_done_sim     ),
        .sim_ip_layer_done_i   (ip_layer_done_sim   ),
        .sim_pixel_pos_i       (pixel_pos_sim       ),
        .sim_channel_pos_i     (channel_pos_sim     ),
        .sim_sec_pos_i         (sec_pos_sim         ),
        .sim_ip_data_in_i      (ip_data_in_sim      ),
        .sim_ip_bias_i         (ip_bias_sim         ),
        .sim_ip_weight_i       (ip_weight_sim       ),
        .sim_ip_bram_addr_i    (ip_bram_addr_sim    ),
        .sim_accum_data_i      (accum_data_sim      ),
        .sim_ip_data_out_i     (ip_data_out_sim     ),
        .sim_ip_addr_out_i     (ip_addr_out_sim     ),
        .sim_cur_layer_index_i (cur_layer_index_sim ),
        .sim_ip_buf_addr_i     (ip_buf_addr_sim     )
    );
    `endif
endmodule
