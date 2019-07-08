#!/bin/bash

transferSize0=$1
transferSize1=$2
transferSize2=$3
transferCount=$4
h2cChannels=$5
c2hChannels=$6

testError=0
# Run the PCIe DMA memory mapped write read test
echo "Info: Running PCIe DMA memory mapped write read test"
echo "      transfer size:  $transferSize0"
echo "      transfer size:  $transferSize1"
echo "      transfer size:  $transferSize2"
echo "      transfer count: $transferCount"

 Write to all enabled h2cChannels in parallel
if [ $h2cChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize0 and write to them (in parallel where possible)
  for ((i=0; i<=0; i++))
  do
    addrOffset=$(($transferSize0*$i))
    curChannel=$(($i % $h2cChannels))
    echo "Info: Writing to h2c channel $curChannel at address offset $addrOffset."
   #./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f data/datafile${i}_4K.bin -s $transferSize -a $addrOffset -c $transferCount &
    ./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f data/conv1_1.bottom.txt -s $transferSize0 -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
    if [ $(($curChannel+1)) -eq $h2cChannels ]; then
      echo "Info: Wait for current transactions to complete."
      wait
    fi
  done
fi


#if [ $h2cChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize1 and write to them (in parallel where possible)
#  for ((i=0; i<=0; i++))
#  do
#    addrOffset=($(($transferSize1*$i)))+524288000
#    curChannel=$(($i % $h2cChannels))
#    echo "Info: Writing to h2c channel $curChannel at address offset $addrOffset."
#    ./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f data/datafile${i}_32M.bin -s $transferSize1 -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
#    if [ $(($curChannel+1)) -eq $h2cChannels ]; then
#      echo "Info: Wait for current transactions to complete."
#      wait
#    fi
#  done
#fi

if [ $h2cChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize2 and write to them (in parallel where possible)
  for ((i=0; i<=0; i++))
  do
    addrOffset=($(($transferSize2*$i)))+1048576000
    curChannel=$(($i % $h2cChannels))
    echo "Info: Writing to h2c channel $curChannel at address offset $addrOffset."
    ./dma_to_device -d /dev/xdma0_h2c_${curChannel} -f data/ip_param.bin -s $transferSize2 -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
    if [ $(($curChannel+1)) -eq $h2cChannels ]; then
      echo "Info: Wait for current transactions to complete."
      wait
    fi
  done
fi



# Wait for the last transaction to complete.
wait

 Read from all enabled c2hChannels in parallel
if [ $c2hChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize0 and read from them (in parallel where possible)
  for ((i=0; i<=0; i++))
  do
    addrOffset=$(($transferSize0 * $i))
    curChannel=$(($i % $c2hChannels))
    rm -f data/output_conv.bin
    echo "Info: Reading from c2h channel $curChannel at address offset $addrOffset."
    ./dma_from_device -d /dev/xdma0_c2h_${curChannel} -f data/output_conv.bin -s $transferSize0 -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
    if [ $(($curChannel+1)) -eq $c2hChannels ]; then
      echo "Info: Wait for the current transactions to complete."
      wait
    fi
  done
fi

#if [ $c2hChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize1 and read from them (in parallel where possible)
#  for ((i=0; i<=0; i++))
#  do
#    addrOffset=$((($transferSize1 * $i)))+524288000;
#    curChannel=$(($i % $c2hChannels))
#    rm -f data/output_data.bin
#    echo "Info: Reading from c2h channel $curChannel at address offset $addrOffset."
#    ./dma_from_device -d /dev/xdma0_c2h_${curChannel} -f data/output_data.bin -s $transferSize1 -a $addrOffset -c $transferCount &
    # If all channels have active transactions we must wait for them to complete
#    if [ $(($curChannel+1)) -eq $c2hChannels ]; then
#      echo "Info: Wait for the current transactions to complete."
#      wait
#    fi
#  done
#fi

if [ $c2hChannels -gt 0 ]; then
  # Loop over four blocks of size $transferSize2 and read from them (in parallel where possible)
  for ((i=0; i<=0; i++))
  do
    addrOffset=$((($transferSize2 * $i)))+1048576000;
    curChannel=$(($i % $c2hChannels))
    rm -f data/output_param.bin
    echo "Info: Reading from c2h channel $curChannel at address offset $addrOffset."
    ./dma_from_device -d /dev/xdma0_c2h_${curChannel} -f data/output_param.bin -s $transferSize2 -a $addrOffset -c $transferCount &
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
    cmp data/output_conv.bin data/conv1_1.bottom.txt -n $transferSize0
    returnVal=$?
    if [ ! $returnVal == 0 ]; then
      echo "Error: The data written did not match the data that was read."
      echo "       address range:   $(($i*$transferSize0)) - $((($i+1)*$transferSize0))"
      echo "       write data file: data/conv1_1.bottom.txt"
      echo "       read data file:  data/output_conv.bin"
      testError=1
    else
      echo "Info: Data check passed for address range $(($i*$transferSize0)) - $((($i+1)*$transferSize0))."
    fi
  done
fi

#if [ $h2cChannels -eq 0 ]; then
#  echo "Info: No data verification was performed because no h2c channels are enabled."
#elif [ $c2hChannels -eq 0 ]; then
#  echo "Info: No data verification was performed because no c2h channels are enabled."
#else
#  echo "Info: Checking data integrity."
#  for ((i=0; i<=0; i++))
#  do
#    cmp data/output_data.bin data/datafile${i}_32M.bin -n $transferSize1
#    returnVal=$?
#    if [ ! $returnVal == 0 ]; then
#      echo "Error: The data written did not match the data that was read."
#      echo "       address range:   $(($i*$transferSize1)) - $((($i+1)*$transferSize1))"
#      echo "       write data file: data/datafile${i}_4K.bin"
#      echo "       read data file:  data/output_data.bin"
#      testError=1
#    else
#      echo "Info: Data check passed for address range $(($i*$transferSize1)) - $((($i+1)*$transferSize1))."
#    fi
#  done
#fi

if [ $h2cChannels -eq 0 ]; then
  echo "Info: No data verification was performed because no h2c channels are enabled."
elif [ $c2hChannels -eq 0 ]; then
  echo "Info: No data verification was performed because no c2h channels are enabled."
else
  echo "Info: Checking data integrity."
  for ((i=0; i<=0; i++))
  do
    cmp data/output_param.bin data/ip_param.bin -n $transferSize2
    returnVal=$?
    if [ ! $returnVal == 0 ]; then
      echo "Error: The data written did not match the data that was read."
      echo "       address range:   $(($i*$transferSize2)) - $((($i+1)*$transferSize2))"
      echo "       write data file: data/ip_param.bin"
      echo "       read data file:  data/output_param.bin"
      testError=1
    else
      echo "Info: Data check passed for address range $(($i*$transferSize2)) - $((($i+1)*$transferSize2))."
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
