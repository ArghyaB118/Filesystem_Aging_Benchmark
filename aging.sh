#!/bin/bash
set -x
mkdir ./disks
git clone https://github.com/torvalds/linux.git
git clone https://github.com/aineshbakshi/Git-Benchmark.git
sudo ./genUbuntuDisk.sh ./disks/linuxdisk_unaged.raw 15G
sudo mount -o loop ./disks/linuxdisk_unaged.raw mnt/
#sudo vim mnt/etc/passwd
sudo sed -i 's/root:x/root:/g' mnt/etc/passwd
sudo cp -r Git-Benchmark/ ./mnt/root/
sudo cp -r linux/ ./mnt/root/
sudo chmod +x ./code_qemu.sh
sudo cp code_qemu.sh ./mnt/root/
sudo chmod +x ./mnt/root/code_qemu.sh
sudo umount mnt
sudo ./compare-large-file-throughput.sh ./disks/linuxdisk_unaged.raw 
sudo ./q
