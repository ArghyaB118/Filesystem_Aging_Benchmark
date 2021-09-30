import random
import sys
import shutil
import os

## args: number of offsets, file name

if __name__ == "__main__":
    # ensure we always use the same numbers
    # on repeated runs
    random.seed(42)

    total_nums = int(sys.argv[1])

    disk = sys.argv[2]
    #res = shutil.disk_usage(disk)
    fd = os.open(disk, os.O_RDONLY)
    end = os.lseek(fd, 0, os.SEEK_END)
    print(end)
    # res is a named tuple with:
    # with the attributes total, used and free, which are the amount of total, used and free space, in bytes

    # make sure we don't choose an offset that causes our read to exceed the disk
    max_num = end - (256*1024*1024)

    #print("disk {}, size {}".format(disk, end))

    a=random.sample(range(max_num), total_nums)
    for x in a :
        print("{} ,".format(x))

