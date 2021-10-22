all: seq random

seq:    write_ssd.c read_ssd.c seq_num.log
	cp seq_num.log my_num.log
	gcc write_ssd.c -o write_ssd_seq -lrt
	gcc read_ssd.c -o read_ssd_seq -lrt

random: write_ssd.c read_ssd.c rand_num.log
	cp rand_num.log my_num.log
	gcc write_ssd.c -o write_ssd_rand -lrt
	gcc read_ssd.c -o read_ssd_rand -lrt

rand_num.log:
	python random_num.py >> rand_num.log

clean:
	rm -f write_ssd_seq read_ssd_seq
	rm -f write_ssd_rand read_ssd_rand
