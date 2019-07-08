// ---------------------------------------------------
// File       : pcie_trans.v
// 
// Description: transfer data from PC to ddr
// 
// Version    : 1.0
// ---------------------------------------------------

module pcie_trans #( 
      parameter C_DATA_WIDTH       = 64,
      parameter C_M_AXI_DATA_WIDTH = C_DATA_WIDTH,
      parameter C_M_AXI_ID_WIDTH   = 4
    )(
      // System IO signals
      input  wire                               user_clk,
      input  wire                               user_resetn,
      // AXI Memory Mapped interface
      input  wire [C_M_AXI_ID_WIDTH-1:0]        s_axi_awid,
      input  wire [31:0]                        s_axi_awaddr,
      input  wire [7:0]                         s_axi_awlen,
      input  wire [2:0]                         s_axi_awsize,
      input  wire [1:0]                         s_axi_awburst,
      input  wire                               s_axi_awvalid,
      output wire                               s_axi_awready,
      input  wire [C_M_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
      input  wire [(C_M_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
      input  wire                               s_axi_wlast,
      input  wire                               s_axi_wvalid,
      output wire                               s_axi_wready,
      output wire [C_M_AXI_ID_WIDTH-1:0]        s_axi_bid,
      output wire [1:0]                         s_axi_bresp,
      output wire                               s_axi_bvalid,
      input  wire                               s_axi_bready,
      input  wire [C_M_AXI_ID_WIDTH-1:0]        s_axi_arid,
      input  wire [31:0]                        s_axi_araddr,
      input  wire [7:0]                         s_axi_arlen,
      input  wire [2:0]                         s_axi_arsize,
      input  wire [1:0]                         s_axi_arburst,
      input  wire                               s_axi_arvalid,
      output wire                               s_axi_arready,
      output wire [C_M_AXI_ID_WIDTH-1:0]        s_axi_rid,
      output wire [C_M_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
      output wire [1:0]                         s_axi_rresp,
      output wire                               s_axi_rlast,
      output wire                               s_axi_rvalid,
      input  wire                               s_axi_rready,
      // accelerator
      input  wire                               acc_cnn_idle,     // <-xxxxxxxxxxxxxxxx block data reading
      output wire                               acc_data_ready, // <-xxxxxxxxxxxxxxxx write on the last data, signal to start cnn operation
      // ddr MIG interface
      input  wire                               ddr_clk,
      input  wire                               ddr_clk_sync_rst,
      input  wire                               ddr_rdy,
      input  wire                               ddr_wdf_rdy,
      input  wire [511:0]                       ddr_rd_data,
      input  wire                               ddr_rd_data_end,
      input  wire                               ddr_rd_data_valid,
      output wire                               ddr_en,
      output wire [2:0]                         ddr_cmd,
      output wire [29:0]                        ddr_addr,
      output wire [511:0]                       ddr_wdf_data,
      output wire                               ddr_wdf_end,
      output wire                               ddr_wdf_wren,
      output wire [63:0]                        ddr_wdf_mask,
      input  wire                               ddr_init_calib_complete
    );

  // bram
  wire [63:0]           ddr_data_from_bram;
  wire [63:0]           ddr_data_to_bram;
  wire                  ddr_bram_wr_en;
  wire                  ddr_bram_rd_en;
  wire [9:0]            ddr_bram_addr;

  // synchronizer
  wire                  ddr2axi_write_end;
  wire [3:0]            ddr2axi_stage_flags;
  wire [3:0]            axi2ddr_stage_flags;
  wire [31:0]           axi2ddr_req_addr;
  wire                  axi2ddr_rd_req;
  wire                  axi2ddr_rd_end;
  wire                  axi2ddr_wr_req;
  wire                  axi_wr_end;
  wire [3:0]            axi_rd_stage_flags;
  wire [3:0]            ddr_wr_stage_flags;
  wire [31:0]           ddr_req_addr;
  wire                  ddr_read_req;
  wire                  ddr_read_end;
  wire                  ddr_write_req;

  // Block ram for the AXI interface
  ifaceAdapter blk_mem(
    .axi_clk       (user_clk),
    .axi_reset_n   (user_resetn),
    // write address port
    .axi_awid      (s_axi_awid),
    .axi_awaddr    (s_axi_awaddr),
    .axi_awlen     (s_axi_awlen),
    .axi_awsize    (s_axi_awsize),
    .axi_awburst   (s_axi_awburst),
    .axi_awvalid   (s_axi_awvalid),
    .axi_awready   (s_axi_awready),
    // write data port
    .axi_wdata     (s_axi_wdata),
    .axi_wstrb     (s_axi_wstrb),
    .axi_wlast     (s_axi_wlast),
    .axi_wvalid    (s_axi_wvalid),
    .axi_wready    (s_axi_wready),
    // write response port
    .axi_bid       (s_axi_bid),
    .axi_bresp     (s_axi_bresp),
    .axi_bvalid    (s_axi_bvalid),
    .axi_bready    (s_axi_bready),
    // read address port
    .axi_arid      (s_axi_arid),
    .axi_araddr    (s_axi_araddr),
    .axi_arlen     (s_axi_arlen),
    .axi_arsize    (s_axi_arsize),
    .axi_arburst   (s_axi_arburst),
    .axi_arvalid   (s_axi_arvalid),
    .axi_arready   (s_axi_arready),
    // read data port
    .axi_rid       (s_axi_rid),
    .axi_rdata     (s_axi_rdata),
    .axi_rresp     (s_axi_rresp),
    .axi_rlast     (s_axi_rlast),
    .axi_rvalid    (s_axi_rvalid),
    .axi_rready    (s_axi_rready),

    // sync
    .axi2ddr_stage_flags (axi2ddr_stage_flags),
    .axi2ddr_req_addr    (axi2ddr_req_addr),
    .axi2ddr_rd_req      (axi2ddr_rd_req),
    .axi2ddr_rd_end      (axi2ddr_rd_end), // axi idle
    .axi2ddr_wr_req      (axi2ddr_wr_req),
    .axi_wr_end          (axi_wr_end),     // ddr idle
    .axi_rd_stage_flags  (axi_rd_stage_flags),
    // app
    .axi_acc_cnn_idle    (acc_cnn_idle),
    // bram
    .ddr_clk             (ddr_clk),
    .bram_wr_en          (ddr_bram_wr_en),
    .bram_rd_en          (ddr_bram_rd_en),
    .bram_addr           (ddr_bram_addr),
    .bram_din            (ddr_data_to_bram),
    .bram_dout           (ddr_data_from_bram)
  );

  // synchronizer
  sync  axi_ddr_sync(
    .axi_clk             (user_clk),
    .ddr_clk             (ddr_clk),
    .axi_reset_n         (user_resetn),
    .ddr_clk_sync_rst    (ddr_clk_sync_rst),
 
    .ddr2axi_write_end   (ddr2axi_write_end),
    .ddr2axi_stage_flags (ddr2axi_stage_flags),
 
    .axi2ddr_stage_flags (axi2ddr_stage_flags),
    .axi2ddr_req_addr    (axi2ddr_req_addr),
    .axi2ddr_rd_req      (axi2ddr_rd_req),
    .axi2ddr_rd_end      (axi2ddr_rd_end),
    .axi2ddr_wr_req      (axi2ddr_wr_req),
 
    .axi_wr_end          (axi_wr_end),
    .axi_rd_stage_flags  (axi_rd_stage_flags),
 
    .ddr_wr_stage_flags  (ddr_wr_stage_flags),
    .ddr_req_addr        (ddr_req_addr),
    .ddr_read_req        (ddr_read_req),
    .ddr_read_end        (ddr_read_end),
    .ddr_write_req       (ddr_write_req)
  );

  // ddr cmd generator
  ddr_cmd_gen ddr_iface(
    // arb_pcie
    .ddr_addr                (ddr_addr),
    .ddr_cmd                 (ddr_cmd),
    .ddr_en                  (ddr_en),
    .ddr_wdf_data            (ddr_wdf_data),
    .ddr_wdf_end             (ddr_wdf_end),
    .ddr_wdf_wren            (ddr_wdf_wren),
    .ddr_wdf_mask            (ddr_wdf_mask),
    .ddr_rd_data             (ddr_rd_data),
    .ddr_rd_data_end         (ddr_rd_data_end),
    .ddr_rd_data_valid       (ddr_rd_data_valid),
    .ddr_rdy                 (ddr_rdy),
    .ddr_wdf_rdy             (ddr_wdf_rdy),
    .ddr_clk                 (ddr_clk),
    .ddr_clk_sync_rst        (ddr_clk_sync_rst),
    // arb_pcie
    .ddr_init_calib_complete (ddr_init_calib_complete),
 
    .ddr_data_from_bram      (ddr_data_from_bram),
    .ddr_data_to_bram        (ddr_data_to_bram),
    .ddr_addr_to_bram        (ddr_bram_addr),
    .ddr_bram_wr_en          (ddr_bram_wr_en),
    .ddr_bram_rd_en          (ddr_bram_rd_en),

    // app
    .ddr_vgg_idle            (acc_cnn_idle),
    .ddr_vgg_data_ready      (acc_data_ready),
    .ddr_wr_req              (ddr_write_req),
    .ddr_wr_end              (ddr2axi_write_end),
    .ddr_stage_flags_from    (ddr_wr_stage_flags),
    .ddr_rd_req              (ddr_read_req),
    .ddr_stage_flags_to      (ddr2axi_stage_flags),
    .ddr_rd_end              (ddr_read_end),
    .ddr_req_addr            (ddr_req_addr)
  );

endmodule
