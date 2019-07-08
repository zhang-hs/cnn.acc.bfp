###############################################################################
# xdma User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

set_false_path -from [get_ports sys_rst_n]

###############################################################################
# Pinout and Related I/O Constraints
###############################################################################
set_property PACKAGE_PIN AV35 [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

set_property LOC IBUFDS_GTE2_X1Y11 [get_cells refclk_ibuf]
set_property PACKAGE_PIN AM39 [get_ports led_0]
set_property PACKAGE_PIN AN39 [get_ports led_1]
set_property PACKAGE_PIN AR37 [get_ports led_2]
set_property PACKAGE_PIN AT37 [get_ports led_3]

set_property IOSTANDARD LVCMOS18 [get_ports led_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_1]
set_property IOSTANDARD LVCMOS18 [get_ports led_2]
set_property IOSTANDARD LVCMOS18 [get_ports led_3]

set_false_path -to [get_ports -filter NAME=~led_*]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

