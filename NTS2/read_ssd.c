#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>

off_t address[]= {
#include "my_num.log"
};
#define SEGSIZE (1024*4)
//static const int SEG_SIZE = 8*1024*1024;
char dev_name[]="/dev/sdb";
int num=1000;
bool verbose=true;

int main()
{
	if(verbose) { printf("here\n"); }
    int i=0;
    struct timespec start, end;
    double elapsed, sizeMB;
    int ret, sizeKB;
    char *buf = NULL;
	if(verbose) { printf("here\n"); }

    int fd=open(dev_name, O_RDONLY, 0);
    if (fd==-1) {
        printf("Can not open the file\n");
        return -1;
    }

    buf = malloc(SEGSIZE);
    if (buf == NULL) {
      printf("malloc failed for %d bytes\n", SEGSIZE);
      return -1;
    }
    memset(buf, 0, SEGSIZE);

	if(verbose) { printf("here\n"); }
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (i=0;i<num;i++) { 
	ret=pread(fd, buf, SEGSIZE, address[i]*SEGSIZE);
	if(ret!=SEGSIZE) {
	   printf("ret: %d\n", ret);
           perror("error");
           return -1;
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &end);

    close(fd);

    elapsed = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1000000000.0;
    sizeKB = (SEGSIZE/1024); sizeMB = SEGSIZE / 1e6;
    printf("size.KB, num, time.s, throughput.MBps\n");
    printf("%d, %d, %lf, %lf\n", sizeKB, num, elapsed, sizeMB / elapsed);
    return 0;
}

