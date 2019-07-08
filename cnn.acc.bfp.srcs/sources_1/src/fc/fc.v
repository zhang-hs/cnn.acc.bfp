/* 
  --top moduel for fully-connected layer
*/
//`define SIM

module fc
#(
    parameter EW = 5,
    parameter MW = 10,
    parameter FW = 16,
    parameter WL = 32,
    parameter DW = 512,
    parameter CDW = 64*16, //llayer conv
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512, //ddr
    parameter APP_DATA_WIDTH = 512,
    parameter DATA_NUM_BITS  = 20
)
(
    `ifdef SIM
    //--necessary sim signal
    output [12-1:0]         pixel_pos_sim_o,
    output [5-1:0]          channel_pos_sim_o,
    output [4-1:0]          sec_pos_sim_o,
    output [FW-1:0]         ip_data_in_sim_o,
    output                  ip_data_in_valid_sim_o,
    output [15-1:0]         ip_bram_addr_sim_o,
    output reg [9-1:0]      ip_buf_addr_sim_o,
    output [FW-1:0]         ip_weight_sim_o,
    output                  ip_weight_valid_sim_o,
    output [FW-1:0]         ip_bias_sim_o,
    output                  ip_bias_valid_sim_o,
    output                  rd_buf_done_sim_o,
    output [FW-1:0]         accum_data_sim_o,
    output                  ip_out_valid_sim_o,
    output                  ip_out_en_sim_o,
    output [FW-1:0]         ip_data_out_sim_o,
    output [12-1:0]         ip_addr_out_sim_o,
    output [3-1:0]          cur_layer_index_sim_o,
    output                  ip_layer_done_sim_o,
    output                  ip_done_sim_o,
    `endif
    //--clock signal
    input                       clk_i,
    input                       rst_i,
    input                       init_calib_complete_i,
    //--ddr rd/wr interface
    input                       app_rdy_i,
    /*(*mark_debug="TRUE"*)*/output app_en_o,
    /*(*mark_debug="TRUE"*)*/output [3-1:0] app_cmd_o,
    output [ADDR_WIDTH-1:0]     app_addr_o,
    input                       ddr3_wr_en_i,   //0
    input  [DATA_NUM_BITS-1:0]  wr_burst_num_i, //0
    input  [ADDR_WIDTH-1:0]     wr_start_addr_i,//0
    input  [DATA_WIDTH-1:0]     wr_data_i,      //0
    input                       app_wdf_rdy_i,
    output                      app_wdf_wren_o,
    output [DATA_WIDTH-1:0]     app_wdf_data_o,
    output [64-1:0]             app_wdf_mask_o,
    output                      app_wdf_end_o,
    output                      arbitor_req_o,
    input                       arbitor_ack_i,
    input                       app_rd_data_valid_i,
    input  [DATA_WIDTH-1:0]     app_rd_data_i,
    input                       app_rd_data_end_i,
    output                      fetch_data_en_o,
    output                      wr_ddr_done_o,
    //--conv buf write data
    input                       prepare_data_valid_i,
    input  [10-1:0]             prepare_data_addr_i,
    input  [CDW-1:0]            prepare_data_i,
    input                       prepare_done_i,
    //--ip status
    output                      conv_buf_free_o,
    output                      ip_done_o,
    //--export data
    output                      exp_done_o
);
 
    wire                      ui_rstn;
    //--rd_wr_path
    /*(*mark_debug="TRUE"*)*/wire wr_ddr_done;
    wire                      rd_ddr_done;
    wire                      ddr3_rd_en;
    wire [ADDR_WIDTH-1:0]     rd_start_addr;
    wire [DATA_NUM_BITS-1:0]  rd_burst_num;
    wire                      ddr3_rd_data_valid;
    wire [DATA_WIDTH-1:0]     ddr3_rd_data;
    //--inner product
    /*(*mark_debug="TRUE"*)*/wire [3-1:0]              cur_layer_index;
    wire                      ip_layer_done;
    wire                      ip_proc;
    wire                      ip_done;
    wire                      rd_bram_en;
    wire                      arbitor_rd_en;
    wire [15-1:0]             rd_bram_addr;
    wire [FW-1:0]             rd_bram_data;
    wire                      wr_buf_done;
    wire                      wr_buf_sel;
    wire [2-1:0]              param_buf_full;
    wire [2-1:0]              param_buf_busy;
    wire [9-1:0]              ip_buf_addr;
    wire [FW-1:0]             ip_param;
    /*(*mark_debug="TRUE"*)*/wire                      output_valid; 
    wire                      output_en;
    wire [12-1:0]             ip_addr;
    /*(*mark_debug="TRUE"*)*/wire [FW-1:0]             ip_data;
    //--export data status
    /*(*mark_debug="TRUE"*)*/wire exp_active;
    wire                      exp_rd_bram_en;
    wire [FW-1:0]             exp_rd_bram_data;
    wire [10-1:0]             exp_rd_bram_addr;
    wire                      exp_wr_ddr_en;
    wire [5-1:0]              exp_wr_burst_num;
    wire [ADDR_WIDTH-1:0]     exp_wr_start_addr;
    wire [DATA_WIDTH-1:0]     exp_wr_data;
    //--valid write ddr signal
    reg                       ast_wr_ddr_en;
    reg  [DATA_NUM_BITS-1:0]  ast_wr_burst_num;
    reg  [ADDR_WIDTH-1:0]     ast_wr_start_addr;
    reg  [DATA_WIDTH-1:0]     ast_wr_ddr_data;
    //--valid read bram signal
    reg                       ast_ip_buf_1_en;
    reg  [10-1:0]             ast_ip_buf_1_addr;
    //--buf sel
    wire                      conv_buf_en;
    wire                      ip_buf_0_en;
    wire                      ip_buf_1_en;
    wire [FW-1:0]             conv_buf_rd_data; 
    wire [FW-1:0]             ip_buf_0_rd_data; 
    wire [FW-1:0]             ip_buf_1_rd_data; 
    wire                      ip_buf_0_valid;
    wire [FW-1:0]             ip_buf_0_wr_data; 
    wire                      ip_buf_1_valid;
    wire [FW-1:0]             ip_buf_1_wr_data; 
    wire [15-1:0]             conv_buf_rd_addr;
    wire [12-1:0]             ip_buf_0_addr;
    wire [10-1:0]             ip_buf_1_addr;

    assign arbitor_req_o = arbitor_rd_en || exp_active;
    //====================================
    //  export ip data or not
    //====================================    
    `ifdef SIM
    wire sim_rd_ddr_done;
    wire sim_rd_ddr_en;
    wire [6-1:0] sim_rd_burst_num;
    wire [ADDR_WIDTH-1:0] sim_rd_start_addr;
    assign sim_rd_ddr_done = rd_ddr_done;
    `endif
    export_data
    #(
        .iDW(FW),
        .oDW(DATA_WIDTH),
        .oAW(ADDR_WIDTH)
    )
    export_data_U
    (
        `ifdef SIM
         .sim_rd_ddr_done_i  (sim_rd_ddr_done),
         .sim_rd_ddr_en_o    (sim_rd_ddr_en),
         .sim_rd_burst_num_o (sim_rd_burst_num),
         .sim_rd_start_addr_o(sim_rd_start_addr),
        `endif
        .clk_i (clk_i  ),
        .rstn_i(ui_rstn),
        //--export staus
        .ip_done_i   (ip_done      ),
        .exp_ack_i   (arbitor_ack_i),
        .exp_active_o(exp_active   ),
        .exp_done_o  (exp_done_o   ),
        //--fetch data from bram
        .rd_en_o     (exp_rd_bram_en  ),
        .bram_data_i (ip_buf_1_rd_data),
        .rd_addr_o   (exp_rd_bram_addr),
        //--write data to ddr
        .wr_ddr_done_i  (wr_ddr_done      ), //current burst write done
        .fetch_data_en_i(fetch_data_en_o  ),
        .wr_ddr_en_o    (exp_wr_ddr_en    ),
        .wr_burst_num_o (exp_wr_burst_num ),
        .wr_start_addr_o(exp_wr_start_addr),
        .wr_data_o      (exp_wr_data      )
    );
    //--decide whether signal from exp_data is valid
    always @(exp_active or exp_rd_bram_en or exp_rd_bram_addr or exp_wr_ddr_en or exp_wr_burst_num or exp_wr_start_addr or exp_wr_data or
             ip_buf_1_en or ip_buf_1_addr or ddr3_wr_en_i or wr_burst_num_i or wr_start_addr_i or wr_data_i) begin
        if(exp_active) begin
            //--read bram signal
            ast_ip_buf_1_en   = exp_rd_bram_en;
            ast_ip_buf_1_addr = exp_rd_bram_addr;
            //--write ddr signal
            ast_wr_ddr_en     = exp_wr_ddr_en;
            ast_wr_burst_num  = exp_wr_burst_num;
            ast_wr_start_addr = exp_wr_start_addr;
            ast_wr_ddr_data   = exp_wr_data;
        end
        else begin
            //--read bram signal
            ast_ip_buf_1_en   = ip_buf_1_en;
            ast_ip_buf_1_addr = ip_buf_1_addr;
            //--write ddr signal
            ast_wr_ddr_en     = ddr3_wr_en_i;   //0, disabled
            ast_wr_burst_num  = wr_burst_num_i; //0
            ast_wr_start_addr = wr_start_addr_i;//0
            ast_wr_ddr_data   = wr_data_i;      //0
        end
    end

    //====================================
    //  read/write interface with ddr
    //====================================    

    assign wr_ddr_done_o = wr_ddr_done;
    rd_wr_path#
    (
        .ADDR_WIDTH   (ADDR_WIDTH  ),
        .DATA_WIDTH   (DATA_WIDTH  ),
        .DATA_NUM_BITS(DATA_NUM_BITS)
    )
    rd_wr_path_U
    (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .init_calib_complete_i(init_calib_complete_i),
        //--app general signal
        .app_rdy_i            (app_rdy_i            ),
        .app_wdf_rdy_i        (app_wdf_rdy_i        ),
        .app_en_o             (app_en_o             ),
        .app_cmd_o            (app_cmd_o            ),
        .app_addr_o           (app_addr_o           ),
        //--ddr write
        .wr_en_i              (ast_wr_ddr_en        ),
        .wr_burst_num_i       (ast_wr_burst_num     ),
        .wr_start_addr_i      (ast_wr_start_addr    ),
        .wr_data_i            (ast_wr_ddr_data      ),
        .fetch_data_en_o      (fetch_data_en_o      ),
        .wr_ddr_done_o        (wr_ddr_done          ),
        .app_wdf_wren_o       (app_wdf_wren_o       ),
        .app_wdf_mask_o       (app_wdf_mask_o       ),
        .app_wdf_data_o       (app_wdf_data_o       ),
        .app_wdf_end_o        (app_wdf_end_o        ),
        //--ddr read
        .rd_en_i              (`ifdef SIM exp_active ? sim_rd_ddr_en : ddr3_rd_en `else ddr3_rd_en `endif          ),
        .rd_burst_num_i       (`ifdef SIM exp_active ? sim_rd_burst_num : rd_burst_num `else rd_burst_num `endif ),
        .rd_start_addr_i      (`ifdef SIM exp_active ? sim_rd_start_addr : rd_start_addr `else rd_start_addr `endif),
        .app_rd_data_valid_i  (app_rd_data_valid_i  ),
        .app_rd_data_i        (app_rd_data_i        ),
        .app_rd_data_end_i    (app_rd_data_end_i    ),
        .rd_data_valid_o      (ddr3_rd_data_valid   ),
        .rd_data_o            (ddr3_rd_data         ),
        .rd_ddr_done_o        (rd_ddr_done          )
    );
    assign ui_rstn = ~rst_i;

    //====================================
    //  inner product top module
    //==================================== 

    `ifdef SIM
    always @(posedge clk_i) begin
        ip_buf_addr_sim_o <= ip_buf_addr;
    end
    assign cur_layer_index_sim_o = cur_layer_index;
    assign ip_layer_done_sim_o   = ip_layer_done;
    assign ip_done_sim_o         = ip_done;
    assign ip_out_valid_sim_o    = output_valid;
    assign ip_out_en_sim_o       = output_en;
    assign ip_data_out_sim_o     = ip_data;
    assign ip_addr_out_sim_o     = ip_addr;
    `endif
    wire  ip_en;
    assign ip_en           = prepare_done_i && (~exp_active);
    //--assign conv_buf_free_o = ip_layer_done && (cur_layer_index==3'b0);
    assign ip_done_o       = ip_done;
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
        .clk_i  (clk_i ),
        .rstn_i (ui_rstn),
        .wr_ddr_done_i(prepare_done_i),
        .init_calib_complete_i(init_calib_complete_i),
        //--simulation port
        `ifdef SIM
        .pixel_pos_sim_o       (pixel_pos_sim_o       ),
        .channel_pos_sim_o     (channel_pos_sim_o     ),
        .sec_pos_sim_o         (sec_pos_sim_o         ),
        .ip_data_sim_o         (ip_data_in_sim_o      ),
        .ip_data_valid_sim_o   (ip_data_in_valid_sim_o),
        .ip_bram_addr_sim_o    (ip_bram_addr_sim_o    ),
        .ip_weight_sim_o       (ip_weight_sim_o       ),
        .ip_weight_valid_sim_o (ip_weight_valid_sim_o ),
        .ip_bias_sim_o         (ip_bias_sim_o         ),
        .ip_bias_valid_sim_o   (ip_bias_valid_sim_o   ),
        .rd_buf_done_sim_o     (rd_buf_done_sim_o     ),
        .accum_data_sim_o      (accum_data_sim_o      ),
        `endif   
        //--ip status
        .ip_en_i          (ip_en          ),
        .cur_layer_index_o(cur_layer_index),
        .exp_done_i       (exp_done_o     ),
        .ip_layer_done_o  (ip_layer_done  ),
        .ip_proc_o        (ip_proc        ),
        .ip_done_o        (ip_done        ),
        //--read bram
        .rd_bram_en_o     (rd_bram_en     ),
        .rd_bram_addr_o   (rd_bram_addr   ),
        .rd_bram_data_i   (rd_bram_data   ),
        //--read ddr
        .arbitor_ack_i    (arbitor_ack_i  ),
        .rd_ddr_done_i    (rd_ddr_done    ),
        .arbitor_rd_en_o  (arbitor_rd_en  ),
        .rd_ddr_en_o      (ddr3_rd_en     ),
        .rd_burst_num_o   (rd_burst_num   ),
        .rd_start_addr_o  (rd_start_addr  ),
        //--param buf
        .wr_buf_done_i    (wr_buf_done    ),
        .wr_buf_sel_o     (wr_buf_sel     ),
        .conv_buf_free_o  (conv_buf_free_o),
        .param_buf_full_o (param_buf_full ),
        .param_buf_busy_o (param_buf_busy ),
        .ip_buf_addr_o    (ip_buf_addr    ),
        .ip_param_i       (ip_param       ),
        //--inner prodcut output
        .output_valid_o   (output_valid   ),
        .output_en_o      (output_en      ),
        .ip_addr_o        (ip_addr        ),
        .ip_data_o        (ip_data        )
    );

    //====================================
    //  buf selector
    //==================================== 
    buf_sel
    #(
        .FW(FW)
    )
    buf_sel_U
    (
        .cur_layer_index_i  (cur_layer_index ),
        //--enable signal
        .rd_bram_en_i       (rd_bram_en      ),
        .wr_bram_en_i       (output_en       ),
        .conv_buf_en_o      (conv_buf_en     ),
        .ip_buf_0_en_o      (ip_buf_0_en     ),
        .ip_buf_1_en_o      (ip_buf_1_en     ),
        //--ip data in
        .conv_buf_data_i    (conv_buf_rd_data),
        .ip_buf_0_data_i    (ip_buf_0_rd_data),
        .ip_buf_1_data_i    (ip_buf_1_rd_data),
        .ip_data_in_o       (rd_bram_data    ), 
        //--ip data out
        .ip_data_out_i      (ip_data         ),
        .ip_data_valid_i    (output_valid    ),
        .ip_buf_0_valid_o   (ip_buf_0_valid  ),
        .ip_buf_0_data_o    (ip_buf_0_wr_data),
        .ip_buf_1_valid_o   (ip_buf_1_valid  ),
        .ip_buf_1_data_o    (ip_buf_1_wr_data),
        //--addr control
        .rd_bram_addr_i     (rd_bram_addr    ),
        .wr_bram_addr_i     (ip_addr         ),
        .conv_buf_addr_o    (conv_buf_rd_addr),
        .ip_buf_0_addr_o    (ip_buf_0_addr   ),
        .ip_buf_1_addr_o    (ip_buf_1_addr   )
    );

    //====================================
    //  externel data and param  buffer
    //==================================== 
    wire param_buf_en;
    assign param_buf_en = ddr3_rd_data_valid && ip_proc;
    ip_mem_interface
    #(
        .FW (FW ),
        .DW (DW ),
        .CDW(CDW),
        .WL (WL )
    )
    ip_mem_interface_U
    (
        .clk_i (clk_i ),
        .rstn_i(ui_rstn),
        //--param buf
        .param_buf_en_i  (param_buf_en            ),
        .wr_buf_sel_i    (wr_buf_sel              ),
        .param_buf_full_i(param_buf_full          ),
        .param_i         (ddr3_rd_data            ),
        .param_buf_busy_i(param_buf_busy          ),
        .param_buf_addr_i(ip_buf_addr             ),
        .wr_buf_done_o   (wr_buf_done             ),
        .ip_param_o      (ip_param                ),
        //--conv buf
        .conv_buf_ena_i  (prepare_data_valid_i    ),
        .conv_buf_wea_i  (prepare_data_valid_i    ),
        .conv_buf_addra_i(prepare_data_addr_i[9:0]),
        .conv_buf_dina_i (prepare_data_i          ),
        .conv_buf_enb_i  (conv_buf_en             ),
        .conv_buf_addrb_i(conv_buf_rd_addr        ),
        .conv_buf_doub_o (conv_buf_rd_data        ),
        //--ip buf0/1
        .ip_buf0_ena_i   (ip_buf_0_en             ),
        .ip_buf0_wea_i   (ip_buf_0_valid          ),
        .ip_buf0_addra_i (ip_buf_0_addr           ),
        .ip_buf0_dina_i  (ip_buf_0_wr_data        ),
        .ip_buf0_douta_o (ip_buf_0_rd_data        ),
        .ip_buf1_ena_i   (ast_ip_buf_1_en         ),
        .ip_buf1_wea_i   (ip_buf_1_valid          ),
        .ip_buf1_addra_i (ast_ip_buf_1_addr       ),
        .ip_buf1_dina_i  (ip_buf_1_wr_data        ),
        .ip_buf1_douta_o (ip_buf_1_rd_data        )
    );
endmodule
