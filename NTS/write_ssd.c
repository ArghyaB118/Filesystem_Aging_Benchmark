#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>

off_t address[]= {
#include "my_num.log"
};
#define SEG_SIZE 262144
char dev_name[]="/dev/sdb3";
int num=1000;

int main()
{
    int i=0;
    char buf[SEG_SIZE]={0};
    int ret;	

    int fd=open(dev_name, O_WRONLY, 0);
    if (fd==-1) {
        printf("Can not open the file\n");
        return -1;
    }

    for (i=0;i<num;i++) { 
	ret=pwrite(fd, buf, SEG_SIZE, address[i]*SEG_SIZE);

	if(ret!=SEG_SIZE) {
	   printf("ret: %d\n", ret);
           perror("error");
           return -1;
        }
    }

    fsync(fd);
    close(fd);
    printf("Done\n");
    return 0;
}
