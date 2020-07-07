#!/bin/bash
set -x
declare -a packages=("qemu-utils" "qemu-kvm" "debootstrap" "qemu-system-x86" "libvirt-bin" "virtinst" "bridge-utils" "cpu-checker") 
for i in "${packages[@]}"
do
 PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$i"|grep "install ok installed") && echo $PKG_OK
 if [ "$PKG_OK" != "install ok installed" ]; then
        sudo apt-get --force-yes install "$i"
 fi
done

[ ! -d "./disks" ] && mkdir ./disks
if [ ! -d "linux" ]; then
        git clone https://github.com/torvalds/linux.git
fi
[ ! -d "./mnt" ] && mkdir ./mnt
[ ! -e "./disks/linuxdisk_unaged.raw" ] && sudo ./genUbuntuDisk.sh ./disks/linuxdisk_unaged.raw 15G 
mount -o loop ./disks/linuxdisk_unaged.raw mnt/
sed -i 's/root:x/root:/g' mnt/etc/passwd
cp git_benchmark.py ./mnt/root/
cp -r linux/ ./mnt/root/
chmod +x ./code_qemu.sh
cp code_qemu.sh ./mnt/root/
chmod +x ./mnt/root/code_qemu.sh
umount mnt 
./compare-large-file-throughput.sh ./disks/linuxdisk_unaged.raw
./q
