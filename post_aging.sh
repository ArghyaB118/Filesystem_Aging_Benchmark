#!/bin/bash
sudo mv ./disks/linuxdisk_unaged.raw ./disks/linuxdisk_aged.raw
sudo ./compare-large-file-throughput.sh ./disks/linuxdisk_aged.raw 
