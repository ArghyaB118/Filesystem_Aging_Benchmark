#!/bin/bash

OUTPUT_FILE="data.csv"

IO_COUNT=1000

function drop_caches() {
    for i in {0..10}
    do
	sync; echo 3 > /proc/sys/vm/drop_caches
	sleep 3
    done
}

for dev_name in "/dev/sdc" "/dev/sdb"
do
    # prep the random offsets
    python3 random_num.py $IO_COUNT $dev_name > my_num.log
    
    currentdate=`date`
    echo "# $currentdate, $dev_name" >> $OUTPUT_FILE
    for exponent in {0..17}
    do 
       g++ read.c -o read_rand -lrt
       drop_caches
       ./read_rand $(((2**$exponent)*4096)) $IO_COUNT $dev_name >> $OUTPUT_FILE
    done
done
