//
// File       : sync_ddr2axi_1bit.v
//
// Description: 1 bit data sychronizer, from ddr clock domain to axi clock domain
//
// Version    : 1.0
//

module sync_ddr2axi_1bit(
  input   wire           rst,
  input   wire           axi_clk,
  input   wire           ddr_clk,
  input   wire [0:0]     ddr_data,
  output  wire [0:0]     axi_data
  );

  wire [0:0]    axi_stage1;
  wire [0:0]    axi_stage2;

  // ddr data
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      ddrdata_0(
        .D(ddr_data[0]),
        .Q(axi_stage1[0]),
        .CE(1'b1),
        .C(ddr_clk),
        .CLR(rst)
        );

  // axi stage1
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      axidata1_0(
        .D(axi_stage1[0]),
        .Q(axi_stage2[0]),
        .CE(1'b1),
        .C(axi_clk),
        .CLR(rst)
        );
  // axi stage2
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      axidata2_0(
        .D(axi_stage2[0]),
        .Q(axi_data[0]),
        .CE(1'b1),
        .C(axi_clk),
        .CLR(rst)
        );

endmodule
