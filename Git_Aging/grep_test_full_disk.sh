#!/bin/bash
################################################################################
# grep_ext4.sh
################################################################################
# performs aged and unaged grep tests on ext4
#
# usage:
# ./grep_test_full_disk.sh path_to_full_aged full_aged_blk_device path_to_unfull_aged 
#				unfull_aged_blk_device path_to_unaged unaged_blk_device file_system
################################################################################

FULL_PATH=$1
FULL_BLKDEV=$2
UNFULL_PATH=$3
UNFULL_BLKDEV=$4
CLEAN_PATH=$5
CLEAN_BLKDEV=$6
FS_TYPE=$7

case $FS_TYPE in
	ext4)
		# remount aged and time a recursive grep
		umount $FULL_PATH &>> log.txt
		mount -t ext4 $FULL_BLKDEV $FULL_PATH &>> log.txt
		FULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $FULL_PATH) 2>&1)"
		SIZE="$(du -s $FULL_PATH | awk '{print $1}')"

		umount $UNFULL_PATH &>> log.txt
		mount -t ext4 $UNFULL_BLKDEV $UNFULL_PATH
		UNFULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNFULL_PATH) 2>&1)"
		SIZE2="$(du -s $UNFULL_PATH | awk '{print $1}')"

		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.ext4 -q -F $CLEAN_BLKDEV &>> log.txt
		mount -t ext4 $CLEAN_BLKDEV $CLEAN_PATH &>> log.txt
		cp -a $FULL_PATH/* $CLEAN_PATH/.
		umount $CLEAN_PATH &>> log.txt
		mount -t ext4 $CLEAN_BLKDEV $CLEAN_PATH
		CLEAN="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $CLEAN_PATH) 2>&1)"
		umount $CLEAN_PATH &>> log.txt

		# return the size and times
		echo "$SIZE $FULL $SIZE2 $UNFULL $CLEAN"
		;;
	btrfs)
		# remount aged and time a recursive grep
		umount $FULL_PATH &>> log.txt
		mount -t btrfs $FULL_BLKDEV $FULL_PATH &>> log.txt
		FULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $FULL_PATH) 2>&1)"
		SIZE="$(du -s $FULL_PATH | awk '{print $1}')"

		umount $UNFULL_PATH &>> log.txt
		mount -t btrfs $UNFULL_BLKDEV $UNFULL_PATH
		UNFULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNFULL_PATH) 2>&1)"
		SIZE2="$(du -s $UNFULL_PATH | awk '{print $1}')"

		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.btrfs -f $CLEAN_BLKDEV &>> log.txt
		mount -t btrfs $CLEAN_BLKDEV $CLEAN_PATH &>> log.txt
		cp -a $FULL_PATH/* $CLEAN_PATH/.
		umount $CLEAN_PATH &>> log.txt
		mount -t btrfs $CLEAN_BLKDEV $CLEAN_PATH
		CLEAN="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $CLEAN_PATH) 2>&1)"
		umount $CLEAN_PATH &>> log.txt

		# return the size and times
		echo "$SIZE $FULL $SIZE2 $UNFULL $CLEAN"
		;;

	xfs)
		# remount aged and time a recursive grep
		umount $FULL_PATH &>> log.txt
		mount -t xfs $FULL_BLKDEV $FULL_PATH &>> log.txt
		FULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $FULL_PATH) 2>&1)"
		SIZE="$(du -s $FULL_PATH | awk '{print $1}')"

		umount $UNFULL_PATH &>> log.txt
		mount -t xfs $UNFULL_BLKDEV $UNFULL_PATH
		UNFULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNFULL_PATH) 2>&1)"
		SIZE2="$(du -s $UNFULL_PATH | awk '{print $1}')"

		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.xfs -f $CLEAN_BLKDEV &>> log.txt
		mount -t xfs $CLEAN_BLKDEV $CLEAN_PATH &>> log.txt
		cp -a $FULL_PATH/* $CLEAN_PATH/.
		umount $CLEAN_PATH &>> log.txt
		mount -t xfs $CLEAN_BLKDEV $CLEAN_PATH
		CLEAN="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $CLEAN_PATH) 2>&1)"
		umount $CLEAN_PATH &>> log.txt

		# return the size and times
		echo "$SIZE $FULL $SIZE2 $UNFULL $CLEAN"
		;;
	f2fs)
		# remount aged and time a recursive grep
		umount $FULL_PATH &>> log.txt
		mount -t f2fs $FULL_BLKDEV $FULL_PATH &>> log.txt
		FULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $FULL_PATH) 2>&1)"
		SIZE="$(du -s $FULL_PATH | awk '{print $1}')"

		umount $UNFULL_PATH &>> log.txt
		mount -t f2fs $UNFULL_BLKDEV $UNFULL_PATH
		UNFULL="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNFULL_PATH) 2>&1)"
		SIZE2="$(du -s $UNFULL_PATH | awk '{print $1}')"

		# create a new f2fs filesystem, mount it, time a recursive grep and dismount it
		mkfs.f2fs $CLEAN_BLKDEV &>> log.txt
		mount -t f2fs $CLEAN_BLKDEV $CLEAN_PATH &>> log.txt
		cp -a $FULL_PATH/* $CLEAN_PATH/.
		umount $CLEAN_PATH &>> log.txt
		mount -t f2fs $CLEAN_BLKDEV $CLEAN_PATH
		CLEAN="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $CLEAN_PATH) 2>&1)"
		umount $CLEAN_PATH &>> log.txt

		# return the size and times
		echo "$SIZE $FULL $SIZE2 $UNFULL $CLEAN"
	*)
		echo -n "unknown fs type"
		;;
esac