//------------------------------------------------------------------------
// File       : ddr_cmd_gen.v
//
// Description: ddr user interface command generator
//
// input      : address flags on BRAM
// output     : UI commands
//
// Version    : 1.1
//------------------------------------------------------------------------

module ddr_cmd_gen(
  // ddr input/output
  output reg  [29:0]      ddr_addr,
  output reg  [2:0]       ddr_cmd,
  output reg              ddr_en,
  output reg  [511:0]     ddr_wdf_data,
  output reg              ddr_wdf_end,
  output reg              ddr_wdf_wren,
  output reg  [63:0]      ddr_wdf_mask,
  input  wire [511:0]     ddr_rd_data,
  input  wire             ddr_rd_data_end,
  input  wire             ddr_rd_data_valid,
  input  wire             ddr_rdy,
  input  wire             ddr_wdf_rdy,
  input  wire             ddr_clk,
  input  wire             ddr_clk_sync_rst,
  input  wire             ddr_init_calib_complete,
  // bram interface
  input  wire [63:0]      ddr_data_from_bram,       // data read from BRAM
  output reg  [63:0]      ddr_data_to_bram,         // data write to BRAM
  output reg  [9:0]       ddr_addr_to_bram,         // addr write to BRAM
  output reg              ddr_bram_wr_en,           // BRAM write enable
  output reg              ddr_bram_rd_en,           // BRAM read enable

  // adapter write
  input  wire             ddr_wr_req,
  output reg              ddr_wr_end,
  input  wire [3:0]       ddr_stage_flags_from,

  // vgg interface
  input  wire             ddr_vgg_idle,
  output reg              ddr_vgg_data_ready,

  // adapter read
  input  wire             ddr_rd_req,
  input  wire             ddr_rd_end,
  output reg  [3:0]       ddr_stage_flags_to,
  input  wire [31:0]      ddr_req_addr
  );

  localparam          STAGE_DEPTH  = 10'h3ff;
  localparam          STAGE_DEPTH_PLUS1  = 11'h400;
  localparam          STAGE0_END = 10'hff;
  localparam          STAGE1_END = 10'h1ff;
  localparam          STAGE2_END = 10'h2ff;
  localparam          STAGE3_END = 10'h3ff;
  localparam          STAGE0_START = 10'h0;
  localparam          STAGE1_START = 10'h100;
  localparam          STAGE2_START = 10'h200;
  localparam          STAGE3_START = 10'h300;
  localparam          STAGE_IN_BIT = 8; // one stage depth in bit
  // states
  localparam          DDR_RST      = 3'b000;
  localparam          DDR_WR_WAIT  = 3'b001;
  localparam          DDR_WR_DATA  = 3'b010;
  localparam          DDR_RD_DATA_ = 3'b011;
  //localparam          DDR_RD_WAIT  = 3'b100;

  reg  [29:0]          _base_addr;
  reg  [29:0]          _ddr_offset;
  reg  [2:0]           _rdwr_state;
  reg  [2:0]           _next_state;
  reg  [9:0]           _bram_offset;
  reg                  _bram_next;
  reg                  _ddr_next;
  reg                  _rd_end_reg;
  wire                 _rising_edge_rd;

  localparam    END_OF_DATA  = 32'h6c5fff + {6'b10, 26'd0}; // <-xxxxxxx end of parameter data address
//  localparam    END_OF_IMG   = 32'h2fffff + {6'b00, 26'd0}; // <-xxxxxxx end of parameter data address 64*3*16*16*4*64*16bit/64bit-1
  localparam    END_OF_IMG   = 32'hc3ff + {6'b00, 26'd0}; // <-xxxxxxx end of input address 3*16*16*4*64*16bit/64bit + 8192*8bits/64 -1
  // app
  reg   _ddr_vgg_idle_reg;
  wire  _ddr_vgg_idle_rising_edge;
  assign _ddr_vgg_idle_rising_edge = ddr_vgg_idle && (!_ddr_vgg_idle_reg);
  always@(posedge ddr_clk) begin
    _ddr_vgg_idle_reg <= ddr_vgg_idle;
  end
  always@(posedge ddr_clk) begin
    if(ddr_clk_sync_rst) begin
      ddr_vgg_data_ready <= 1'b0;
    end else begin
      if((ddr_addr== END_OF_IMG) && (ddr_cmd == 3'b0)) begin
        ddr_vgg_data_ready <= 1'b1;
      end else if(_ddr_vgg_idle_rising_edge) begin
        ddr_vgg_data_ready <= 1'b0;
      end
    end
  end

  always@(posedge ddr_clk) begin
    if(ddr_clk_sync_rst)
      _rdwr_state <= DDR_RST;
    else
      _rdwr_state <= _next_state;
  end
  // addr offset
  always@(posedge ddr_clk) begin
    if(ddr_clk_sync_rst) begin
      _bram_offset  <= 10'b0;
      _ddr_offset   <= 30'b0;
    end else begin
      if(_rdwr_state == DDR_RST) begin
        _bram_offset  <= 10'b0;
        _ddr_offset   <= 30'b0;
      end else begin
        if(_bram_next) _bram_offset <= _bram_offset + 10'b1;
        if(_ddr_next)  _ddr_offset  <= _ddr_offset + 30'b1;
      end
    end
  end
  // base addr
  always@(posedge ddr_clk) begin
    if(ddr_clk_sync_rst)
      _base_addr  <= 30'b0;
    else
      if(ddr_wr_req || ddr_rd_req)
        _base_addr  <= {ddr_req_addr[29:10],10'b0};
  end
  // stage flags
  assign  _rising_edge_rd = ddr_rd_end && (!_rd_end_reg);
  always@(posedge ddr_clk) begin
    if(ddr_clk_sync_rst) begin
      ddr_stage_flags_to  <= 4'b0;
      _rd_end_reg         <= 1'b0;
    end else begin
      if((_bram_offset == STAGE0_END) && (_rdwr_state == DDR_RD_DATA_)) begin
        ddr_stage_flags_to[0] <= 1'b1;
      end else if((_bram_offset == STAGE1_END) && (_rdwr_state == DDR_RD_DATA_)) begin
        ddr_stage_flags_to[1] <= 1'b1;
      end else if((_bram_offset == STAGE2_END) && (_rdwr_state == DDR_RD_DATA_)) begin
        ddr_stage_flags_to[2] <= 1'b1;
      end else if((_bram_offset == STAGE3_END) && (_rdwr_state == DDR_RD_DATA_)) begin
        ddr_stage_flags_to[3] <= 1'b1;
      end

      _rd_end_reg <= ddr_rd_end;
      if(_rising_edge_rd) ddr_stage_flags_to <= 4'b0;
    end
  end

  // state transition
  always@(_rdwr_state or ddr_wr_req or ddr_rd_req or ddr_stage_flags_to or ddr_en or
          ddr_stage_flags_from or ddr_addr or ddr_addr_to_bram or ddr_bram_wr_en) begin
    _next_state        = DDR_RST;
    case(_rdwr_state)
      DDR_RST: begin
        if(ddr_wr_req) begin
          _next_state = DDR_WR_WAIT;
        end else if(ddr_rd_req && !ddr_stage_flags_to[3]) begin
          _next_state = DDR_RD_DATA_;
        end else begin
          _next_state = DDR_RST;
        end
      end

      DDR_WR_WAIT: begin
      // check stage full
        if(ddr_addr[9:0]  == STAGE0_START) begin
          if(ddr_stage_flags_from[0] == 1'b1) _next_state = DDR_WR_DATA;
          else                                _next_state = DDR_WR_WAIT;
        end else if(ddr_addr[9:0]  == STAGE1_START) begin
          if(ddr_stage_flags_from[1] == 1'b1) _next_state = DDR_WR_DATA;
          else                                _next_state = DDR_WR_WAIT;
        end else if(ddr_addr[9:0]  == STAGE2_START) begin
          if(ddr_stage_flags_from[2] == 1'b1) _next_state = DDR_WR_DATA;
          else                                _next_state = DDR_WR_WAIT;
        end else if(ddr_addr[9:0]  == STAGE3_START) begin
          if(ddr_stage_flags_from[3] == 1'b1) _next_state = DDR_WR_DATA;
          else                                _next_state = DDR_WR_WAIT;
        end else begin
          _next_state = DDR_WR_DATA;
        end
      end

      DDR_WR_DATA: begin
      // write data
        if(((ddr_addr[9:0] == STAGE0_END) ||
            (ddr_addr[9:0] == STAGE1_END) ||
            (ddr_addr[9:0] == STAGE2_END)) && ddr_en) begin
          _next_state = DDR_WR_WAIT;
        end else if((ddr_addr[9:0] == STAGE3_END) && ddr_en) begin // last data done
          _next_state = DDR_RST;
        end else begin
          _next_state = DDR_WR_DATA;
        end
      end

      DDR_RD_DATA_: begin
        if((ddr_addr_to_bram == STAGE3_END) && ddr_bram_wr_en) // last data writen
          _next_state = DDR_RST;
        else
          _next_state = DDR_RD_DATA_;
      end
    endcase
  end

  // logic
  always@(_rdwr_state or ddr_wr_req or ddr_rd_req or
          ddr_stage_flags_from or ddr_rdy or ddr_wdf_rdy or
          _bram_offset or _ddr_offset or _base_addr or
          ddr_rd_data_valid or ddr_rd_data or ddr_data_from_bram) begin
    // default value
    ddr_bram_rd_en  = 1'b0;
    ddr_addr_to_bram= 10'b0;
    ddr_en          = 1'b0;
    ddr_cmd         = 3'b1;
    ddr_addr        = 30'b0;
    ddr_data_to_bram= 64'b0;
    ddr_bram_wr_en  = 1'b0;
    ddr_wdf_mask    = 64'b0;
    ddr_wdf_data    = 512'b0;
    ddr_wdf_wren    = 1'b0;
    ddr_wdf_end     = 1'b1;
    ddr_wr_end      = 1'b1;
    _bram_next      = 1'b0;
    _ddr_next       = 1'b0;

    case(_rdwr_state)
      DDR_RST: begin
        ddr_addr        = 30'b0;
        ddr_addr_to_bram= 10'b0;
      end

      DDR_WR_WAIT: begin
        // signal to ifaceAdapter
        ddr_wr_end  = 1'b0;
        ddr_addr    = _base_addr + _ddr_offset;
        if(ddr_addr[9:0] == STAGE0_START) begin
          if(ddr_stage_flags_from[0] == 1'b1) begin
            ddr_bram_rd_en  = 1'b1;
            _bram_next      = 1'b1;
            ddr_addr_to_bram= _bram_offset;
          end
        end else if(ddr_addr[9:0]  == STAGE1_START) begin
          if(ddr_stage_flags_from[1] == 1'b1) begin
            ddr_bram_rd_en  = 1'b1;
            _bram_next      = 1'b1;
            ddr_addr_to_bram= _bram_offset;
          end
        end else if(ddr_addr[9:0]  == STAGE2_START) begin
          if(ddr_stage_flags_from[2] == 1'b1) begin
            ddr_bram_rd_en  = 1'b1;
            _bram_next      = 1'b1;
            ddr_addr_to_bram= _bram_offset;
          end
        end else if(ddr_addr[9:0]  == STAGE3_START) begin
          if(ddr_stage_flags_from[3] == 1'b1) begin
            ddr_bram_rd_en  = 1'b1;
            _bram_next      = 1'b1;
            ddr_addr_to_bram= _bram_offset;
          end
        end
      end

      DDR_WR_DATA: begin
      // read from bram, write to ddr
        // signal to ifaceAdapter
        ddr_wr_end    = 1'b0;
        if(ddr_rdy && ddr_wdf_rdy) begin
          // ddr control
          ddr_en        = 1'b1;
          ddr_cmd       = 3'b0;
          ddr_wdf_wren  = 1'b1;
          ddr_wdf_end   = 1'b1;
          _ddr_next     = 1'b1;
          ddr_addr      = _base_addr + _ddr_offset;
          // ddr write-data
          case(ddr_addr[2:0])
            3'h0: begin
              ddr_wdf_mask = 64'hffff_ffff_ffff_ff00;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 0;
            end
            3'h1: begin
              ddr_wdf_mask = 64'hffff_ffff_ffff_00ff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 64;
            end
            3'h2: begin
              ddr_wdf_mask = 64'hffff_ffff_ff00_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 128;
            end
            3'h3: begin
              ddr_wdf_mask = 64'hffff_ffff_00ff_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 192;
            end
            3'h4: begin
              ddr_wdf_mask = 64'hffff_ff00_ffff_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 256;
            end
            3'h5: begin
              ddr_wdf_mask = 64'hffff_00ff_ffff_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 320;
            end
            3'h6: begin
              ddr_wdf_mask = 64'hff00_ffff_ffff_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 384;
            end
            3'h7: begin
              ddr_wdf_mask = 64'h00ff_ffff_ffff_ffff;
              ddr_wdf_data = {448'b0,ddr_data_from_bram} << 448;
            end
          endcase
          // bram
          ddr_addr_to_bram= _bram_offset;
          ddr_bram_rd_en  = 1'b1;
          if(_bram_offset[STAGE_IN_BIT-1:0]=={STAGE_IN_BIT{1'b0}}) _bram_next  = 1'b0;
          else                        _bram_next  = 1'b1;

        end else begin
          ddr_bram_rd_en  = 1'b0;
          ddr_addr_to_bram= _bram_offset;
          ddr_addr        = _base_addr + _ddr_offset;
        end
      end

      DDR_RD_DATA_: begin
        // ddr
        ddr_addr  = _base_addr + _ddr_offset;
        if(ddr_rdy) begin
          ddr_cmd = 3'b1;
          if(_ddr_offset > STAGE_DEPTH) begin
            ddr_en    = 1'b0;
            _ddr_next = 1'b0;
          end else begin
            ddr_en    = 1'b1;
            _ddr_next = 1'b1;
          end
        end
        // bram
        if(ddr_rd_data_valid) begin
          ddr_bram_wr_en    = 1'b1;
          ddr_data_to_bram  = ddr_rd_data[63:0];
          ddr_addr_to_bram  = _bram_offset;
          _bram_next        = 1'b1;
        end else begin
          ddr_bram_wr_en    = 1'b0;
          ddr_data_to_bram  = ddr_rd_data[63:0];
          ddr_addr_to_bram  = _bram_offset;
          _bram_next        = 1'b0;
        end
      end
    endcase
  end


endmodule
