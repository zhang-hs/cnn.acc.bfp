#!/bin/bash
./load_driver.sh
./run_test.sh data/param_all.txt 42074112 1073741824
./run_test.sh data/exp_all.txt 8192 2684354560
./run_test_cam.sh 393216 0

