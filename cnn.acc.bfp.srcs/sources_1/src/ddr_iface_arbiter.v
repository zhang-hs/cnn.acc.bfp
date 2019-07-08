// ---------------------------------------------------
// File       : ddr_iface_arbiter.v
//
// Description: ddr interface arbiter:
//                a) I/O from PC
//                b) I/O from vgg module
//
// Version    : 1.1
// ---------------------------------------------------

//`define sim_
module ddr_iface_arbiter (
    input  wire           clk,
    input  wire           rst_n,
    // ddr
    output reg  [29:0]    ddr_addr,
    output reg  [2:0]     ddr_cmd,
    output reg            ddr_en,
    output reg  [511:0]   ddr_wdf_data,
    output reg  [63:0]    ddr_wdf_mask, // stuck at 64'b1
    output reg            ddr_wdf_end,  // stuck at 1'b1
    output reg            ddr_wdf_wren,
    //
    input  wire           arb_data_ready, // deasserted -- PCIe, asserted -- vgg module, transinet signal, arbiter enable
    input  wire           arb_cnn_finish, // asserted -- PCIe, deasserted -- vgg module, transinet signal, arbiter disable
    // pcie
    input  wire [29:0]    arb_pcie_addr,
    input  wire [2:0]     arb_pcie_cmd,
    input  wire           arb_pcie_en,
    input  wire [511:0]   arb_pcie_wdf_data,
    input  wire [63:0]    arb_pcie_wdf_mask, // stuck at 64'b1
    input  wire           arb_pcie_wdf_end,  // stuck at 1'b1
    input  wire           arb_pcie_wdf_wren,
    // vgg module conv.
    input  wire           arb_conv_req,
    output wire           arb_conv_grant,
    input  wire [29:0]    arb_conv_addr,
    input  wire [2:0]     arb_conv_cmd,
    input  wire           arb_conv_en,
    input  wire [511:0]   arb_conv_wdf_data,
    input  wire [63:0]    arb_conv_wdf_mask, // stuck at 64'b1
    input  wire           arb_conv_wdf_end,  // stuck at 1'b1
    input  wire           arb_conv_wdf_wren,
    // vgg module fc.
    input  wire           arb_fc_req,
    output wire           arb_fc_grant,
    input  wire [29:0]    arb_fc_addr,
    input  wire [2:0]     arb_fc_cmd,
    input  wire           arb_fc_en,
    input  wire [511:0]   arb_fc_wdf_data,
    input  wire [63:0]    arb_fc_wdf_mask, // stuck at 64'b1
    input  wire           arb_fc_wdf_end,  // stuck at 1'b1
    input  wire           arb_fc_wdf_wren
  );

  localparam PRIO_CONV = 2'd1;
  localparam PRIO_FC   = 2'd2;
  localparam GRNT_PCIE = 2'd0;
  localparam GRNT_CONV = 2'd1;
  localparam GRNT_FC   = 2'd2;

  reg  [1:0]  _arb_grant;
  reg  [1:0]  _arb_priority; // 2'b1 -- conv, 2'b2 -- fc
  reg         _arb_en;

  assign arb_conv_grant = _arb_grant[0] && arb_conv_req;
  assign arb_fc_grant   = _arb_grant[1] && arb_fc_req;

//`ifdef sim_
//always@(posedge clk) begin
//  if(arb_conv_grant) begin
//    $display("%t: grant conv @ ddr_iface_arbiter.v", $realtime);
//  end else if(arb_fc_grant) begin
//    $display("%t: grant fc @ ddr_iface_arbiter.v", $realtime);
//  end
//end
//`endif

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _arb_en <= 1'b0;
    end else begin
      if(arb_data_ready) begin
        _arb_en <= 1'b1;
      end else if(arb_cnn_finish) begin
        _arb_en <= 1'b0;
      end
    end
  end

  // priority update
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _arb_priority <= PRIO_CONV;
    end else begin
      if(_arb_en) begin
        if(_arb_grant==GRNT_CONV) begin
          _arb_priority <= PRIO_FC;
        end else begin
          _arb_priority <= PRIO_CONV;
        end
      end
    end
  end

  // grant request
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _arb_grant <= GRNT_PCIE;
    end else begin
      if(_arb_en) begin
        if((arb_conv_req || arb_fc_req) && _arb_grant==GRNT_PCIE) begin
          if(_arb_priority==PRIO_FC) begin
            if(arb_fc_req) begin
              _arb_grant <= GRNT_FC;
            end else begin
              _arb_grant <= GRNT_CONV;
            end
          end else if(_arb_priority==PRIO_CONV) begin
            if(arb_conv_req) begin
              _arb_grant <= GRNT_CONV;
            end else begin
              _arb_grant <= GRNT_FC;
            end
          end
        end else if((arb_conv_req || arb_fc_req) && _arb_grant==GRNT_CONV) begin
          if(!arb_conv_req) begin
            _arb_grant <= GRNT_FC;
          end else begin
            _arb_grant <= GRNT_CONV;
          end
        end else if((arb_conv_req || arb_fc_req) && _arb_grant==GRNT_FC) begin
          if(!arb_fc_req) begin
            _arb_grant <= GRNT_CONV;
          end else begin
            _arb_grant <= GRNT_FC;
          end
        end else begin
          _arb_grant  <= GRNT_PCIE;
        end
      end else begin
        _arb_grant <= GRNT_PCIE;
      end
    end
  end
  // grant request two-process coding style (ToDo)

  always@(_arb_grant or

          arb_pcie_addr     or arb_pcie_cmd     or arb_pcie_en        or arb_pcie_wdf_data or
          arb_pcie_wdf_mask or arb_pcie_wdf_end or arb_pcie_wdf_wren  or

          arb_conv_addr     or arb_conv_cmd     or arb_conv_en        or arb_conv_wdf_data or
          arb_conv_wdf_mask or arb_conv_wdf_end or arb_conv_wdf_wren  or

          arb_fc_addr       or arb_fc_cmd       or arb_fc_en          or arb_fc_wdf_data or
          arb_fc_wdf_mask   or arb_fc_wdf_end   or arb_fc_wdf_wren
          ) begin
    ddr_addr      = 30'd0;
    ddr_cmd       = 3'd0;
    ddr_en        = 1'd0;
    ddr_wdf_data  = 512'd0;
    ddr_wdf_mask  = 64'd0;
    ddr_wdf_end   = 1'd0;
    ddr_wdf_wren  = 1'd0;

    case(_arb_grant)
      GRNT_PCIE: begin
        ddr_addr                = arb_pcie_addr;
        ddr_cmd                 = arb_pcie_cmd;
        ddr_en                  = arb_pcie_en;
        ddr_wdf_data            = arb_pcie_wdf_data;
        ddr_wdf_mask            = arb_pcie_wdf_mask;
        ddr_wdf_end             = arb_pcie_wdf_end;
        ddr_wdf_wren            = arb_pcie_wdf_wren;
      end
      GRNT_CONV: begin
        ddr_addr                = arb_conv_addr;
        ddr_cmd                 = arb_conv_cmd;
        ddr_en                  = arb_conv_en;
        ddr_wdf_data            = arb_conv_wdf_data;
        ddr_wdf_mask            = arb_conv_wdf_mask;
        ddr_wdf_end             = arb_conv_wdf_end;
        ddr_wdf_wren            = arb_conv_wdf_wren;
      end
      GRNT_FC: begin
        ddr_addr                = arb_fc_addr;
        ddr_cmd                 = arb_fc_cmd;
        ddr_en                  = arb_fc_en;
        ddr_wdf_data            = arb_fc_wdf_data;
        ddr_wdf_mask            = arb_fc_wdf_mask;
        ddr_wdf_end             = arb_fc_wdf_end;
        ddr_wdf_wren            = arb_fc_wdf_wren;
      end
    endcase
  end

endmodule
