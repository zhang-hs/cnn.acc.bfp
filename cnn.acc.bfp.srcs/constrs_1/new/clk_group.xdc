set_clock_groups -name async_axi_ddr_clks -asynchronous -group [get_clocks -include_generated_clocks clk_pll_i] -group [get_clocks -include_generated_clocks clk_125mhz]

