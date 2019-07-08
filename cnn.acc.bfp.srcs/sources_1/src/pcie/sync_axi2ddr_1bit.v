//
// File       : sync_axi2ddr_1bit.v
//
// Description: 1 bits data sychronizer, from axi clock domain to ddr clock domain
//
// Version    : 1.0
//

module sync_axi2ddr_1bit(
  input   wire           rst,
  input   wire           axi_clk,
  input   wire           ddr_clk,
  input   wire [0:0]     axi_data,
  output  wire [0:0]     ddr_data
  );

  wire [0:0]    ddr_stage1;
  wire [0:0]    ddr_stage2;

  // axi data
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      axidata_0(
        .D(axi_data[0]),
        .Q(ddr_stage1[0]),
        .CE(1'b1),
        .C(axi_clk),
        .CLR(rst)
        );

  // ddr stage1
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      ddrdata1_0(
        .D(ddr_stage1[0]),
        .Q(ddr_stage2[0]),
        .CE(1'b1),
        .C(ddr_clk),
        .CLR(rst)
        );
  // ddr stage2
  (* DONT_TOUCH="yes" *)FDCE #(.INIT(1'b0))
      ddrdata2_0(
        .D(ddr_stage2[0]),
        .Q(ddr_data[0]),
        .CE(1'b1),
        .C(ddr_clk),
        .CLR(rst)
        );

endmodule
