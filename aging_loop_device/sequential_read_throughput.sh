#!/bin/bash

set -x
IO_SIZE=4096
RESULTS_FILE="output"
rm -f /tmp/${RESULTS_FILE}.csv

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
DEV=$(df $1 | sed '2!d' | awk '{print $1}') | echo $DEV
#DEV=$FILE_NAME
## Get file size for a fair comparison when reading from the block device
FILE_SIZE=$(stat -c%s "$FILE_NAME")
BLOCK_COUNT=$((($FILE_SIZE+$IO_SIZE-1)/$IO_SIZE))

function drop_vm_caches {
    sync
    echo 3 > /proc/sys/vm/drop_caches # 1 frees pagecache # 2 frees dentries and inodes # 3 all
    echo 0 > /proc/sys/vm/vfs_cache_pressure
    DISK=/dev/sdb1
    blockdev --flushbufs $DISK
    hdparm -F $DISK >> /dev/null 2>&1
    sleep 1
    sync

    umount mnt
    mount -t ext4 /dev/sdb1 mnt 
}

function run {
    fname=$1
    iosize=$2
    count=$3
    outfile=$4
    #dd if=$fname of=/dev/null bs=$iosize conv=sparse count=$count >> /tmp/${outfile}.csv 2>&1
    WHOLE_SIZE=`du -h --apparent-size $fname | awk '{print $1}'`
    #SPARSE_SIZE=`du -h $fname | awk '{print $1}'` 
    #SEC=`tail -n 1 /tmp/${outfile}.csv  | awk '{print $6 " " $7}'`
    #THRU=`tail -n 1 /tmp/${outfile}.csv  | awk '{print $8 " " $9}'`
    HOST=`hostname`
    #echo "$HOST, read.seq.dd.sparse, $fname, $WHOLE_SIZE, $SPARSE_SIZE, $SEC, $THRU" >>  ${outfile}.csv
    dd if=$fname of=/dev/null bs=$iosize count=$count >> /tmp/${outfile}.csv 2>&1
    SEC=`tail -n 1 /tmp/${outfile}.csv | awk '{print $6 " " $7}'`
    THRU=`tail -n 1 /tmp/${outfile}.csv | awk '{print $8 " " $9}'`
    echo "$HOST, read.seq.dd.non.sparse, $fname, $WHOLE_SIZE, $SEC $THRU" >> ${outfile}.csv
}

echo "before dropping cache" >> ${RESULTS_FILE}.csv
run $FILE_NAME $IO_SIZE $BLOCK_COUNT $RESULTS_FILE
drop_vm_caches
drop_vm_caches
drop_vm_caches
echo "after dropping cache" >> ${RESULTS_FILE}.csv
#run $DEV $IO_SIZE $BLOCK_COUNT $RESULTS_FILE
run $FILE_NAME $IO_SIZE $BLOCK_COUNT $RESULTS_FILE

