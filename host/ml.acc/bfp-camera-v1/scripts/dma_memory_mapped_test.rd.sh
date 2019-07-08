#!/bin/bash

transferSize=$1
transferCount=$2
h2cChannels=$3
c2hChannels=$4
transferFileName=$5
transferOffset=$6

if [ ! -e "$transferFileName" ]; then
  echo "$transferFileName does not exist"
  exit 0
fi

testError=0
# Run the PCIe DMA memory mapped write read test
echo "Info: Running PCIe DMA memory mapped write read test"
echo "      transfer size:  $transferSize"
echo "      transfer count: $transferCount"
#
##Write to all enabled h2cChannels in parallel
#if [ $h2cChannels -gt 0 ]; then
#  # Loop over four blocks of size $transferSize and write to them (in parallel where possible)
#  for ((i=0; i<=0; i++))
#  do
#    addrOffset=$(expr $(($transferSize*$i)) + $transferOffset)
#    curChannel=$(($i % $h2cChannels))
#    echo "Info: Writing to h2c channel $curChannel at address offset $addrOffset."
#   #./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f $transferFileName -s $transferSize -a $addrOffset -c $transferCount &
#    ./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f $transferFileName -s $transferSize -a $addrOffset -c $transferCount &
#    # If all channels have active transactions we must wait for them to complete
#    if [ $(($curChannel+1)) -eq $h2cChannels ]; then
#      echo "Info: Wait for current transactions to complete."
#      wait
#    fi
#  done
#fi
#
## Wait for the last transaction to complete.
#wait

# Read from all enabled c2hChannels in parallel
if [ $c2hChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize and read from them (in parallel where possible)
  for ((i=0; i<=0; i++))
  do
   #addrOffset=$(($transferSize * $i)) + $transferOffset
    addrOffset=$(expr $(($transferSize*$i)) + $transferOffset)
    curChannel=$(($i % $c2hChannels))
    rm -f data/output_conv.bin
    echo "Info: Reading from c2h channel $curChannel at address offset $addrOffset."
    ./dma_from_device -d /dev/xdma0_c2h_${curChannel} -f data/rd.file.bin -s $transferSize -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
    if [ $(($curChannel+1)) -eq $c2hChannels ]; then
      echo "Info: Wait for the current transactions to complete."
      wait
    fi
  done
fi
 
# Wait for the last transaction to complete.
wait

# Verify that the written data matches the read data if possible.
if [ $h2cChannels -eq 0 ]; then
  echo "Info: No data verification was performed because no h2c channels are enabled."
elif [ $c2hChannels -eq 0 ]; then
  echo "Info: No data verification was performed because no c2h channels are enabled."
else
  echo "Info: Checking data integrity."
  for ((i=0; i<=0; i++))
  do
    cmp data/rd.file.bin $transferFileName -n $transferSize
    returnVal=$?
    if [ ! $returnVal == 0 ]; then
      echo "Error: The data written did not match the data that was read."
      echo "       address range:   $(($i*$transferSize)) - $((($i+1)*$transferSize))"
      echo "       write data file: $transferFileName"
      echo "       read data file:  data/rd.file.bin"
      testError=1
    else
      echo "Info: Data check passed for address range $(($i*$transferSize)) - $((($i+1)*$transferSize))."
    fi
  done
fi

# Exit with an error code if an error was found during testing
if [ $testError -eq 1 ]; then
  echo "Error: Test completed with Errors."
  exit 1
fi

# Report all tests passed and exit
echo "Info: All PCIe DMA memory mapped tests passed."
exit 0
