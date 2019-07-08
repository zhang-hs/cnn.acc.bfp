//
// File       : sync_axi2ddr_nbit.v
//
// Description: n bits sychronizer, from axi clock domain to ddr clock domain
//
// Version    : 1.0
//

module sync_axi2ddr_nbit #(
      parameter WIDTH = 32
      )(
  input   wire                 rst,
  input   wire                 axi_clk,
  input   wire                 ddr_clk,
  input   wire [WIDTH-1:0]     axi_data,
  output  wire [WIDTH-1:0]     ddr_data
  );

  genvar i;

  generate
    for( i=0; i<WIDTH; i=i+1) begin
      sync_axi2ddr_1bit sync_axi2ddr_bits(
        .rst(rst),
        .axi_clk(axi_clk),
        .ddr_clk(ddr_clk),
        .axi_data(axi_data[i]),
        .ddr_data(ddr_data[i])
      );
    end
  endgenerate

endmodule
