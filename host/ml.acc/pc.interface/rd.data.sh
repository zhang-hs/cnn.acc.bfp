#!/bin/bash
./load_driver.sh

# Batch
#./run_test.data.sh data/fc8.output.batch64.fp32.bin 131072 2147483648
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 1610612736
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 536870912
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 1073741824
#./run_test.data.sh data/16.bit.conv.all.param.txt 32768 0
#./run_test.data.sh data/16.bit.conv.all.param.txt 8192 0

# Single
./run_test.data.sh data/16.bit.conv5_3.bottom.txt 8192 2147483648
