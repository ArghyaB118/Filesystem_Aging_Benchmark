# Project_Benchmarking
#location:betrfs-private/benchmarks/aging_benchmarks/
#to set up kvm in ubuntu: https://github.com/oscarlab/betrfs-private/wiki/Sample-Testing-Environment
#check line 18 and 24 in q 
#check disk partition in compare-large-file-throughput.sh 
$ sudo chmod +x aging.sh
$ sudo chmod +x post_aging.sh
$ sudo ./aging.sh

#in qemu
$ root
$ sudo ./code_qemu.sh

#back in host
$ sudo ./post_aging.sh

-------------------------
#added report as submodule
#for adding submodules
$ git submodule add ghttps://git.overleaf.com/5e29e0067162cd00015723f3 doc/
$ cat .gitmodules //to check
#for submodules pull
$ git submodule update --init --recursive
#for submodules push
$ cd your_submodule
$ git checkout master
$ git commit -a -m "commit in submodule"
$ git push
-------------------------

1. lsblk [we need something like two block devices both of which are comparatively large]
2. cat /sys/block/sda/queue/rotational [check which one is SSD and which one is HDD]
3. [I've a HDD of 500 GiB as /dev/sdb so let's create /dev/sdb1 and /dev/sdb2, both 125 GiB]
	a. #https://www.codingame.com/playgrounds/2135/linux-filesystems-101---block-devices/partitioning-block-devices
	b. sudo fdisk -l /dev/sdb [to see the number of sectors, start and end]
	c. sudo fdisk /dev/sdb [initiate fdisk]
	d. p,n [use the start and end as 25% and press enter]
4. sudo mkfs -t ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdb1
	a. sudo mkfs.btrfs -f /dev/sdb1
	b. sudo mkfs.f2fs /dev/sdb1 [sudo apt-get install f2fs-tools]
	c. sudo mkfs.xfs -f /dev/sdb1
	d1. sudo apt-get remove zfs-dkms && sudo apt-get remove spl-dkms && sudo apt-get install spl-dkms && sudo apt-get install zfs-dkms
	d2. sudo apt-get install zfsutils && sudo zpool status && whereis zfs
	d3. sudo zpool create -f datastore /dev/sdb1 && sudo zfs create -o mountpoint=/mnt/aged datastore/files && sudo chown -R betrfs:betrfs /dev/sdb1
5. stat -f -c %T mnt/aged
6. sudo mkfs -t ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdb2
7. sudo mount -t ext4 /dev/sdb1 /mnt/aged
8. sudo cp -r linux /mnt/aged
9. sudo mkdir /mnt/aged/linux2
10. sudo mount -t ext4 /dev/sdb2 /mnt/unaged && sudo rm -r /mnt/unaged/* && sudo umount /mnt/unaged
	a. sudo zfs mount -O datastore/files && sudo rm -r /mnt/unaged/* && sudo umount /mnt/unaged
11. sudo python git_benchmark.py /mnt/aged/linux /mnt/aged/linux2 output.txt 10000 1000 ./grep_test.sh /mnt/aged /dev/sdb1 /mnt/unaged /dev/sdb2 ext4
12. sudo du -sh /mnt/aged [to see size of directory, first mount]


10. sudo cp ../dummy.dev . [also, get ext4 back on /dev/sdb1]


$ git clone https://github.com/oscarlab/betrfs-private.git
$ vim betrfs-private/ftfs/.mkinclude [to set kdir to 3.11.10]
$ cd betrfs-private/linux-3.11.10/
$ sudo cp ../qemu-utils/kvm-config .config
$ sudo make oldconfig && sudo make prepare
$ nproc
$ sudo make -j 4
$ sudo make modules_install headers_install
$ sudo make install
$ cd ..
$ mkdir build && cd build
$ cp ../qemu-utils/cmake-ft.sh .
$ sudo ./cmake-ft.sh 
$ cd ../filesystem && make