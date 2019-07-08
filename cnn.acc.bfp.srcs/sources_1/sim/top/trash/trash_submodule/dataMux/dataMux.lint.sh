#!/bin/bash

# batch mode options
# general options
# simulatior options
# tcl debug options -verilog -2001 
#-v ../../../ip/mem64bit/sim/mem64bit.v \
nLint -gui -nologo -logdir ./ -sv -sort s -readonly on -beauty \
      -f $PWD/dataMux/tb.dataMux.f \
      -top top
