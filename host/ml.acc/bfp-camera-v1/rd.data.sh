#!/bin/bash
./load_driver.sh
./run_test.data.sh data/16.bit.conv5_3.bottom.txt 131072 2147483648
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 1610612736
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 536870912
#./run_test.data.sh data/16.bit.conv5_3.bottom.txt 262144 1073741824
#./run_test.data.sh data/16.bit.conv.all.param.txt 32768 0
#./run_test.data.sh data/16.bit.conv.all.param.txt 8192 0
