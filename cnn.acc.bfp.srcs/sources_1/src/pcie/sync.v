//-----------------------------------------------------------------------------
// File       : sync.v
//
// Description: synchronize axi interface to dram
//
// Version    : 1.0
//-----------------------------------------------------------------------------

module sync(
  // clocks and resets
  input  wire          axi_clk,
  input  wire          ddr_clk,
  input  wire          axi_reset_n,
  input  wire          ddr_clk_sync_rst,
  // from ddr to axi
  input  wire          ddr2axi_write_end,
  input  wire [3:0]    ddr2axi_stage_flags,
  // from axi to ddr
  input  wire [3:0]    axi2ddr_stage_flags,
  input  wire [31:0]   axi2ddr_req_addr,
  input  wire          axi2ddr_rd_req,
  input  wire          axi2ddr_rd_end,
  input  wire          axi2ddr_wr_req,
  // axi
  output wire          axi_wr_end,
  output wire [3:0]    axi_rd_stage_flags,
  // ddr
  output wire [3:0]    ddr_wr_stage_flags,
  output wire [31:0]   ddr_req_addr,
  output wire          ddr_read_req,
  output wire          ddr_read_end,
  output wire          ddr_write_req
  );

  // from ddr to axi
  sync_ddr2axi_1bit sync_ddr2axi_idle(
      .rst((!axi_reset_n)),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .ddr_data(ddr2axi_write_end),
      .axi_data(axi_wr_end)
  );
  sync_ddr2axi_nbit#(.WIDTH(4)) sync_ddr2axi_full(
      .rst((!axi_reset_n)),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .ddr_data(ddr2axi_stage_flags),
      .axi_data(axi_rd_stage_flags)
  );
  // from axi to ddr
  sync_axi2ddr_nbit #( .WIDTH(4)) sync_axi2ddr_flags(
      .rst(ddr_clk_sync_rst),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .axi_data(axi2ddr_stage_flags),
      .ddr_data(ddr_wr_stage_flags)
  );
  sync_axi2ddr_nbit #( .WIDTH(32)) sync_axi2ddr_req_addr(
      .rst(ddr_clk_sync_rst),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .axi_data(axi2ddr_req_addr),
      .ddr_data(ddr_req_addr)
  );
  sync_axi2ddr_1bit sync_axi2ddr_rd_end(
      .rst(ddr_clk_sync_rst),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .axi_data(axi2ddr_rd_end),
      .ddr_data(ddr_read_end)
  );
  sync_axi2ddr_1bit sync_axi2ddr_rd_req(
      .rst(ddr_clk_sync_rst),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .axi_data(axi2ddr_rd_req),
      .ddr_data(ddr_read_req)
  );
  sync_axi2ddr_1bit sync_axi2ddr_wr_req(
      .rst(ddr_clk_sync_rst),
      .axi_clk(axi_clk),
      .ddr_clk(ddr_clk),
      .axi_data(axi2ddr_wr_req),
      .ddr_data(ddr_write_req)
  );
  /*
  // command generator
  wire [63:0]       ddr_data_to_bram;
  wire [63:0]       ddr_data_from_bram;
  wire              ddr_bram_wr_en;
  wire              ddr_bram_rd_en;
  wire [9:0]        ddr_addr_to_bram;
  ddr_cmd_gen ddr_cmd_iface(
      .ddr_addr                 (ddr_addr),
      .ddr_cmd                  (ddr_cmd),
      .ddr_en                   (ddr_en),
      .ddr_wdf_data             (ddr_wdf_data),
      .ddr_wdf_end              (ddr_wdf_end),
      .ddr_wdf_wren             (ddr_wdf_wren),
      .ddr_rd_data              (ddr_rd_data),
      .ddr_rd_data_end          (ddr_rd_data_end),
      .ddr_rd_data_valid        (ddr_rd_data_valid),
      .ddr_rdy                  (ddr_rdy),
      .ddr_wdf_rdy              (ddr_wdf_rdy),
      .ddr_clk                  (ddr_clk),
      .ddr_clk_sync_rst         (ddr_clk_sync_rst),
      .ddr_wdf_mask             (ddr_wdf_mask),
      .ddr_init_calib_complete  (ddr_init_calib_complete),
      // bram interface
      .ddr_data_from_bram       (ddr_data_from_bram),
      .ddr_data_to_bram         (ddr_data_to_bram),
      .ddr_addr_to_bram         (ddr_addr_to_bram),
      .ddr_bram_wr_en           (ddr_bram_wr_en),
      .ddr_bram_rd_en           (ddr_bram_rd_en),
      // adapter write
      .ddr_wr_end               (ddr2axi_write_end),
      .ddr_stage_flags_from     (ddr_stage_flags_from),
      // adapter read
      .ddr_req_rd               (axi2ddr_read_req), // request read from ddr
      .ddr_stage_flags_to       (ddr2axi_stage_flags_to),
      .ddr_rd_end               (axi2ddr_read_end),
      // rd base/end addresses
      .ddr_base_addr_gray       (ddr_base_addr_gray)
  );
  */

endmodule
