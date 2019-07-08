//----------------------------------------------------
// File       : vgg_acc.v
//
// Description: top module of vgg16
//
// Version    : 1.0
//----------------------------------------------------

`timescale 1ps / 1ps
//`define ddr_sim // should be removed, on Aug.14

module vgg_acc #(
  parameter TCQ = 1,
  parameter C_M_AXI_ID_WIDTH = 4,
  parameter C_DATA_WIDTH = 64,
  parameter C_M_AXI_DATA_WIDTH = C_DATA_WIDTH
)
(
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

  // System IO signals
  input  wire           user_clk, // xdma axi clk, 125 MHz
  input  wire           user_resetn,
  input  wire           user_lnk_up,
  input  wire           sys_rst_n,
  output wire [3:0]     leds,

  // ddr interface
  input  wire           ddr_sys_rst,
  input  wire           ddr_sys_clk_n,
  input  wire           ddr_sys_clk_p,
  output [15:0]         ddr3_addr,
  output [2:0]          ddr3_ba,
  output                ddr3_cas_n,
  output [0:0]          ddr3_ck_n,
  output [0:0]          ddr3_ck_p,
  output [0:0]          ddr3_cke,
  output                ddr3_ras_n,
  output                ddr3_reset_n,
  output                ddr3_we_n,
  inout  [63:0]         ddr3_dq,
  inout  [7:0]          ddr3_dqs_n,
  inout  [7:0]          ddr3_dqs_p,
  output [0:0]          ddr3_cs_n,
  output [7:0]          ddr3_dm,
  output [0:0]          ddr3_odt

);

  // ddr interface
  wire [29:0]           ddr_addr;
  wire [2:0]            ddr_cmd;
  wire                  ddr_en;
  wire [511:0]          ddr_wdf_data;
  wire                  ddr_wdf_end;
  wire                  ddr_wdf_wren;
  wire [511:0]          ddr_rd_data;
  wire                  ddr_rd_data_end;
  wire                  ddr_rd_data_valid;
  wire                  ddr_rdy;
  wire                  ddr_wdf_rdy;
  wire                  ddr_sr_active;
  wire                  ddr_ref_ack;
  wire                  ddr_zq_ack;
  wire                  ddr_clk;
  wire                  ddr_clk_sync_rst;
  wire [63:0]           ddr_wdf_mask;

  wire                  ddr_init_calib_complete;

  wire                  sys_reset, sys_resetn;
  reg  [25:0]           user_clk_heartbeat;

  // pcie
  wire [511:0]  pcie_rd_data;
  wire          pcie_rd_data_end;
  wire          pcie_rd_data_valid;
  wire          pcie_rdy;
  wire          pcie_wdf_rdy;

  wire [29:0]   pcie_addr;
  wire [2:0]    pcie_cmd;
  wire          pcie_en;
  wire [511:0]  pcie_wdf_data;
  wire [63:0]   pcie_wdf_mask;
  wire          pcie_wdf_end;
  wire          pcie_wdf_wren;
  wire          acc_data_ready;
  // conv
  wire          conv_ddr_req;
  wire          conv_ddr_grant;

  wire [29:0]   conv_addr;
  wire [2:0]    conv_cmd;
  wire          conv_en;
  wire [511:0]  conv_wdf_data;
  wire [63:0]   conv_wdf_mask;
  wire          conv_wdf_end;
  wire          conv_wdf_wren;
  // fc
  wire          fc_ddr_req;
  wire          fc_ddr_grant;

  wire [29:0]   fc_addr;
  wire [2:0]    fc_cmd;
  wire          fc_en;
  wire [511:0]  fc_wdf_data;
  wire [63:0]   fc_wdf_mask;
  wire          fc_wdf_end;
  wire          fc_wdf_wren;
  wire          acc_idle;


  // The sys_rst_n input is active low based on the core configuration
  assign sys_resetn = sys_rst_n;
  assign sys_reset  = ~sys_rst_n;

  // Create a Clock Heartbeat
  always @(posedge user_clk) begin
    if(!sys_resetn) begin
      user_clk_heartbeat <= #TCQ 26'd0;
    end else begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
    end
  end

  // LEDs for observation
  assign leds[0] = sys_resetn;
  assign leds[1] = user_resetn;
  assign leds[2] = user_lnk_up;
  assign leds[3] = user_clk_heartbeat[25];

  // MIG DDR3 interface
  mig7series u_mig7series (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [15:0]                ddr3_addr
    .ddr3_ba                        (ddr3_ba),  // output [2:0]                ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),  // output                        ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]                ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]                ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),  // output [0:0]                ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),  // output                        ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output                        ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),  // output                        ddr3_we_n
    .ddr3_dq                        (ddr3_dq),  // inout [63:0]                ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [7:0]                ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [7:0]                ddr3_dqs_p
    .ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]                ddr3_cs_n
    .ddr3_dm                        (ddr3_dm),  // output [7:0]                ddr3_dm
    .ddr3_odt                       (ddr3_odt),  // output [0:0]                ddr3_odt
    // System Clock Ports
    .sys_clk_p                      (ddr_sys_clk_p),  // input                                sys_clk_p
    .sys_clk_n                      (ddr_sys_clk_n),  // input                                sys_clk_n
    .sys_rst                        (ddr_sys_rst), // input sys_rst

    // Application interface ports
    .app_addr                       (ddr_addr),  // input [29:0]                app_addr
    .app_cmd                        (ddr_cmd),  // input [2:0]                app_cmd
    .app_en                         (ddr_en),  // input                                app_en
    .app_wdf_data                   (ddr_wdf_data),  // input [511:0]                app_wdf_data
    .app_wdf_end                    (ddr_wdf_end),  // input                                app_wdf_end
    .app_wdf_wren                   (ddr_wdf_wren),  // input                                app_wdf_wren
    .app_rd_data                    (ddr_rd_data),  // output [511:0]                app_rd_data
    .app_rd_data_end                (ddr_rd_data_end),  // output                        app_rd_data_end
    .app_rd_data_valid              (ddr_rd_data_valid),  // output                        app_rd_data_valid
    .app_rdy                        (ddr_rdy),  // output                        app_rdy
    .app_wdf_rdy                    (ddr_wdf_rdy),  // output                        app_wdf_rdy
    .ui_clk                         (ddr_clk),  // output                        ui_clk
    .ui_clk_sync_rst                (ddr_clk_sync_rst),  // output                        ui_clk_sync_rst
    .app_wdf_mask                   (ddr_wdf_mask),  // input [63:0]                app_wdf_mask
    .app_sr_req                     (1'b0),  // input                        app_sr_req
    .app_ref_req                    (1'b0),  // input                        app_ref_req
    .app_zq_req                     (1'b0),  // input                        app_zq_req
    .app_sr_active                  (),  // output                        app_sr_active
    .app_ref_ack                    (),  // output                        app_ref_ack
    .app_zq_ack                     (),  // output                        app_zq_ack
    .init_calib_complete            (ddr_init_calib_complete)  // output                        init_calib_complete
  );

  // pcie data transfer
  pcie_trans data_trans(
    .user_clk(user_clk),
    .user_resetn(user_resetn),
    // axi
    .s_axi_awid(s_axi_awid),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bid(s_axi_bid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_arid(s_axi_arid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .acc_cnn_idle(acc_idle),
    .acc_data_ready(acc_data_ready),
    //ddr
    .ddr_clk(ddr_clk),
    .ddr_clk_sync_rst(ddr_clk_sync_rst),
    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),
    .ddr_rd_data(ddr_rd_data),
    .ddr_rd_data_end(ddr_rd_data_end),
    .ddr_rd_data_valid(ddr_rd_data_valid),
    // pcie data transfer
    .ddr_en(pcie_en),
    .ddr_cmd(pcie_cmd),
    .ddr_addr(pcie_addr),
    .ddr_wdf_data(pcie_wdf_data),
    .ddr_wdf_end(pcie_wdf_end),
    .ddr_wdf_wren(pcie_wdf_wren),
    .ddr_wdf_mask(pcie_wdf_mask),
    .ddr_init_calib_complete(ddr_init_calib_complete)
  );

  // arbiter
  ddr_iface_arbiter arbiter(
    .clk(ddr_clk),
    .rst_n(sys_rst_n), // <-xxxxxxxxx ddr clk synchronous reset

    .ddr_addr(ddr_addr),
    .ddr_cmd(ddr_cmd),
    .ddr_en(ddr_en),
    .ddr_wdf_data(ddr_wdf_data),
    .ddr_wdf_mask(ddr_wdf_mask), // stuck at 64'b1
    .ddr_wdf_end(ddr_wdf_end),  // stuck at 1'b1
    .ddr_wdf_wren(ddr_wdf_wren),

    .arb_data_ready(acc_data_ready), // deasserted -- PCIe, asserted -- vgg module, transinet signal, arbiter enable
    .arb_cnn_finish(acc_idle), // asserted -- PCIe, deasserted -- vgg module, transinet signal, arbiter disable

    // pcie
    .arb_pcie_addr(pcie_addr),
    .arb_pcie_cmd(pcie_cmd),
    .arb_pcie_en(pcie_en),
    .arb_pcie_wdf_data(pcie_wdf_data),
    .arb_pcie_wdf_mask(pcie_wdf_mask), // stuck at 64'b1
    .arb_pcie_wdf_end(pcie_wdf_end),  // stuck at 1'b1
    .arb_pcie_wdf_wren(pcie_wdf_wren),
    // conv_layer
    .arb_conv_req(conv_ddr_req), // convolution request <-xxxxxxxxxxxxxxx
    .arb_conv_grant(conv_ddr_grant),

    .arb_conv_addr(conv_addr),
    .arb_conv_cmd(conv_cmd),
    .arb_conv_en(conv_en),
    .arb_conv_wdf_data(conv_wdf_data),
    .arb_conv_wdf_mask(conv_wdf_mask), // stuck at 64'b1
    .arb_conv_wdf_end(conv_wdf_end),  // stuck at 1'b1
    .arb_conv_wdf_wren(conv_wdf_wren),
    // fc_layer
    .arb_fc_req(fc_ddr_req),
    .arb_fc_grant(fc_ddr_grant),

    .arb_fc_addr(fc_addr),
    .arb_fc_cmd(fc_cmd),
    .arb_fc_en(fc_en),
    .arb_fc_wdf_data(fc_wdf_data),
    .arb_fc_wdf_mask(fc_wdf_mask), // stuck at 64'b1
    .arb_fc_wdf_end(fc_wdf_end),  // stuck at 1'b1
    .arb_fc_wdf_wren(fc_wdf_wren)
  );

  // vgg
  vgg vgg_net(
    .clk(ddr_clk),
    .rst_n(sys_rst_n),
    .vgg_conv_req(conv_ddr_req),
    .vgg_conv_grant(conv_ddr_grant),
    .vgg_fc_req(fc_ddr_req),
    .vgg_fc_grant(fc_ddr_grant),

    .ddr_rd_data_valid(ddr_rd_data_valid),
    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),
    .ddr_rd_data(ddr_rd_data),
    .ddr_rd_data_end(ddr_rd_data_end),
    // conv
    .vgg_conv_addr(conv_addr),
    .vgg_conv_cmd(conv_cmd),
    .vgg_conv_en(conv_en),
    .vgg_conv_wdf_wren(conv_wdf_wren),
    .vgg_conv_wdf_data(conv_wdf_data),
    .vgg_conv_wdf_mask(conv_wdf_mask),
    .vgg_conv_wdf_end(conv_wdf_end),
    // fc
    .vgg_fc_addr(fc_addr),
    .vgg_fc_cmd(fc_cmd),
    .vgg_fc_en(fc_en),
    .vgg_fc_wdf_data(fc_wdf_data),
    .vgg_fc_wdf_mask(fc_wdf_mask), // stuck at 64'b1
    .vgg_fc_wdf_end(fc_wdf_end),  // stuck at 1'b1
    .vgg_fc_wdf_wren(fc_wdf_wren),
    //
    .vgg_data_ready(acc_data_ready), // bottom data and kernel data is ready on ddr -> convolution start
    .vgg_end(acc_idle) // current layer convolution done
  );

endmodule
