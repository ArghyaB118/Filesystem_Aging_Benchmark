#!/bin/bash

set -e
set -x
IO_SIZE=4096
RESULTS_FILE="output"
rm -f /tmp/${RESULTS_FILE}.csv

for i in {1..10} 
do
	echo "$i=================================="	
	#########################################
	# Provide the target file as argument ! #
	#########################################
	if [ "$#" -ne 1 ] ; then
	    echo "Need target file as an argument!"
	    exit 1
	fi


	############################
	# Target file must exist ! #
	############################

	FILE_NAME=$1

	if [ ! -e $FILE_NAME ]; then
	    echo "no target file... exiting"
	    exit 2 # ENOENT
	fi

	## Get the target file's underlying block device
	#DEV=$(df $1 | sed '2!d' | awk '{print $1}')
        DEV=$FILE_NAME
	## Get file size for a fair comparison when reading from the block device
	FILE_SIZE=$(stat -c%s "$FILE_NAME")
	BLOCK_COUNT=$((($FILE_SIZE+$IO_SIZE-1)/$IO_SIZE))

	function drop_vm_caches {
	    sync
	    echo 3 > /proc/sys/vm/drop_caches # 1 frees pagecache
					      # 2 frees dentries and inodes
					      # 3 all
	    echo 0 > /proc/sys/vm/vfs_cache_pressure
	    DISK=/dev/sda1
	    blockdev --flushbufs $DISK
            hdparm -F $DISK >> /dev/null 2>&1
	    sleep 1
	    sync
	}

	function run {
	    fname=$1
	    iosize=$2
	    count=$3
	    outfile=$4
	    dd if=$fname of=/dev/null bs=$iosize conv=sparse count=$count >> /tmp/${outfile}.csv 2>&1
            #time (cp --sparse=never $fname  /dev/null) >> /tmp/${outfile}.csv 2>&1 
	    #SIZE=`tail -n 1 /tmp/${outfile}.csv  | awk '{print $1}'`
	    #SPARSE_SIZE=ls $fname -lsh | sed '2!d' | awk '{print $1}'
	    WHOLE_SIZE=`du -h --apparent-size $fname | awk '{print $1}'`
	    SPARSE_SIZE=`du -h $fname | awk '{print $1}'` 
	    SEC=`tail -n 1 /tmp/${outfile}.csv  | awk '{print $6 " " $7}'`
	    THRU=`tail -n 1 /tmp/${outfile}.csv  | awk '{print $8 " " $9}'`
	    SIZE_MB=`echo "scale=6; $SIZE/1000000" | bc -l`
	    HOST=`hostname`
	    echo "$HOST, read.seq.dd.sparse, $fname, $WHOLE_SIZE, $SPARSE_SIZE, $SEC, $THRU" >>  ${outfile}.csv
	    dd if=$fname of=/dev/null bs=$iosize count=$count >> /tmp/${outfile}.csv 2>&1
	    SEC=`tail -n 1 /tmp/${outfile}.csv | awk '{print $6 " " $7}'`
	    THRU=`tail -n 1 /tmp/${outfile}.csv | awk '{print $8 " " $9}'`
	    echo "$HOST, read.seq.dd.non.sparse, $fname, $WHOLE_SIZE, $SPARSE_SIZE, $SEC, $THRU" >> ${outfile}.csv
	    #time (cp --sparse=never $fname /dev/null) >> /tmp/${outfile}.csv 2>&1
	    #SEC=`tail -n 3 /tmp/output.csv | awk 'FNR == 1 {print $2}'`
	    #echo "$HOST, read.seq.cp.non.sparse, $fname, $WHOLE_SIZE, $SPARSE_SIZE, $SEC" >> ${outfile}.csv
	    #time (cp --sparse=always $fname /dev/null) >> /tmp/${outfile}.csv 2>&1
	    #SEC=`tail -n 3 /tmp/output.csv | awk 'FNR == 1 {print $2}'`
	    #echo "$HOST, read.seq.cp.sparse, $fname, $WHOLE_SIZE, $SPARSE_SIZE, $SEC" >> ${outfile}.csv
	}
	
	echo "before dropping cache" >> ${RESULTS_FILE}.csv
	run $FILE_NAME $IO_SIZE $BLOCK_COUNT $RESULTS_FILE
	drop_vm_caches
	drop_vm_caches
	drop_vm_caches
	echo "after dropping cache" >> ${RESULTS_FILE}.csv
	run $DEV $IO_SIZE $BLOCK_COUNT $RESULTS_FILE

done

