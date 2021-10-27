#define _GNU_SOURCE

#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#include <inttypes.h>



#define BLOCK_SIZE 4096
static char BLOCK[BLOCK_SIZE];

/**
 * This test copies one file to another in a way that should preserve
 * the "sparseness" of the source file.
 * 
 * Stat the source, see its size.
 * Truncate the destination to the target size (creating a sparse file)
 * Use lseek with SEEK_HOLE/SEEK_DATA to find the offset of consecutive
 *     holes (sparse regions) and data (non-sparse) regions.
 *     The man page explicitly says applications can't depend on this to
 *     find "all such ranges in a file", but we are going to anyway.
 * Pwrite all data from the source to the first hole.
 */

off_t get_file_size(int fd) {
  return lseek(fd, 0, SEEK_END);
}

// copies one data region from the source to the dest
// returns 0 on success
off_t copy_one_data_region(int src_fd, off_t data_start, size_t bytes,
			   int dst_fd) {
	off_t current = data_start;
	while (bytes > 0) {
	//ssize_t
	//pwrite(int fildes, const void *buf, size_t nbyte, off_t offset);
	//pread(int d, void *buf, size_t nbyte, off_t offset);
		ssize_t read_bytes =
			pread(src_fd, BLOCK, BLOCK_SIZE, current);
		assert(read_bytes > 0);
		ssize_t write_bytes =
			pwrite(dst_fd, BLOCK, read_bytes, current);
		assert(write_bytes > 0);
		current += write_bytes;
		bytes -= write_bytes;
	}
	return 0;
}

uint64_t copy_sparse(int src_fd, int dst_fd, off_t src_size) {
	off_t data_start;
	off_t hole_start;
	uint64_t data_regions_copied = 0;
	
	if (src_size == 0)
		return 0;


	// get start of first data region in the file
	data_start = lseek(src_fd, 0, SEEK_DATA);
	if (data_start < 0) {
		// no data in file?
		if (errno == ENXIO)
			return 0;
		perror("error finding first data region");
		exit(-errno);
	}
	
	// while there are still more holes in the file
	do {
		// get start of next hole in the file
		// (i.e., the end of the current data region)
		hole_start = lseek(src_fd, 0, SEEK_HOLE);

		copy_one_data_region(src_fd, // src
				     data_start, // data start
				     hole_start - data_start, // n_bytes
				     dst_fd); // dst
		data_regions_copied++;

		// look for next data region, starting at last hole
		data_start = lseek(src_fd, hole_start, SEEK_DATA);
		if (data_start < 0 && errno == ENXIO)
			return data_regions_copied;

		// have not yet thought how to recover from other errors
		assert(data_start > 0);
	} while(data_start > 0);
	
	return data_regions_copied;
}

void usage() {
  printf("./copy_sparse src_path dst_path\n");
  printf("\tfor safety, we exit if file at dst_path exists\n");
}

int main(int argc, char **argv) {
  char *src_path;
  char *dst_path;
  int src_fd;
  int dst_fd;

  off_t file_size;
  
  
  
  if (argc < 3) {
    usage();
    return -EINVAL;
  }

  src_path = argv[1];
  dst_path = argv[2];

  
  if (access(dst_path, F_OK) == 0) {
    printf("file %s exists already. exiting\n", dst_path);
    return -EEXIST;
  }
  
  src_fd = open(src_path, O_RDONLY);
  assert(src_fd > 0);

  dst_fd = open(dst_path, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR);
  assert(dst_fd > 0);

  file_size = get_file_size(src_fd);
  if (file_size == 0) {
	  printf("file %s is empty", src_path);
	  return 0;
  } else {
	  // truncate destionation file to create appropriately sized
	  // sparse file
	  int ret = ftruncate(dst_fd, file_size);
	  assert(ret == 0);
  }

  uint64_t blocks_copied = copy_sparse(src_fd, dst_fd, file_size);

  printf("Successfully copied %"PRIu64" blocks!\n", blocks_copied);
  
  close(src_fd);
  close(dst_fd);
  return blocks_copied;
  
}
