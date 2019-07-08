//
// File       : sync_ddr2axi_nbit.v
//
// Description: n bits data sychronizer, from ddr clock domain to axi clock domain
//
// Version    : 1.0
//

module sync_ddr2axi_nbit#(
      parameter WIDTH = 4
      )(
  input   wire                 rst,
  input   wire                 axi_clk,
  input   wire                 ddr_clk,
  input   wire [WIDTH-1:0]     ddr_data,
  output  wire [WIDTH-1:0]     axi_data
  );

  genvar i;

  generate
    for( i=0; i<WIDTH; i=i+1) begin
      sync_ddr2axi_1bit sync_ddr2axi_bits(
        .rst(rst),
        .axi_clk(axi_clk),
        .ddr_clk(ddr_clk),
        .ddr_data(ddr_data[i]),
        .axi_data(axi_data[i])
      );
    end
  endgenerate

endmodule
