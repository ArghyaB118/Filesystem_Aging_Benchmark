#!/bin/bash
set -ex
#"mntpnt=mnt" and "vm_mnt=$mntpnt/vm_mnt", "loop_dev=/dev/loop1" and "sb_dev=/dev/sdb" for read script
#these are coming from fs-info.sh
#files reqd: aging_experiment_final.sh, copy_sparse.c, git_benchmark.py, sequential_read_thoughput.sh
#to see size of copied directory: sudo du -sh mnt/vm_mnt/root/linux
#to see mounts: df -h
#to see loop mounts: sudo losetup --show -f linuxdisk.raw 
. "/home/betrfs/betrfs-private/benchmarks/fs-info.sh"

mntpnt=mnt
vm_mnt=$mntpnt/vm_mnt
loop_dev=/dev/loop0
sb_dev=/dev/sdb1

if [ $# -ne 2 ]
then
    echo "Usage: sudo ./aging host_fstype vm_fstype"
    exit
fi

declare -a packages=("qemu-utils" "qemu-kvm" "debootstrap" "qemu-system-x86" "libvirt-bin" "virtinst" "bridge-utils" "cpu-checker") 
for i in "${packages[@]}"
do
 PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$i"|grep "install ok installed") && echo $PKG_OK
 if [ "$PKG_OK" != "install ok installed" ]; then
 	sudo apt-get --force-yes install "$i"
 fi
done

if [ ! -d "linux" ]; then
        git clone https://github.com/torvalds/linux.git
fi
if [ -d $mntpnt ]; then
	rm -rf $mntpnt
	mkdir $mntpnt
fi
#[ ! -f "./git_benchmark.py" ] && wget https://raw.githubusercontent.com/aineshbakshi/Git-Benchmark/master/git_benchmark.py
[ -d $mntpnt ] && rm -rf $mntpnt && mkdir -p $mntpnt
if [ "$1" == "ext4" ]; then
    mkfs -t ext4 -F -E lazy_itable_init=0,lazy_journal_init=0 $sb_dev &&
    mount -t ext4 $sb_dev $mntpnt &&
    chown -R $user_owner $mntpnt
elif [ "$1" == "btrfs" ]; then
    mkfs.btrfs -f $sb_dev &&
    mount -t btrfs $sb_dev $mntpnt &&
    chown -R $user_owner $mntpnt
elif [ "$1" == "xfs" ]; then
    mkfs.xfs -f $sb_dev &&
    mount -t xfs $sb_dev $mntpnt &&
    chown -R $user_owner $mntpnt
elif [ "$1" == "f2fs" ]; then
    mkfs.f2fs $sb_dev &&
    mount -t f2fs $sb_dev $mntpnt &&
    chown -R $user_owner $mntpnt
elif [ "$1" == "betrfs" ]; then
    /home/betrfs/betrfs-private/benchmarks/setup-ftfs.sh
fi
rm output.csv && touch output.csv
#[ ! -e "copy_sparse" ] && gcc copy_sparse.c -o copy_sparse
#creating the disk that is to be mounted
diskName="linuxdisk.raw"
[ -e $diskName ] && rm -rf $diskName
mkdir -p $vm_mnt
truncate -s 15g $diskName
chmod 777 $diskName
#creating the loop device
losetup $loop_dev $diskName
if [ "$2" == "ext4" ]; then
    mkfs.ext4 -F $loop_dev
elif [ "$2" == "btrfs" ]; then
    mkfs.btrfs -f $loop_dev
elif [ "$2" == "xfs" ]; then
    mkfs.xfs -f $loop_dev
elif [ "$2" == "f2fs" ]; then
    mkfs.f2fs $loop_dev
fi
mount $loop_dev -o loop $vm_mnt
mkdir -p ${vm_mnt}/root/
cp -R linux ${vm_mnt}/root/
touch ${vm_mnt}/root/out
umount $vm_mnt
losetup -d $loop_dev
./sequential_read_throughput.sh $diskName
for i in {1..10}
do
num_of_pulls=$(($i*500))
losetup $loop_dev $diskName
if [ "$2" == "ext4" ]; then
    mkfs.ext4 -F $loop_dev
elif [ "$2" == "btrfs" ]; then
    mkfs.btrfs -f $loop_dev
elif [ "$2" == "xfs" ]; then
    mkfs.xfs -f $loop_dev
elif [ "$2" == "f2fs" ]; then
    mkfs.f2fs $loop_dev
fi
mount $loop_dev -o loop $vm_mnt
mkdir -p ${vm_mnt}/root/
cp -R linux ${vm_mnt}/root/
touch ${vm_mnt}/root/out
[ -d "${vm_mnt}/root/linux2" ] && rm -r ${vm_mnt}/root/linux2
python git_benchmark.py grep git_gc_off ${vm_mnt}/root/linux ${vm_mnt}/root/linux2 ${vm_mnt}/root/linux3 ${vm_mnt}/root/out $num_of_pulls $num_of_pulls df -h
umount $vm_mnt
losetup -d $loop_dev
./sequential_read_throughput.sh $diskName
done