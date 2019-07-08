#!/bin/bash

# generate bottom and param data for testbench

vcs -full64 -severilog -Mupdate -debug_all +nospecify \
    +incdir+opt/synopsys/dc/dw/sim_ver \
    +incdir+../ \
    ../gen.param.tb.v
