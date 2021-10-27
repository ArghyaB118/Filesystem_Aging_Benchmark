#!/bin/bash
################################################################################
# grep_test_warm_cache.sh
################################################################################
# performs aged and unaged grep tests on ext4
#
# usage:
# ./grep_test.sh path_to_aged aged_blk_device path_to_unaged unaged_blk_device file_system
################################################################################

AGED_PATH=$1
FS_TYPE=$2

case $FS_TYPE in
	ext4)
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		echo "$SIZE $AGED"
		;;
	btrfs)
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		echo "$SIZE $AGED"
		;;
	xfs)
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		echo "$SIZE $AGED"
		;;
	zfs)
		AGED="$(TIMEFORMAT='%3R'; time (grep -r "t26EdaovJD" $AGED_PATH) 2>&1)"
		SIZE="$(du -s $AGED_PATH | awk '{print $1}')"
		echo "$SIZE $AGED"
		;;
	*)
		echo -n "unknown fs type"
		;;
esac