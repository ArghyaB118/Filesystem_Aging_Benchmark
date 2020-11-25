# Configuration file for git test

################################################################################
# General Test Configuration Parameters
# fs_var means var for filesizetest/randomdirstructure test
# rr_var means var for round robin file appendage test
# rlt_var means var for random order linux test

drive=ssd
aged_fs=ext4
clean_fs=ftfs
test_name="${aged_fs}_${drive}"
if [ $aged_fs = "ftfs" ]
then
	test_name="${aged_fs}_${drive}_aged"
fi
if [ $clean_fs = "ftfs" ]
then
	test_name="${clean_fs}_${drive}_clean"
fi
if [ $drive = "ssd" ]
then
	aged_partition="/dev/sdc3"
	clean_partition="/dev/sdc4"
	is_rotational=0
elif [ $drive = "hdd" ]
then
	aged_partition="/dev/sdb1"
	clean_partition="/dev/sdb2"
	is_rotational=1
fi

grep_random=8TCg8BVMrUz4xoaU
keep_traces=False

# Random Directory Structure Test
rfs_test=False

# File Size Test
fs_test=False
fs_directory_count=1000
fs_fs_size=128 #in MiB
let "fs_fs_size = $fs_fs_size*1024*1024"

# Round Robin Appendage Test
rr_test=False
rr_file_count=10
rr_initial_size=262144
rr_chunk_size=4096
rr_rounds=100

# Random Linux test
rlt_test=True

################################################################################
# System Parameters

user=betrfs:betrfs

################################################################################
# Profiles
# set mntpnt to '' to disable in the test

case "$profile" in
	aged)
		partition=$aged_partition
		mntpnt=/mnt/research
		fs_type=$aged_fs
		# zfs only
		datastore=agedstore 
		;;

	clean)
		partition=$clean_partition
		mntpnt=/mnt/clean
		fs_type=$clean_fs
		# zfs only
		datastore=cleanstore
		;;

	cleaner)
		partition=/dev/sdb3
		mntpnt=''
		fs_type=ext4
		# zfs only
		datastore=cleanerstore
		;;

	*)
		echo "Unknown profile $profile"
		exit 1
		;;
esac
	
################################################################################
# betrfs Specific Parameters
# --since only one betrfs filesystem can be mounted at a time, these need not be
# --duplicated as above

dummy_file=/home/betrfs/betrfs-private/benchmarks/dummy.dev
dummy_dev=/dev/loop0
module=/home/betrfs/betrfs-private/filesystem/ftfs.ko
circle_size=128
