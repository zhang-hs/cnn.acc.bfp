/*
--fast ddr model
*/

    localparam ADDR_WIDTH    = 30;
    localparam DATA_WIDTH    = 512;
    localparam DATA_NUM_BITS = 20;
    localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

    wire clk;
    wire rst;
    //--ddr write
    wire ddr3_wr_en;
    wire fetch_data_en;
    wire wr_addr_inc;
    wire wr_ddr_done;
    wire [DATA_NUM_BITS-1:0] wr_burst_num;
    wire [ADDR_WIDTH-1:0] wr_start_addr;
    wire [DATA_WIDTH-1:0] ddr3_wr_data;
    //--ddr read
    wire rd_addr_inc;
    wire rd_ddr_done;
    //--interface with mig
    wire app_en;
    wire app_rdy;
    wire app_wdf_rdy;
    wire app_wdf_end;
    wire app_rd_data_end;
    wire app_rd_data_valid;
    wire init_calib_complete;
    wire [2:0] app_cmd;
    wire [ADDR_WIDTH-1:0] app_addr;
    wire [APP_DATA_WIDTH-1:0] app_rd_data;
    wire [APP_DATA_WIDTH-1:0] app_wdf_data;
    wire [APP_MASK_WIDTH-1:0] app_wdf_mask;
    wire arb_app_en;
    wire arb_app_rdy;
    wire arb_app_wdf_rdy;
    wire arb_app_wdf_end;
    wire arb_app_rd_data_end;
    wire arb_app_rd_data_valid;
    wire arb_init_calib_complete;
    wire [2:0] arb_app_cmd;
    wire [ADDR_WIDTH-1:0] arb_app_addr;
    wire [APP_DATA_WIDTH-1:0] arb_app_rd_data;
    wire [APP_DATA_WIDTH-1:0] arb_app_wdf_data;
    wire [APP_MASK_WIDTH-1:0] arb_app_wdf_mask;

    //====================================
    //  fast ddr model
    //==================================== 
    /*
    ddr_model
    #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )
    ddr_model_U
    (
        //--app general signal
        .app_en_i  (app_en  ),
        .app_rdy_o (app_rdy ),
        .app_cmd_i (app_cmd ),
        .app_addr_i(app_addr),
        //--write ddr
        .app_wdf_wren_i(app_wdf_wren),
        .app_wdf_end_i (app_wdf_end ),
        .app_wdf_rdy_o (app_wdf_rdy ),
        .app_wdf_data_i(app_wdf_data),
        //--read ddr
        .app_rd_data_valid_o(app_rd_data_valid),
        .app_rd_data_end_o  (app_rd_data_end  ),
        .app_rd_data_o      (app_rd_data      ),
        //--output clock
        .ui_clk(clk),
        .ui_rst(rst),
        .init_calib_complete_o(init_calib_complete)
    );
    */
    ddr_model
    ddr_model_U
    (
        //--app general signal
        .ddr_en      (app_en  ),
        .ddr_rdy     (app_rdy ),
        .ddr_cmd     (app_cmd ),
        .ddr_addr    (app_addr),
        .ddr_wdf_mask(app_wdf_mask),
        //--write ddr
        .ddr_wdf_wren(app_wdf_wren),
        .ddr_wdf_end (app_wdf_end ),
        .ddr_wdf_rdy (app_wdf_rdy ),
        .ddr_wdf_data(app_wdf_data),
        //--read ddr
        .ddr_rd_data_valid(app_rd_data_valid),
        .ddr_rd_data_end  (app_rd_data_end  ),
        .ddr_rd_data      (app_rd_data      ),
        //--output clock
        .ui_clk(clk),
        .ui_rst(rst),
        .init_calib_complete(init_calib_complete)
    );
