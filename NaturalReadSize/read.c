#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>

// this array contains *absolute* byte offsets.
// you should run python3 generate_array.py <disk_size_in_bytes>
// to generate this array.
off_t address[]= {
#include "my_num.log"
};


bool verbose=false;

static void usage() {
  printf("usage: ./read_rand <segment size> <num_ios> <file name>\n");
}

int main(int argc, char **argv)
{
    int i=0;
    struct timespec start, end;
    double elapsed, bandwidth;
    int ret;
    char *buf = NULL;
    
    if (argc < 3) {
      usage();
      return -EINVAL;
    }

    int seg_size = atoi(argv[1]);
    int num_ios = atoi(argv[2]);
    char *dev_name = argv[3];

    if(verbose) {
      printf("test parameters:\n");
      printf("\tseg_size: %d\n", seg_size);
      printf("\tnum_ios: %d\n", num_ios);
      printf("\tdev_name: %s\n", dev_name);
    }
  

    int fd = open(dev_name, O_RDONLY, 0);
    if (fd == -1) {
      printf("Can not open target file %s\n", dev_name);
      return fd;
    }

    buf = (char*) malloc(seg_size);
    if (buf == NULL) {
      printf("malloc failed for %d bytes\n", seg_size);
      return -1;
    }
    memset(buf, 0, seg_size);

    // start the test
    clock_gettime(CLOCK_MONOTONIC, &start);

    for (i=0; i<num_ios; i++) { 
      ret = pread(fd, buf, seg_size, address[i]);
      if(ret != seg_size) {
        printf("short read. requested %d, read %d, offset %ld\n", seg_size, ret, address[i]);
        perror("ending test early\n");
        return -1;
      }
    }

    // end the test
    clock_gettime(CLOCK_MONOTONIC, &end);

    close(fd);
    free(buf);
    elapsed = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1000000000.0;
    bandwidth = seg_size/1024*num_ios/elapsed/1024;
    if(verbose) {
      printf("segsize, num_ios, time.s, read_bandwidth_MiBps\n");
    }
    printf("%d, %d, %lf, %lf\n", seg_size, num_ios, elapsed, bandwidth);

    return 0;
}

