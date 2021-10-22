import random
import sys
import shutil
import os

## args: number of offsets, file name

if __name__ == "__main__":
    # ensure we always use the same numbers
    # on repeated runs
    random.seed(0)

    total_nums = int(sys.argv[1])

    disk = sys.argv[2]
    #res = shutil.disk_usage(disk)
    fd = os.open(disk, os.O_RDONLY)
    start = os.lseek(fd, 0, os.SEEK_SET)
    end = os.lseek(fd, 0, os.SEEK_END)
    #print(start, end)
    # res is a named tuple with:
    # with the attributes total, used and free, which are the amount of total, used and free space, in bytes

    # make sure we don't choose an offset that causes our read to exceed the disk
    max_num = end - (20*1024*1024*1024)

    #print("disk {}, size {}".format(disk, end))
    for i in range(total_nums):
        print("{} ,".format(random.randint(start,max_num)))			

