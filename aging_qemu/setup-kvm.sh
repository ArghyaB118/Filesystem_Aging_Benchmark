#!/bin/bash
set -ex
cd ~/betrfs-private
cd 'linux-3.11.10'
lsmod | grep kvm 
num_proc=$(nproc)
make -j $num_proc
make modules_install headers_install
make install
