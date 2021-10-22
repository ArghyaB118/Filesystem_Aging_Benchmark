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


##How to check the system parameters
```bash
uname -r #kernel version
sudo modinfo zfs | grep version #zfs version
lscpu #CPU config
cat /proc/cpuinfo
sudo hdparm -Tt /dev/sdb #tells the buffered read speed of the hdd and ssd
```


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
https://github.com/Gui110tine/git-full-disk/blob/master/grep_f2fs.sh
https://github.com/Gui110tine/Full-Disk-Testing
required files: git_benchmark.py && grep_test.sh
1. lsblk [we need something like two block devices both of which are comparatively large]
2. cat /sys/block/sda/queue/rotational [check which one is SSD and which one is HDD]
3. [I've a HDD of 500 GiB as /dev/sdb so let's create /dev/sdb1 and /dev/sdb2, both 125 GiB]
	a. #https://www.codingame.com/playgrounds/2135/linux-filesystems-101---block-devices/partitioning-block-devices
	b. sudo fdisk -l /dev/sdb [to see the number of sectors, start and end]
	c. sudo fdisk /dev/sdb [initiate fdisk]
	d. p,n [use the start and end as 25% and press enter]
4. sudo mkfs -t ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdb1
	a. sudo mkfs.btrfs -f /dev/sdb1 [sudo mkfs.btrfs -f /dev/sdb1 -n 4096]
	b. sudo mkfs.f2fs /dev/sdb1 [sudo apt-get install f2fs-tools]
	c. sudo mkfs.xfs -f /dev/sdb1
	d1. sudo apt-get remove zfs-dkms && sudo apt-get remove spl-dkms && sudo apt-get install spl-dkms && sudo apt-get install zfs-dkms
	d2. sudo apt-get install zfsutils && sudo zpool status && whereis zfs
	d3. sudo modprobe zfs && sudo zpool create -f agedstore /dev/sdb1 && sudo zfs create -o mountpoint=/mnt/aged agedstore/files && sudo chown -R betrfs:betrfs /dev/sdb1
5. stat -f -c %T /mnt/aged
6. sudo mkfs -t ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdb2
7. sudo mount -t ext4 /dev/sdb1 /mnt/aged
8. sudo cp -r linux /mnt/aged
9. sudo mkdir /mnt/aged/linux2
10. sudo mount -t ext4 /dev/sdb2 /mnt/unaged && sudo rm -r /mnt/unaged/* && sudo umount /mnt/unaged
	a. sudo zfs mount -O datastore/files && sudo rm -r /mnt/unaged/* && sudo umount /mnt/unaged
11a. sudo python git_benchmark.py grep git_gc_off linux /mnt/aged/ output.txt 10000 100 ./grep_test.sh /mnt/aged /dev/sdb1 /mnt/unaged /dev/sdb2 ext4
11b. sudo python git_benchmark.py grep git_gc_off linux /mnt/aged/ output.txt 10000 100 ./grep_test_warm_cache.sh /mnt/aged ext4
11c. sudo python git_benchmark.py full_disk_grep git_gc_off /mnt/aged/linux /mnt/aged/linux3 /mnt/aged/linux2 output.txt 10000 100 ./grep_test_full_disk.sh /mnt/aged/linux /dev/sdb1 /mnt/aged/linux3 /dev/sdb1 /mnt/unaged /dev/sdb2 ext4
12. sudo du -sh /mnt/aged [to see size of directory, first mount]



10. sudo cp ../dummy.dev . [also, get ext4 back on /dev/sdb1]


------------ How to deal with 'betrfs' ------------
$ git clone https://github.com/oscarlab/betrfs-private.git
$ sudo add-apt-repository ppa:ubuntu-toolchain-r/test
$ sudo apt-get update
$ sudo apt-get install -y build-essential zlib1g zlib1g-dev gcc-4.7 g++-4.7 cmake valgrind cscope
$ uname -r [output: 3.11.10-ftfs]
$ vim betrfs-private/ftfs/.mkinclude [KDIR=3.11.10-ftfs MOD_KERN_SOURCE=$(PWD)/../linux-3.11.10]
$ vim betrfs-private/simplefs/.mkinclude [KDIR=$(shell uname -r) MOD_KERN_SOURCE=/lib/modules/$(KDIR)/build]
$ cd betrfs-private/linux-3.11.10/
$ sudo cp ../qemu-utils/kvm-config .config
$ sudo chown betrfs:betrfs include/ -R
$ sudo chown betrfs:betrfs scripts/ -R
$ sudo make oldconfig && sudo make prepare && sudo make scripts
$ nproc
$ sudo make -j 4
$ sudo make modules -j 4
$ sudo make modules_install -j 4
$ sudo make headers_install -j 4 ## setting up the symlink for /lib/modules/3.11.10/build to compile module
$ sudo make install
$ cd ..
$ mkdir build && cd build
$ cp ../qemu-utils/cmake-ft.sh .
$ sudo ./cmake-ft.sh 
$ cd ../filesystem && make
$ cd ../ftfs && make



------------ How to do the warm cache test by changing memory ------------
$ sudo vim /etc/default/grub [modify GRUB_CMDLINE_LINUX_DEFAULT and add mem=1024m]
$ sudo update-grub [reboot & then check]
$ sudo vim /proc/meminfo


------------ How to secure copy file from host to VM and vice versa ------------
$ scp betrfs@bunsen16.cs.unc.edu:/home/betrfs/microbenchmarks/zfs_ssd/zfs_ssd_rlt_results.csv .
$ scp myfile.txt betrfs@bunsen16.cs.unc.edu:/home/betrfs


------------
$ ls /lib/modules/$(uname -r)/ -la
$ sudo ln -sf /home/betrfs/betrfs-private/linux-3.11.10 /lib/modules/3.11.10-ftfs/build
$ sudo ln -sf /home/betrfs/betrfs-private/linux-3.11.10 /lib/modules/3.11.10-ftfs/source


Q. How to do the intrafile experiment random linux test (rlt)?
1. git clone linux repo
2. run 'listoffiles.py', it will get the files in random order in 'listoffiles.txt'
3. cp listoffiles.txt randomfilelist.txt
------------ How to deal with f2fs ------------
Impose f2fs on the disks once before the experiment using '-f' flag
------------ to delete lines with the word 'this' from 'myfile.txt'------------
$ sed -i '/this/d' myfile.txt
------------ How to deal with bad boy 'zfs' ------------
#https://blog.iqonda.net/ubuntu-on-a-zfs-root-file-system-for-ubuntu-14-04/
sudo -i
apt-add-repository --yes ppa:zfs-native/stable
apt-get update
apt-get install debootstrap ubuntu-zfs
modprobe zfs

Download zfs and spl packages as tar file
scp them to whereever you need
tar -xvf spl-***.tar
tar -xvf zfs-***.tar
cd spl-***
./configure
sudo apt-get install zfsutils-linux
whereis linux
sudo modprobe zfs
sudo zpool create new-pool /dev/sdb
sudo zpool status
sudo zpool destroy new-pool
Every time before using zfs, destroy the zpool, and get ext4 on that block device


------------ How to switch off look-ahead in ssd ------------
$ sudo hdparm -A 0 /dev/sdc1

------------ How to check if ssd or hdd ------------
$ cat /sys/block/sda/queue/rotational