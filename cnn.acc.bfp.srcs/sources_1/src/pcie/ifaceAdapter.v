//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : ifaceAdapter.v
// Description: adapte axi interface to dram
//              write/read to/from bram through axi interface simple
//              implementation, assume INCR burst, AWSIZE=3'b011, ID=4'b0
//              add interrupt when finishing transfer
//
//              add states to signal ddr to accept data
//
// Version    : 1.2
//-----------------------------------------------------------------------------
`define RDWR_RST_AXI 3'b000
`define WR_START_AXI 3'b001
`define WR_DATA_AXI  3'b010
`define WR_RESP_AXI  3'b011
`define RD_START_AXI 3'b100
`define RD_DATA_AXI  3'b101
`define RD_END_AXI   3'b110

module ifaceAdapter(
    // AXI Memory Mapped interface
    //write address channel
    input  wire [3:0]   axi_awid,
    input  wire [31:0]  axi_awaddr,
    input  wire [7:0]   axi_awlen,
    input  wire [2:0]   axi_awsize,
    input  wire [1:0]   axi_awburst,
    input  wire         axi_awvalid,
    output reg          axi_awready,
    //write data channel
    input  wire [63:0]  axi_wdata,
    input  wire [7:0]   axi_wstrb,
    input  wire         axi_wlast,
    input  wire         axi_wvalid,
    output reg          axi_wready,
    //write response channel
    output reg  [3:0]   axi_bid,
    output reg  [1:0]   axi_bresp,
    output reg          axi_bvalid,
    input  wire         axi_bready,
    // read address channel
    input  wire [3:0]   axi_arid,
    input  wire [31:0]  axi_araddr,
    input  wire [7:0]   axi_arlen,
    input  wire [2:0]   axi_arsize,
    input  wire [1:0]   axi_arburst,
    input  wire         axi_arvalid,
    output reg          axi_arready,
    // read data channel
    output reg  [3:0]   axi_rid,
    output wire [63:0]  axi_rdata,
    output reg  [1:0]   axi_rresp,
    output reg          axi_rlast,
    output reg          axi_rvalid,
    input  wire         axi_rready,

    // System IO signals
    input  wire         axi_clk,
    input  wire         axi_reset_n,

    // sync
    output wire [3:0]   axi2ddr_stage_flags,
    output wire [31:0]  axi2ddr_req_addr,
    output wire         axi2ddr_rd_req,
    output wire         axi2ddr_rd_end, // axi idle
    output wire         axi2ddr_wr_req,
    input  wire         axi_wr_end,     // ddr idle
    input  wire [3:0]   axi_rd_stage_flags,
    // app
    input  wire         axi_acc_cnn_idle,
    // bram interface
    input  wire         ddr_clk,
    input  wire         bram_wr_en,
    input  wire         bram_rd_en,
    input  wire [9:0]   bram_addr,
    input  wire [63:0]  bram_din,
    output wire [63:0]  bram_dout
  );

  localparam    STAGE0_START = 10'h0;
  localparam    STAGE1_START = 10'h100;
  localparam    STAGE2_START = 10'h200;
  localparam    STAGE3_START = 10'h300;
  localparam    STAGE0_END   = 10'hff;
  localparam    STAGE1_END   = 10'h1ff;
  localparam    STAGE2_END   = 10'h2ff;
  localparam    STAGE3_END   = 10'h3ff;
  localparam    ONE_ADDR     = 10'h1;
  localparam    STAGE_DEPTH_PLUS1 = 11'h400;

  localparam    END_OF_DATA  = 32'h6c5fff + {6'b10, 26'd0}; // <-xxxxxxx end of parameter data address
  localparam    END_OF_IMG   = 32'h2fffff + {6'b00, 26'd0}; // <-xxxxxxx end of parameter data address 64*3*16*16*4*64*16bit/64bit-1
  localparam    RESET_DATA_READY = 32'h1;

  reg  [31:0]   _addr_base;
  reg  [31:0]   _addr_offset;
  //reg  [2:0]    _size_axi;
  wire [31:0]   _addr_axi;
  wire [63:0]   _data_in;
  wire [63:0]   _data_out;
  reg  [0:0]    _wr_en;
  reg  [0:0]    _rd_en;
  reg  [0:0]    _rd_next;
  (*mark_debug="TRUE"*)reg  [2:0]    _rdwr_state;
  reg  [2:0]    _next_state;

  reg           _wr_end_reg;
  wire          _rising_edge;
  reg  [3:0]    _stage_flags; // signal ddr

  reg           _rd_ddr_req;
  reg           _wr_ddr_req;
  reg           _rd_end;
  reg  [31:0]   _req_addr;

  assign _addr_axi = _addr_base + _addr_offset;
  assign _data_in  = axi_wdata;
  assign axi_rdata = _data_out;
  assign axi2ddr_wr_req = _wr_ddr_req;
  assign axi2ddr_rd_req = _rd_ddr_req;
  assign axi2ddr_rd_end = _rd_end;
  assign axi2ddr_stage_flags  = _stage_flags;
  assign axi2ddr_req_addr     = _req_addr;
  // rising edge detection
  assign _rising_edge   = axi_wr_end && (!_wr_end_reg);

//// signal to data ready
//always@(posedge axi_clk or negedge axi_reset_n) begin
//  if(!axi_reset_n) begin
//    axi_acc_data_ready <= 1'b0;
//  end else begin
//    if((_addr_axi  == END_OF_IMG) && ( _rdwr_state==`WR_START_AXI ||
//          _rdwr_state==`WR_DATA_AXI && _rdwr_state==`WR_RESP_AXI))begin // check end of address, if be END_OF_IMG -> transmit param then img
//      axi_acc_data_ready <= 1'b1;
//    end else if((_addr_axi == RESET_DATA_READY) && ( _rdwr_state==`WR_START_AXI ||
//          _rdwr_state==`WR_DATA_AXI && _rdwr_state==`WR_RESP_AXI)) begin
//      axi_acc_data_ready <= 1'b0;
//    end
//  end
//end



  // RD/WR state machine
  always@(axi_awvalid or axi_wlast or axi_bready
          or axi_arvalid  or _addr_offset or axi_arlen 
          or _rdwr_state or _stage_flags or axi_acc_cnn_idle) begin
    // state transition
    case(_rdwr_state)
      // writing state
      `RDWR_RST_AXI: begin
        if(axi_awvalid && (!_stage_flags[3]) && (axi_acc_cnn_idle)) begin
          _next_state  = `WR_START_AXI;
        end else if(axi_arvalid && (axi_acc_cnn_idle)) begin
          _next_state  = `RD_START_AXI;
        end else  begin
          _next_state  = `RDWR_RST_AXI;
        end
      end

      `WR_START_AXI: begin
        if(axi_wlast) _next_state  = `WR_RESP_AXI;
        else          _next_state  = `WR_DATA_AXI;
      end

      `WR_DATA_AXI: begin
        if(axi_wlast) _next_state  = `WR_RESP_AXI;
        else          _next_state  = `WR_DATA_AXI;
      end

      `WR_RESP_AXI: begin
        if(axi_bready) begin
          _next_state  = `RDWR_RST_AXI;
        end else begin
          _next_state  = `WR_RESP_AXI;
        end
      end

      // reading state
      `RD_START_AXI: begin
        _next_state = `RD_DATA_AXI;
      end

      `RD_DATA_AXI: begin
        if(_addr_offset == (axi_arlen + 8'h1)) begin
          _next_state = `RD_END_AXI;
        end else begin
          _next_state = `RD_DATA_AXI;
        end
      end

      `RD_END_AXI: begin
        _next_state = `RDWR_RST_AXI;
      end

      default: begin
        _next_state = `RDWR_RST_AXI;
      end
    endcase
  end

  // state flip flop
  always@(posedge axi_clk or negedge axi_reset_n) begin
  
    if(!axi_reset_n) begin
      _rdwr_state    <= `RDWR_RST_AXI;
      _addr_offset   <= 32'b0;
      _wr_end_reg    <= 1'b0;
      _stage_flags   <= 4'b0;
      _req_addr      <= 32'b0;
      _wr_ddr_req    <= 1'b0;
      _addr_base     <= 32'b0;
    end else begin
      _rdwr_state    <= _next_state;
      _wr_end_reg    <= axi_wr_end;

      if((_next_state == `WR_DATA_AXI) && axi_wvalid && axi_wready) begin
        _addr_offset <= _addr_offset + 1'b1;
      end else if(_next_state == `WR_RESP_AXI) begin
        _addr_offset <= 32'b0;
      end else if(_next_state == `RD_DATA_AXI && _rd_next && axi_rready) begin
        _addr_offset <= _addr_offset + 1'b1;
      end else if(_next_state == `RD_END_AXI) begin
        _addr_offset <= 32'b0;
      end
      if(_next_state == `WR_START_AXI) begin
        _addr_base  <= (axi_awaddr>>3);
      end else if(_next_state == `RD_START_AXI) begin
        _addr_base  <= (axi_araddr>>3);
      end else if(_next_state == `RDWR_RST_AXI) begin
        _addr_base  <= 32'b0;
      end

      // set flags
      if((_addr_axi[9:0] == STAGE3_END) && (_rdwr_state==`WR_DATA_AXI)) begin           // 10'h3ff
        _stage_flags[3] <= 1'b1;
      end else if((_addr_axi[9:0] == STAGE2_END) && (_rdwr_state==`WR_DATA_AXI)) begin  // 10'h2ff
        _stage_flags[2] <= 1'b1;
      end else if((_addr_axi[9:0] == STAGE1_END) && (_rdwr_state==`WR_DATA_AXI)) begin  // 10'h1ff
        _stage_flags[1] <= 1'b1;
      end else if((_addr_axi[9:0] == STAGE0_END) && (_rdwr_state==`WR_DATA_AXI)) begin  // 10'hff
        _stage_flags[0] <= 1'b1;
        _wr_ddr_req     <= 1'b1;
      end
      // clear flags
      if(_rising_edge)begin
        _stage_flags    <= 4'b0;
      end

      // store req address
      if(axi_awvalid ) begin
        _req_addr <= (axi_awaddr>>3);
      end else if(axi_arvalid) begin
        _req_addr <= (axi_araddr>>3);
      end

      // clear wr req
      if(!axi_wr_end) begin
        _wr_ddr_req <= 1'b0;
      end
    end
  end

  // logic
  always@(_rdwr_state or _addr_offset or axi_bready or 
          axi_awid or axi_awsize or axi_awaddr or axi_arid or
          axi_araddr or axi_arsize or axi_arlen or _addr_base or
          axi_rd_stage_flags or _addr_axi or axi_acc_cnn_idle) begin
    // default value
    axi_awready  = axi_acc_cnn_idle && (!_stage_flags[3]);
    axi_wready   = 1'b0;
    axi_bvalid   = 1'b0;
    axi_bid      = 4'b0;
    axi_bresp    = 2'b0;
    // reading
  //axi_arready  = 1'b1;
    axi_arready  = axi_acc_cnn_idle; // on cnn finished
    axi_rvalid   = 1'b0;
    axi_rid      = 4'b0;
    axi_rlast    = 1'b0;
    axi_rresp    = 2'b0;
    // control info
    //_size_axi    = 3'b0;
    _wr_en       = 1'b0;
    _rd_en       = 1'b0;
    // signal to ddr
    _rd_ddr_req  = 1'b0;
    _rd_end      = 1'b1;
    _rd_next     = 1'b0;

    case(_rdwr_state)
      `RDWR_RST_AXI: begin
        // writing
        axi_awready  = axi_acc_cnn_idle && (!_stage_flags[3]);
        axi_wready   = 1'b0;
        axi_bvalid   = 1'b0;
        axi_bid      = 4'b0;
        axi_bresp    = 2'b0;
        _wr_en       = 1'b0;
        _rd_en       = 1'b0;
        // reading
        axi_arready  = axi_acc_cnn_idle;
        axi_rvalid   = 1'b0;
        axi_rid      = 4'b0;
        axi_rlast    = 1'b0;
        axi_rresp    = 2'b0;
        // control info
        //_size_axi    = 3'b0;
      end

      `WR_START_AXI: begin // gathering info
        axi_bid     = axi_awid;
        axi_awready = 1'b0;
        axi_wready  = 1'b0;
        //_size_axi   = axi_awsize;
      end

      `WR_DATA_AXI: begin // begin transfering
        // adding address offset in sequencial logic
        axi_bid     = axi_awid;
        axi_awready = 1'b0;
        axi_wready  = 1'b1;
        _wr_en      = 1'b1;
      end

      `WR_RESP_AXI: begin
        axi_bid      = axi_awid;
        axi_awready  = 1'b0;
        axi_wready   = 1'b0;
        if(axi_bready) begin
          axi_bvalid = 1'b1;
          axi_bresp  = 2'b0; // OK
        end
      end

      // reading
      `RD_START_AXI: begin
        axi_rid     = axi_arid;
        //_size_axi   = axi_arsize;
        axi_arready = 1'b0;
        axi_rvalid  = 1'b0;
        if(axi_rd_stage_flags == 4'hf) begin
          _rd_en    = 1'b1;
          _rd_next  = 1'b1;
        end else begin
          _rd_en    = 1'b0;
          _rd_next  = 1'b0;
        end
      end

      `RD_DATA_AXI: begin
        axi_rid     = axi_arid;
        axi_arready = 1'b0;
        if(_addr_offset == (axi_arlen + 8'h1)) begin
          axi_rlast = 1'b1;
        end
        if(_addr_offset == 32'b0) begin
          axi_rvalid = 1'b0;
        end else begin
          axi_rvalid = 1'b1;
        end
        // mark 'end' in last stage
        if((_addr_offset[10:0]+{1'b0,_addr_base[9:0]} > STAGE3_START) &&
           (_addr_offset[10:0]+{1'b0,_addr_base[9:0]} <= STAGE_DEPTH_PLUS1))begin
          _rd_end = 1'b0;
        end

        if(_addr_axi[9:0] == STAGE0_START) begin
          if(axi_rd_stage_flags[0] == 1'b1) begin
            _rd_en    = 1'b1;
            _rd_next  = 1'b1;
          end else begin
            _rd_en    = 1'b0;
            _rd_next  = 1'b0;
            _rd_ddr_req = 1'b1;
          end
        end else if(_addr_axi[9:0] == STAGE1_START) begin
          if(axi_rd_stage_flags[1] == 1'b1) begin
            _rd_en    = 1'b1;
            _rd_next  = 1'b1;
          end else begin
            _rd_en    = 1'b0;
            _rd_next  = 1'b0;
          end
        end else if(_addr_axi[9:0] == STAGE2_START) begin
          if(axi_rd_stage_flags[2] == 1'b1) begin
            _rd_en    = 1'b1;
            _rd_next  = 1'b1;
          end else begin
            _rd_en    = 1'b0;
            _rd_next  = 1'b0;
          end
        end else if(_addr_axi[9:0] == STAGE3_START) begin
          if(axi_rd_stage_flags[3] == 1'b1) begin
            _rd_en    = 1'b1;
            _rd_next  = 1'b1;
          end else begin
            _rd_en    = 1'b0;
            _rd_next  = 1'b0;
          end
        end else begin
          _rd_en    = 1'b1;
          _rd_next  = 1'b1;
        end
      end

      `RD_END_AXI: begin
        axi_rid      = axi_arid;
        axi_arready  = 1'b0;
        axi_rvalid   = 1'b0;
        axi_rlast    = 1'b0;
        axi_rresp    = 2'b0;
      end

    endcase
  end

  mem64bit memBlk(
    .clka(axi_clk),    // input wire clka
    .ena(_wr_en || _rd_en),      // always enabled
    .wea(_wr_en),      // input wire [0 : 0] wea
    .addra(_addr_axi[9:0]),  // input wire [9 : 0] addra
    .dina(_data_in),    // input wire [63 : 0] dina
    .douta(_data_out),  // output wire [63 : 0] douta
    .clkb(ddr_clk),    // input wire clkb
    .enb((bram_rd_en || bram_wr_en)),      // input wire enb
    .web(bram_wr_en),      // input wire [0 : 0] web
    .addrb(bram_addr),  // input wire [9 : 0] addrb
    .dinb(bram_din),    // input wire [63 : 0] dinb
    .doutb(bram_dout)  // output wire [63 : 0] doutb
  );

endmodule
