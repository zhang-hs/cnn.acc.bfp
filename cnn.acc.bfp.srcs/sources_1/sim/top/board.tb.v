// ---------------------------------------------------
// File       : board.tb.v
//
// Description: board test bench
//
// Version    : 1.0
// ---------------------------------------------------

`timescale 1ns/100fs
`define NULL 0
//`define sim_ // simulation using directC

module top;

  // clocks
  reg  ddr_clk;
  reg  sys_rst_n;
  reg  init_calib_complete;
  initial begin
    sys_rst_n           = 1'b0;
    init_calib_complete = 1'b0;
    #50  sys_rst_n            = 1'b1;
    #100 init_calib_complete  = 1'b1;
  end
  initial ddr_clk = 1'b0;
  always #10 ddr_clk = ~ddr_clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef VCS //Synopsys VPD dump
        $vcdplusfile("top.vpd");
        $vcdpluson;
      //$vcdplusmemon;
        $vcdplusglitchon;
      `endif
    end
  end

  // ddr
  wire [511:0]  ddr_rd_data;
  wire          ddr_rd_data_end;
  wire          ddr_rd_data_valid;
  wire          ddr_rdy;
  wire          ddr_wdf_rdy;

  wire [29:0]   ddr_addr;
  wire [2:0]    ddr_cmd;
  wire          ddr_en;
  wire [511:0]  ddr_wdf_data;
  wire [63:0]   ddr_wdf_mask;
  wire          ddr_wdf_end;
  wire          ddr_wdf_wren;
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
  wire          tb_load_done;
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


  ddr_mem data_mem(
    .clk(ddr_clk),
    .ddr_rd_data_valid(ddr_rd_data_valid),
    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),
    .ddr_rd_data(ddr_rd_data),
    .ddr_rd_data_end(ddr_rd_data_end),

    .ddr_addr(ddr_addr),
    .ddr_cmd(ddr_cmd),
    .ddr_en(ddr_en),
    .ddr_wdf_data(ddr_wdf_data),
    .ddr_wdf_mask(ddr_wdf_mask),
    .ddr_wdf_end(ddr_wdf_end),
    .ddr_wdf_wren(ddr_wdf_wren)
  );

  data_pcie data_reading(
    .clk(ddr_clk),
    .rst_n(sys_rst_n),
    // MIG
    .init_calib_complete(init_calib_complete),
    // ddr
    .ddr_rd_data(ddr_rd_data),
    .ddr_rd_data_end(ddr_rd_data_end),
    .ddr_rd_data_valid(ddr_rd_data_valid),
    .ddr_rdy(ddr_rdy),
    .ddr_wdf_rdy(ddr_wdf_rdy),

    .app_addr(pcie_addr),
    .app_cmd(pcie_cmd),
    .app_en(pcie_en),
    .app_wdf_data(pcie_wdf_data),
    .app_wdf_mask(pcie_wdf_mask),
    .app_wdf_end(pcie_wdf_end),
    .app_wdf_wren(pcie_wdf_wren),
    .tb_load_done(tb_load_done)
  );

//reg         fc_ddr_req;
//reg [7:0]   fc_req_count;
//always@(posedge ddr_clk or negedge sys_rst_n) begin
//  if(!sys_rst_n) begin
//    fc_ddr_req  <= 1'b0;
//    fc_req_count<= 8'd0;
//  end else begin 
//    if(fc_req_count==8'd205) begin
//      fc_req_count <= 8'd0;
//    end else begin
//      fc_req_count <= fc_req_count + 8'd1;
//    end
//    if(fc_req_count<8'd170 && fc_req_count>8'd80) begin
//      fc_ddr_req <= 1'd1;
//    end else begin
//      fc_ddr_req <= 1'd0;
//    end
//  end
//end

  ddr_iface_arbiter arbiter(
      .clk(ddr_clk),
      .rst_n(sys_rst_n),

      .ddr_addr(ddr_addr),
      .ddr_cmd(ddr_cmd),
      .ddr_en(ddr_en),
      .ddr_wdf_data(ddr_wdf_data),
      .ddr_wdf_mask(ddr_wdf_mask), // stuck at 64'b1
      .ddr_wdf_end(ddr_wdf_end),  // stuck at 1'b1
      .ddr_wdf_wren(ddr_wdf_wren),

      .arb_data_ready(tb_load_done), // deasserted -- PCIe, asserted -- vgg module, transinet signal, arbiter enable
      .arb_cnn_finish(1'b0), // asserted -- PCIe, deasserted -- vgg module, transinet signal, arbiter disable

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
      .vgg_data_ready(tb_load_done), // bottom data and kernel data is ready on ddr -> convolution start
    //.vgg_start(_fm_start), // conv layer operation start signal
      .vgg_end() // current layer convolution done
    );

//always@(posedge ddr_clk) begin
//  if(tb_load_done) begin
//    #100 $finish;
//  end
//end

endmodule
