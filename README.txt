# Project_Benchmarking
#to set up kvm in ubuntu: https://github.com/oscarlab/betrfs-private/wiki/Sample-Testing-Environment
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
