#!/bin/bash

# batch mode options
# general options
# simulatior options
# tcl debug options -verilog -2001 
#-v ../../../ip/mem64bit/sim/mem64bit.v \
#     -bb bram_top_row \
#     -bb bram_right_patch \
nLint -gui -nologo -logdir ./ -sv -2001 -sort s -readonly on -beauty \
      -bb adder_1\
      -bb adder_2 \
      -bb adder_3 \
      -bb bram_A \
      -bb bram_B \
      -bb mult2 \
      -bb of_blkmem \
      -bb conv_buf \
      -bb ip_buf_0 \
      -bb ip_buf_1 \
      -bb float_adder \
      -bb float_multiply_adder \
      -f $PWD/vgg_with_fc.f \
      -top vgg
