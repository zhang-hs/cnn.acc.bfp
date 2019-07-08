#!/bin/bash
./load_driver.sh
./run_test.sh data/param.16.bit.txt 56778752 1073741824
#./run_test.sh data/param.16.bit.txt 65536 1073741824

# Batch
#./run_test.sh data/16.bit.conv1_1.bottom.txt 25165824 0

# Single
./run_test.sh data/16.bit.conv1_1.bottom.txt 393216 0
