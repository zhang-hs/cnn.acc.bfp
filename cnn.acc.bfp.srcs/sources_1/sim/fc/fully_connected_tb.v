/*
  --test for fully_connected_op.v
*/
`timescale 1ns/1ps
`define FP16
//--DiretC API

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
  localparam ADDR_WIDTH    = 30;
  localparam DATA_WIDTH    = 512;  
  localparam DATA_NUM_BITS = 20;  
  localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

  // clocks
  reg  sys_clk;
  reg  sys_rst_n;
  reg  init_calib_complete;
  initial begin
    sys_rst_n           = 1'b0;
    init_calib_complete = 1'b0;
    #50  sys_rst_n            = 1'b1;
    #100 init_calib_complete  = 1'b1;
  end
  initial sys_clk = 1'b0;
  always #10 sys_clk = ~sys_clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef VCS //Synopsys VPD dump
        $vcdplusfile("top.vpd");
        $vcdpluson;
//        $vcdplusmemon;
        $vcdplusglitchon;
      `endif
    end
  end
//  //====================================
//  //  record simulation data
//  //==================================== 
//  initial begin
//      $vcdplusfile( "sim_result.vpd" );
//      $vcdpluson( 0, fully_connected_tb);
//      $vcdplusmemon();
//      $vcdplusglitchon;
//      $vcdplusflush;

//      //$dumpfile("top.vcd");
//      //$dumpvars(0, fully_connected_tb);
//  end

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
  
  //data_pcie, --prepare ip data to bram
  reg           prepare_en;
  wire          prepare_done;
  wire [CDW-1:0]prepare_data;
  wire          prepare_data_valid;
  wire [12-1:0] prepare_data_addr;
  //--ddr arbitor
  wire          arbitor_req;
  wire          arbitor_ack;
  //--ip status
  wire          conv_buf_free;
  wire          ip_done;
  wire          batch_done;
  //--export data
  wire          exp_done;
  
  //arb app
  wire                      arb_app_en;
  wire                      arb_app_rdy;
  wire                      arb_app_wdf_rdy;
  wire                      arb_app_wdf_wren;
  wire                      arb_app_wdf_end;
  wire                      arb_app_rd_data_end;
  wire                      arb_app_rd_data_valid;
  wire [2:0]                arb_app_cmd;
  wire [ADDR_WIDTH-1:0]     arb_app_addr;
  wire [APP_DATA_WIDTH-1:0] arb_app_rd_data;
  wire [APP_DATA_WIDTH-1:0] arb_app_wdf_data;
  wire [APP_MASK_WIDTH-1:0] arb_app_wdf_mask;
  
  initial begin
      #0  prepare_en = 1'b0;
      #10 prepare_en = 1'b1;
  end
  //ddr wr
  wire                        wr_ddr_done; 
  wire                        ddr3_wr_en;
  wire                        fetch_data_en;    
  wire [DATA_NUM_BITS-1:0]    wr_burst_num;  
  wire [ADDR_WIDTH-1:0]       wr_start_addr; 
  wire [DATA_WIDTH-1:0]       ddr3_wr_data;
 
  //====================================
  //  ddr model and rd_wr_interface
  //====================================
  ddr_mem data_mem(
    .clk(sys_clk),
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

  //====================================
  //  prepare input data for ip
  //====================================    
  prepare_ip_data_sim
  #(
      .FW(FW),
      .CDW(CDW),
      .iNN(iNN)
  )
  wr_prepare_data
  (
      .tb_clk_i        (sys_clk ),
      .tb_rstn_i       (sys_rst_n),
      .tb_en_i         (prepare_en        ),
      .tb_done_o       (prepare_done      ),
      .tb_data_o       (prepare_data      ), 
      .tb_addr_o       (prepare_data_addr ),
      .tb_data_valid_o (prepare_data_valid)
  );
  //write to ddr
  wr_ddr_op
  #(
      .ADDR_WIDTH   (ADDR_WIDTH   ),
      .DATA_WIDTH   (DATA_WIDTH   ),
      .DATA_NUM_BITS(DATA_NUM_BITS)
   )
  wr_ddr_param
  (
      .clk_i(sys_clk),
      .rst_n(sys_rst_n),
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
  always @(negedge sys_rst_n or posedge sys_clk) begin
      if(!sys_rst_n) begin
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
      .clk(sys_clk),
      .rst_n(sys_rst_n),
      //--ddr
//      .ddr_rd_data_valid(app_rd_data_valid), //unvalid input
//      .ddr_rdy          (app_rdy),
//      .ddr_wdf_rdy      (app_wdf_rdy),
//      .ddr_rd_data      (app_rd_data),
//      .ddr_rd_data_end  (app_rd_data_end),
      .ddr_addr         (ddr_addr),
      .ddr_cmd          (ddr_cmd),
      .ddr_en           (ddr_en),
      .ddr_wdf_data     (ddr_wdf_data),
      .ddr_wdf_mask     (ddr_wdf_mask),
      .ddr_wdf_end      (ddr_wdf_end),
      .ddr_wdf_wren     (ddr_wdf_wren),
      
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
      .clk_i (sys_clk),
      .rst_i (!sys_rst_n),
      .init_calib_complete_i(init_calib_complete),
      //--ddr rd/wr interface
      .app_rdy_i            (ddr_rdy            ),
      .app_en_o             (arb_app_en         ),
      .app_cmd_o            (arb_app_cmd        ),
      .app_addr_o           (arb_app_addr       ),
      .ddr3_wr_en_i         (ddr3_wr_en         ),
      .wr_burst_num_i       (wr_burst_num       ),
      .wr_start_addr_i      (wr_start_addr      ),
      .wr_data_i            (ddr3_wr_data       ),
      .app_wdf_rdy_i        (ddr_wdf_rdy        ),
      .app_wdf_wren_o       (arb_app_wdf_wren   ),
      .app_wdf_data_o       (arb_app_wdf_data   ),
      .app_wdf_mask_o       (arb_app_wdf_mask   ),
      .app_wdf_end_o        (arb_app_wdf_end    ),
      .fetch_data_en_o      (fetch_data_en      ),
      .wr_ddr_done_o        (wr_ddr_done        ),
      .arbitor_req_o        (arbitor_req        ),
      .arbitor_ack_i        (arbitor_ack        ),
      .app_rd_data_valid_i  (ddr_rd_data_valid  ),
      .app_rd_data_i        (ddr_rd_data        ),
      .app_rd_data_end_i    (ddr_rd_data_end    ),
      //--conv buf data write
      .prepare_data_addr_i  (prepare_data_addr[9:0]  ),
      .prepare_data_valid_i (prepare_data_valid ),
      .prepare_data_i       (prepare_data       ),
      .prepare_done_i       (prepare_done       ),
      //--ip status
      .conv_buf_free_o      (conv_buf_free      ),
      .ip_done_o            (ip_done            ),
//      .batch_done_o         (batch_done         ),
      //--export data
      .exp_done_o           (exp_done           )
  );


endmodule
