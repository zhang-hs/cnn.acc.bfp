//----------------------------------------------------
// Project    : The Xilinx PCI Express DMA 
//
// File       : xilinx_dma_pcie_ep.sv
//
// Version    : 1.0
//----------------------------------------------------
`timescale 1ps / 1ps
//`define ddr_sim // should be removed, on Aug.14

module xilinx_dma_pcie_ep #
  (
   parameter PL_LINK_CAP_MAX_LINK_WIDTH          = 1,            // 1- X1; 2 - X2; 4 - X4; 8 - X8
   parameter PL_SIM_FAST_LINK_TRAINING           = "FALSE",      // Simulation Speedup
   parameter PL_LINK_CAP_MAX_LINK_SPEED          = 1,             // 1- GEN1; 2 - GEN2; 4 - GEN3
   parameter C_DATA_WIDTH                        = 64 ,
   parameter EXT_PIPE_SIM                        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
   parameter C_ROOT_PORT                         = "FALSE",      // PCIe block is in root port mode
   parameter C_DEVICE_NUMBER                     = 0             // Device number for Root Port configurations only
   )
   (
       // PCIe DMA subsystem
       output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,
       output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
       input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
       input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
   
   
       output                                        led_0,
       output                                        led_1,
       output                                        led_2,
       output                                        led_3,
       input                                         sys_clk_p,
       input                                         sys_clk_n,
       input                                         sys_rst_n,
       
       // MIG DDR3 SDRAM
       // Inouts
       inout [63:0]                                  ddr3_dq,
       inout [7:0]                                   ddr3_dqs_n,
       inout [7:0]                                   ddr3_dqs_p,
       // Inputs
       input                                         ddr_sys_clk_p,
       input                                         ddr_sys_clk_n,
       input                                         ddr_sys_rst,
       // Outputs
    //`ifdef ddr_sim
    //output                                        ddr_init_calib_complete,
    //`endif
       output [15:0]                                 ddr3_addr,
       output [2:0]                                  ddr3_ba,
       output                                        ddr3_ras_n,
       output                                        ddr3_cas_n,
       output                                        ddr3_we_n,
       output                                        ddr3_reset_n,
       output [0:0]                                  ddr3_ck_p,
       output [0:0]                                  ddr3_ck_n,
       output [0:0]                                  ddr3_cke,
       output [0:0]                                  ddr3_cs_n,
       output [7:0]                                  ddr3_dm,
       output [0:0]                                  ddr3_odt
   
       );
   
       //-----------------------------------------------------------------------------------------------------------------------
       
       // Local Parameters derived from user selection
       localparam integer USER_CLK_FREQ = ((PL_LINK_CAP_MAX_LINK_SPEED == 3'h4) ? 5 : 4);
       localparam TCQ = 1;
       localparam C_M_AXI_ID_WIDTH   = 4;
       localparam C_S_AXI_DATA_WIDTH = C_DATA_WIDTH;
       localparam C_M_AXI_DATA_WIDTH = C_DATA_WIDTH;
       localparam C_S_AXI_ADDR_WIDTH = 64;
       localparam C_M_AXI_ADDR_WIDTH = 64;
       localparam C_NUM_USR_IRQ      = 1;
       
       wire                                          user_lnk_up;
       
       //----------------------------------------------------------------------------------------------------------------//
       //  Connectivity for external clocking                                                                            //
       //----------------------------------------------------------------------------------------------------------------//
       wire                                          PIPE_PCLK_IN;
       wire                                          PIPE_RXUSRCLK_IN;
       wire [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]       PIPE_RXOUTCLK_IN;
       wire                                          PIPE_DCLK_IN;
       wire                                          PIPE_USERCLK1_IN;
       wire                                          PIPE_USERCLK2_IN;
       wire                                          PIPE_OOBCLK_IN;
       wire                                          PIPE_MMCM_LOCK_IN;
       
       wire                                          PIPE_TXOUTCLK_OUT;
       wire [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]       PIPE_RXOUTCLK_OUT;
       wire [(PL_LINK_CAP_MAX_LINK_WIDTH-1):0]       PIPE_PCLK_SEL_OUT;
       wire                                          PIPE_GEN3_OUT;
       
       //----------------------------------------------------------------------------------------------------------------//
       //  AXI Interface                                                                                                 //
       //----------------------------------------------------------------------------------------------------------------//
       
       wire                                          user_clk;
       wire                                          user_resetn;
       
       // Wires for Avery HOT/WARM and COLD RESET
       wire                                          avy_sys_rst_n_c;
       wire                                          avy_cfg_hot_reset_out;
       reg                                           avy_sys_rst_n_g;
       reg                                           avy_cfg_hot_reset_out_g;
       
       assign avy_sys_rst_n_c = avy_sys_rst_n_g;
       assign avy_cfg_hot_reset_out = avy_cfg_hot_reset_out_g;
       initial begin 
          avy_sys_rst_n_g = 1;
          avy_cfg_hot_reset_out_g =0;
       end
    
   
       //----------------------------------------------------------------------------------------------------------------//
       //    System(SYS) Interface                                                                                       //
       //----------------------------------------------------------------------------------------------------------------//
   
       wire                                           sys_clk;
       wire                                           sys_rst_n_c;
   
       // User Clock LED Heartbeat
       reg [25:0]                                    user_clk_heartbeat;
       reg [C_NUM_USR_IRQ-1:0]                       usr_irq_req = 0;
       wire [C_NUM_USR_IRQ-1:0]                      usr_irq_ack;
   
       //-- AXI Master Write Address Channel
       wire [C_M_AXI_ADDR_WIDTH-1:0]                 m_axi_awaddr;
       wire [C_M_AXI_ID_WIDTH-1:0]                   m_axi_awid;
       wire [2:0]                                    m_axi_awprot;
       wire [1:0]                                    m_axi_awburst;
       wire [2:0]                                    m_axi_awsize;
       wire [3:0]                                    m_axi_awcache;
       wire [7:0]                                    m_axi_awlen;
       wire                                          m_axi_awlock;
       wire                                          m_axi_awvalid;
       wire                                          m_axi_awready;
   
       //-- AXI Master Write Data Channel
       wire [C_M_AXI_DATA_WIDTH-1:0]                 m_axi_wdata;
       wire [(C_M_AXI_DATA_WIDTH/8)-1:0]             m_axi_wstrb;
       wire                                          m_axi_wlast;
       wire                                          m_axi_wvalid;
       wire                                          m_axi_wready;
       //-- AXI Master Write Response Channel
       wire                                          m_axi_bvalid;
       wire                                          m_axi_bready;
       wire [C_M_AXI_ID_WIDTH-1 : 0]                 m_axi_bid;
       wire [1:0]                                    m_axi_bresp ;
   
       //-- AXI Master Read Address Channel
       wire [C_M_AXI_ID_WIDTH-1 : 0]                 m_axi_arid;
       wire [C_M_AXI_ADDR_WIDTH-1:0]                 m_axi_araddr;
       wire [7:0]                                    m_axi_arlen;
       wire [2:0]                                    m_axi_arsize;
       wire [1:0]                                    m_axi_arburst;
       wire [2:0]                                    m_axi_arprot;
       wire                                          m_axi_arvalid;
       wire                                          m_axi_arready;
       wire                                          m_axi_arlock;
       wire [3:0]                                    m_axi_arcache;
   
       //-- AXI Master Read Data Channel
       wire [C_M_AXI_ID_WIDTH-1 : 0]                 m_axi_rid;
       wire [C_M_AXI_DATA_WIDTH-1:0]                 m_axi_rdata;
       wire [1:0]                                    m_axi_rresp;
       wire                                          m_axi_rvalid;
       wire                                          m_axi_rready;
   
   
   
       wire [2:0]                                    msi_vector_width;
       wire                                          msi_enable;
      
      // AXI ST interface to user
       wire [C_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_0;
       wire                                        m_axis_h2c_tlast_0;
       wire                                        m_axis_h2c_tvalid_0;
       wire                                        m_axis_h2c_tready_0;
       wire [C_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_1;
       wire                                        m_axis_h2c_tlast_1;
       wire                                        m_axis_h2c_tvalid_1;
     //wire                                        m_axis_h2c_tready_1;
       wire [C_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_2;
       wire                                        m_axis_h2c_tlast_2;
       wire                                        m_axis_h2c_tvalid_2;
     //wire                                        m_axis_h2c_tready_2;
       wire [C_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_3;
       wire                                        m_axis_h2c_tlast_3;
       wire                                        m_axis_h2c_tvalid_3;
     //wire                                        m_axis_h2c_tready_3;
       wire [3:0]                                  leds;
   
     //assign m_axis_h2c_tready_1 = 1'b1;
     //assign m_axis_h2c_tready_2 = 1'b1;
     //assign m_axis_h2c_tready_3 = 1'b1;
   
       // Ref clock buffer
       IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
       // Reset buffer
       IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
       // LED buffers
       OBUF led_0_obuf (.O(led_0), .I(leds[0]));
       OBUF led_1_obuf (.O(led_1), .I(leds[1]));
       OBUF led_2_obuf (.O(led_2), .I(leds[2]));
       OBUF led_3_obuf (.O(led_3), .I(leds[3]));
   
        
     // Core Top Level Wrapper
     xdma xdma_i 
        (
         //---------------------------------------------------------------------------------------//
         //  PCI Express (pci_exp) Interface                                                      //
         //---------------------------------------------------------------------------------------//
         .sys_clk         ( sys_clk ),
         .sys_rst_n       ( sys_rst_n_c ),
         
         // Tx
         .pci_exp_txn     ( pci_exp_txn ),
         .pci_exp_txp     ( pci_exp_txp ),
         
         // Rx
         .pci_exp_rxn     ( pci_exp_rxn ),
         .pci_exp_rxp     ( pci_exp_rxp ),
   
          // AXI MM Interface
         .m_axi_awid      (m_axi_awid  ),
         .m_axi_awaddr    (m_axi_awaddr),
         .m_axi_awlen     (m_axi_awlen),
         .m_axi_awsize    (m_axi_awsize),
         .m_axi_awburst   (m_axi_awburst),
         .m_axi_awprot    (m_axi_awprot),
         .m_axi_awvalid   (m_axi_awvalid),
         .m_axi_awready   (m_axi_awready),
         .m_axi_awlock    (m_axi_awlock),
         .m_axi_awcache   (m_axi_awcache),
         .m_axi_wdata     (m_axi_wdata),
         .m_axi_wstrb     (m_axi_wstrb),
         .m_axi_wlast     (m_axi_wlast),
         .m_axi_wvalid    (m_axi_wvalid),
         .m_axi_wready    (m_axi_wready),
         .m_axi_bid       (m_axi_bid),
         .m_axi_bresp     (m_axi_bresp),
         .m_axi_bvalid    (m_axi_bvalid),
         .m_axi_bready    (m_axi_bready),
         .m_axi_arid      (m_axi_arid),
         .m_axi_araddr    (m_axi_araddr),
         .m_axi_arlen     (m_axi_arlen),
         .m_axi_arsize    (m_axi_arsize),
         .m_axi_arburst   (m_axi_arburst),
         .m_axi_arprot    (m_axi_arprot),
         .m_axi_arvalid   (m_axi_arvalid),
         .m_axi_arready   (m_axi_arready),
         .m_axi_arlock    (m_axi_arlock),
         .m_axi_arcache   (m_axi_arcache),
         .m_axi_rid       (m_axi_rid),
         .m_axi_rdata     (m_axi_rdata),
         .m_axi_rresp     (m_axi_rresp),
         .m_axi_rlast     (m_axi_rlast),
         .m_axi_rvalid    (m_axi_rvalid),
         .m_axi_rready    (m_axi_rready),
   
        .usr_irq_req       (usr_irq_req),
        .usr_irq_ack       (usr_irq_ack),
   
        // Config managemnet interface
        .cfg_mgmt_addr  ( 19'b0 ),
        .cfg_mgmt_write ( 1'b0 ),
        .cfg_mgmt_write_data ( 32'b0 ),
        .cfg_mgmt_byte_enable ( 4'b0 ),
        .cfg_mgmt_read  ( 1'b0 ),
        .cfg_mgmt_read_data (),
        .cfg_mgmt_read_write_done (),
        .cfg_mgmt_type1_cfg_reg_access ( 1'b0 ),
   
         //-- AXI Global
         .axi_aclk        ( user_clk ),
         .axi_aresetn     ( user_resetn ),
         .user_lnk_up     ( user_lnk_up )
        );
   
   
     // XDMA application, vgg16 accelerator
     vgg_acc accel(
   
         // AXI Memory Mapped interface
         .s_axi_awid      (m_axi_awid),
         .s_axi_awaddr    (m_axi_awaddr[31:0]),
         .s_axi_awlen     (m_axi_awlen),
         .s_axi_awsize    (m_axi_awsize),
         .s_axi_awburst   (m_axi_awburst),
         .s_axi_awvalid   (m_axi_awvalid),
         .s_axi_awready   (m_axi_awready),
         .s_axi_wdata     (m_axi_wdata),
         .s_axi_wstrb     (m_axi_wstrb),
         .s_axi_wlast     (m_axi_wlast),
         .s_axi_wvalid    (m_axi_wvalid),
         .s_axi_wready    (m_axi_wready),
         .s_axi_bid       (m_axi_bid),
         .s_axi_bresp     (m_axi_bresp),
         .s_axi_bvalid    (m_axi_bvalid),
         .s_axi_bready    (m_axi_bready),
         .s_axi_arid      (m_axi_arid),
         .s_axi_araddr    (m_axi_araddr[31:0]),
         .s_axi_arlen     (m_axi_arlen),
         .s_axi_arsize    (m_axi_arsize),
         .s_axi_arburst   (m_axi_arburst),
         .s_axi_arvalid   (m_axi_arvalid),
         .s_axi_arready   (m_axi_arready),
         .s_axi_rid       (m_axi_rid),
         .s_axi_rdata     (m_axi_rdata),
         .s_axi_rresp     (m_axi_rresp),
         .s_axi_rlast     (m_axi_rlast),
         .s_axi_rvalid    (m_axi_rvalid),
         .s_axi_rready    (m_axi_rready),
   
         .user_clk        (user_clk),
         .user_resetn     (user_resetn),
         .user_lnk_up     (user_lnk_up),
         .sys_rst_n       (sys_rst_n_c),
         .leds            (leds),
   
         // ddr interface
         .ddr_sys_rst          (ddr_sys_rst),
         .ddr_sys_clk_p        (ddr_sys_clk_p),
         .ddr_sys_clk_n        (ddr_sys_clk_n),
         .ddr3_addr            (ddr3_addr),
         .ddr3_ba              (ddr3_ba),
         .ddr3_cas_n           (ddr3_cas_n),
         .ddr3_ck_n            (ddr3_ck_n),
         .ddr3_ck_p            (ddr3_ck_p),
         .ddr3_cke             (ddr3_cke),
         .ddr3_ras_n           (ddr3_ras_n),
         .ddr3_reset_n         (ddr3_reset_n),
         .ddr3_we_n            (ddr3_we_n),
         .ddr3_dq              (ddr3_dq),
         .ddr3_dqs_n           (ddr3_dqs_n),
         .ddr3_dqs_p           (ddr3_dqs_p),
         .ddr3_cs_n            (ddr3_cs_n),
         .ddr3_dm              (ddr3_dm),
         .ddr3_odt             (ddr3_odt)
   
     );
   
endmodule
