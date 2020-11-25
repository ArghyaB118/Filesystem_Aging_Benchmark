#/bin/bash

# prints configuration to stdout

profile=aged
. "config.sh"

echo "test_name $test_name"
echo "grep_random $grep_random"
echo "keep_traces $keep_traces"

echo "rfs_test $rfs_test"

echo "fs_test $fs_test"
echo "fs_fs_size $fs_fs_size"
echo "fs_directory_count $fs_directory_count"
echo "aged $mntpnt $partition"

echo "rr_test $rr_test"
echo "rr_rounds $rr_rounds"
echo "rr_file_count $rr_file_count"
echo "rr_initial_size $rr_initial_size"
echo "rr_chunk_size $rr_chunk_size"

echo "rlt_test $rlt_test"

profile=clean
. "config.sh"
if [ ! -z "$mntpnt" ]; then
	echo "clean $mntpnt $partition"
fi

profile=cleaner
. "config.sh"
if [ ! -z "$mntpnt" ]; then
	echo "cleaner $mntpnt $partition"
fi
