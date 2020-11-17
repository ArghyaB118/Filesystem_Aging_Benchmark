#!/bin/bash
################################################################################
# grep_test.sh
################################################################################
# performs aged and unaged grep tests on ext4
#
# usage:
# ./grep_test.sh path_to_aged aged_blk_device path_to_unaged unaged_blk_device file_system
################################################################################

AGED_PATH=$1
AGED_BLKDEV=$2
UNAGED_PATH=$3
UNAGED_BLKDEV=$4
FS_TYPE=$5
case $FS_TYPE in
	ext4)
		# remount aged and time a recursive grep
		umount $AGED_PATH &>> log.txt
		mount -t ext4 $AGED_BLKDEV $AGED_PATH &>> log.txt
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.ext4 -f $UNAGED_BLKDEV &>> log.txt
		mount -t ext4 $UNAGED_BLKDEV $UNAGED_PATH &>> log.txt
		cp -a $AGED_PATH/* $UNAGED_PATH
		umount $UNAGED_PATH &>> log.txt
		mount -t ext4 $UNAGED_BLKDEV $UNAGED_PATH
		UNAGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNAGED_PATH) 2>&1)"
		umount $UNAGED_PATH &>> log.txt
		# return the size and times
		echo "$SIZE $AGED $UNAGED"
		;;
	f2fs)
		# remount aged and time a recursive grep
		umount $AGED_PATH &>> log.txt
		mount -t f2fs $AGED_BLKDEV $AGED_PATH &>> log.txt
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.f2fs -f $UNAGED_BLKDEV &>> log.txt
		mount -t f2fs $UNAGED_BLKDEV $UNAGED_PATH &>> log.txt
		cp -a $AGED_PATH/* $UNAGED_PATH
		umount $UNAGED_PATH &>> log.txt
		mount -t f2fs $UNAGED_BLKDEV $UNAGED_PATH
		UNAGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNAGED_PATH) 2>&1)"
		umount $UNAGED_PATH &>> log.txt
		# return the size and times
		echo "$SIZE $AGED $UNAGED"
		;;
	btrfs)
		# remount aged and time a recursive grep
		umount $AGED_PATH &>> log.txt
		mount -t btrfs $AGED_BLKDEV $AGED_PATH &>> log.txt
		BLOCKSWRITTEN="$((iostat -d $AGED_BLKDEV | sed '$d' | tail -1 | tail -c 12) 2>&1)"
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		BLOCKSWRITTEN2="$((iostat -d $AGED_BLKDEV | sed '$d' | tail -1 | tail -c 12) 2>&1)"
		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.btrfs -f $UNAGED_BLKDEV &>> log.txt
		mount -t btrfs $UNAGED_BLKDEV $UNAGED_PATH &>> log.txt
		cp -a $AGED_PATH/* $UNAGED_PATH
		umount $UNAGED_PATH &>> log.txt
		mount -t btrfs $UNAGED_BLKDEV $UNAGED_PATH
		UNAGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNAGED_PATH) 2>&1)"
		umount $UNAGED_PATH &>> log.txt
		# return the size and times
		echo "$SIZE $AGED $UNAGED $BLOCKSWRITTEN $BLOCKSWRITTEN2"
		;;
	xfs)
		# remount aged and time a recursive grep
		umount $AGED_PATH &>> log.txt
		mount -t xfs $AGED_BLKDEV $AGED_PATH &>> log.txt
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		mkfs.xfs -f $UNAGED_BLKDEV &>> log.txt
		mount -t xfs $UNAGED_BLKDEV $UNAGED_PATH &>> log.txt
		cp -a $AGED_PATH/* $UNAGED_PATH
		umount $UNAGED_PATH &>> log.txt
		mount -t xfs $UNAGED_BLKDEV $UNAGED_PATH
		UNAGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNAGED_PATH) 2>&1)"
		umount $UNAGED_PATH &>> log.txt
		# return the size and times
		echo "$SIZE $AGED $UNAGED"
		;;
	zfs)
		# remount aged and time a recursive grep
		zfs umount $AGED_PATH &>> log.txt
		zpool export agedstore
		zpool import agedstore
		zfs mount -a
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		# create a new ext4 filesystem, mount it, time a recursive grep and dismount it
		modprobe zfs
		zpool create -f cleanstore $UNAGED_BLKDEV
		zfs create -o mountpoint=$UNAGED_PATH cleanstore/files
		chown -R betrfs:betrfs $UNAGED_PATH
		cp -a $AGED_PATH/* $UNAGED_PATH
		zfs umount $UNAGED_PATH &>> log.txt
		zpool export cleanstore
		zpool import cleanstore
		zfs mount -a
		UNAGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $UNAGED_PATH) 2>&1)"
		zfs umount $UNAGED_PATH &>> log.txt
		zpool destroy -f cleanstore
		# return the size and times
		echo "$SIZE $AGED $UNAGED"
		;;
	ftfs)
		# remount aged and time a recursive grep
		umount $AGED_PATH &>> log.txt
		mount -t ftfs -o max=128,sb_fstype=sfs,d_dev=/dev/loop0,is_rotational=1 $AGED_BLKDEV $AGED_PATH
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		# return the aged time
		echo "$AGED"
		;;
	*)
		echo -n "unknown fs type"
		;;
esac