#!/usr/bin/python

################################################################################
# mtest.py runs the aging microbenchmark test suite using the configuration
# found in config.sh

import subprocess
import shlex
import csv
import time
import random
import os
import sys

# the profile namedtuple (similar to a C struct) contains all the info in a
# profile
from collections import namedtuple
profile = namedtuple("profile", ["name", "mntpnt", "partition"])

# FNULL is used to reroute output of certain subprocesses to /dev/null
FNULL = open(os.devnull, 'w')

# tcolors is used to changed the terminal color
class tcolors:
 bold = '\033[1m'
 pullnumber = '\033[94m'
 initialization = '\033[92m'
 firsttimesetup = '\033[36m'
 end = '\033[0m'
 

################################################################################
# greptest
# runs a wall-timed test of how long it takes to grep a fixed random string
# recursively through the research directory. testno is used to distinguish the
# traces; profile distinguishes the profile (aged/clean/etc)

def greptest(testno, profile):
 subprocess.check_call(shlex.split("bash remount.sh " + profile.name))
 time.sleep(2)
 print('blktrace -a read -d ' + profile.partition.rstrip('0123456789') + ' -o ' + test_name + '/' + profile.name + 'blktrace' + str(testno))
 subprocess.Popen('blktrace -a read -d ' + profile.partition.rstrip('0123456789') + ' -o ' + test_name + '/' + profile.name + 'blktrace' + str(testno), shell=True, stdout=FNULL, stderr=subprocess.STDOUT)
 time.sleep(2)
 print('grep -r --binary-files=text "' + grep_random + '" ' + profile.mntpnt)
 start = time.time()
 subprocess.call(shlex.split('grep -r --binary-files=text "' + grep_random + '" ' + profile.mntpnt), stderr=subprocess.STDOUT)
 stop = time.time() 
 print('kill -15 ' + subprocess.check_output(["pidof","-s","blktrace"]).strip())
 subprocess.call('kill -15 ' + subprocess.check_output(["pidof","-s","blktrace"]), shell=True, stdout=FNULL, stderr=subprocess.STDOUT)
 time.sleep(5)
 return (stop - start)

################################################################################
# process_layout
# processes the given blktrace file and computes the layout score

def process_layout(filename):
    print("processing " + filename + " to compute layout score")
    print('blkparse -a issue -f "%S %n\\n" -i ' + filename)
    while os.path.isfile("{}.blktrace.0".format(filename)) == False:
	time.sleep(1)
    total_blocks = 0
    while total_blocks == 0:
	    blktrace_output = subprocess.check_output(shlex.split('blkparse -a issue -f "%S %n\n" -i ' + filename))
	    blktrace_lines = blktrace_output.split('\n')
	    blktrace_lines.pop() # removes the trailing empty string
	    discont = -1 # number of discontiguous blocks
	    total_blocks = 0 # total number of blocks
	    last_sector = -1 # the last sector read
	    for line in blktrace_lines:
		splitline = line.split()
		if len(splitline) != 0 and splitline[0].isdigit(): # this makes sure we're not at one of blkparse's trailing non-data lines
		    sector = int(splitline[0])
		    length = int(splitline[1])
		    if last_sector != sector:
			discont = discont + 1
		    last_sector = sector + length
		    total_blocks = total_blocks + (length + 7) // 8
    return float(1) - float(discont)/float(total_blocks)

################################################################################
# initialization procedure

print(tcolors.initialization + "initializing test")

# check if config.sh exists, and exit if not
if os.path.isfile('config.sh') == False :
	print "********************"
	print "config.sh doesn't exist"
	print "edit defconfig.sh and save as config.sh"
	print "exiting script"
	print "********************"
	exit()

# load variables from config.sh using the printconfig.sh helper script
print("loading configuration parameters from config.sh")
config = subprocess.check_output(shlex.split("bash printconfig.sh"))
config = config.split('\n')
config.pop() # pop the trailing empty string

# set optional profiles to empty
clean = profile._make(["", "", ""])
cleaner = profile._make(["", "", ""])

for item in config:
	tmp = item.split(" ", 1)
	param = tmp[0]
	value = tmp[1]
	if param == 'test_name':
		test_name = value
	if param == 'grep_random':
		grep_random = value
        if param == 'keep_traces':
                if value == "True":
                    keep_traces = True
                else:
                    keep_traces = False

        if param == 'rfs_test':
                if value == "True":
                    rfs_test = True
                else:
                    rfs_test = False

        if param == 'fs_test':
                if value == "True":
                    fs_test = True
                else:
                    fs_test = False
	if param == 'fs_fs_size':
		fs_fs_size = int(value)	
	if param == 'fs_directory_count':
		fs_directory_count = int(value)

        if param == 'rr_test':
                if value == "True":
                    rr_test = True
                else:
                    rr_test = False
	if param == 'rr_file_count':
		rr_file_count = int(value)
        if param == 'rr_initial_size':
                rr_initial_size = int(value)
        if param == 'rr_chunk_size':
                rr_chunk_size = int(value)
        if param == 'rr_rounds':
                rr_rounds = int(value)

        if param == 'rlt_test':
                if value == "True":
                    rlt_test = True
                else:
                    rlt_test = False

	if param == 'aged':
		aged = profile._make(["aged", value.split()[0], value.split()[1]])
	if param == 'clean':
		clean = profile._make(["clean", value.split()[0], value.split()[1]])
	if param == 'cleaner':
		cleaner = profile._make(["cleaner", value.split()[0], value.split()[1]])

# format the partitions
subprocess.check_call(shlex.split("bash format.sh aged"))
if (clean.name != ""):
	subprocess.check_call(shlex.split("bash format.sh clean"))
if (cleaner.name != ""):
	subprocess.check_call(shlex.split("bash format.sh cleaner"))

# create a dir to hold the results and traces
print("mkdir -p " + test_name)
subprocess.check_call(shlex.split("mkdir -p " + test_name))

# make sure blktrace isn't running
try:
 subprocess.call('kill -15 ' + subprocess.check_output(["pidof","-s","blktrace"]), shell=True)
except Exception, e:
 pass

print('initialization complete' + tcolors.end)


################################################################################
# Random File Structure Test
# creates a random directory tree, then populates it with random 4kb files,
# then runs a grep test

if rfs_test == True:

    print("{}Running Random File Structure Test{}".format(tcolors.bold, tcolors.end))

    # open the results file and give the column headings
    resultfile = open("{}/{}_rfs_results.csv".format(test_name,test_name),'w')
    resultfile.write("file_count aged_time aged_layout_score ")
    if clean.mntpnt != "":
        resultfile.write(" clean_time clean_layout_score ")
    if cleaner.mntpnt != "":
        resultfile.write(" cleaner_time cleaner_layout_score ")
    resultfile.write("\n")

    file_count = 10000

    if os.path.isfile('rfs_dir.txt') == False:
        dirfile = open('rfs_dir.txt','w')
        dirlist = ['']
        for i in range(0,1000):
            parent = random.choice(dirlist)
            dirlist.append("{}dir{}/".format(parent, i))
            dirfile.write("{}dir{}/\n".format(parent, i))
        dirfile.close()

        filefile = open('rfs_file.txt','w')
        for i in range(0,file_count):
            parent = random.choice(dirlist)
            filefile.write("{}file{}\n".format(parent, i))
        filefile.close()

    file_size = 4096
    subprocess.check_call(shlex.split("bash format.sh aged"))
    print(tcolors.bold + 'creating directory structure' + tcolors.end)
    dirfile = open('rfs_dir.txt')
    dirlist = dirfile.readlines()
    for directory in dirlist:
        #print("mkdir " + directory.strip())
        subprocess.check_call(['mkdir',directory.strip()],cwd=aged.mntpnt)
    dirfile.close()

    print(tcolors.bold + 'creating files' + tcolors.end)
    filefile = open('rfs_file.txt')
    filelist = filefile.readlines()
    files_created = 0
    for filename in filelist:
        print("head -c {} </dev/urandom > {}".format(file_size, filename.strip()))
        subprocess.check_call("head -c {} </dev/urandom > {}".format(file_size, filename.strip()), shell=True, cwd=aged.mntpnt)
        files_created = files_created + 1

        if files_created % 100 == 0:
            resultfile.write(str(files_created) + " ")
            print("{}\nrunning aged grep test: {}{}".format(tcolors.bold, files_created, tcolors.end))
            agedgrep = greptest("_rfs_{}".format(files_created), aged)
            aged_layout_score = process_layout("{}/agedblktrace_rfs_{}".format(test_name,files_created))
            resultfile.write(str(agedgrep) + " " + str(aged_layout_score) + " ")

            if clean.mntpnt != "":
                print("{}\nrunning clean grep test: {}{}".format(tcolors.bold, files_created, tcolors.end))
                subprocess.check_call(shlex.split("bash format.sh clean"))
                print("cp -a " + aged.mntpnt + "/* " + clean.mntpnt)
                subprocess.check_output("cp -a " + aged.mntpnt + "/* " + clean.mntpnt,shell=True)
                cleangrep = greptest("_rfs_{}".format(files_created), clean)
                clean_layout_score = process_layout("{}/cleanblktrace_rfs_{}".format(test_name,files_created))
                resultfile.write(str(cleangrep) + " " + str(clean_layout_score) + " ")
            if cleaner.mntpnt != "":
                print("{}\nrunning cleaner grep test: {}{}".format(tcolors.bold, files_created, tcolors.end))
                subprocess.check_call(shlex.split("bash unmount.sh clean"))
                subprocess.check_call(shlex.split("bash unmount.sh cleaner"))
                print("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M")
                subprocess.check_call(shlex.split("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M"), stdout=FNULL, stderr=subprocess.STDOUT)
                subprocess.check_call(shlex.split("bash mount.sh clean"))
                subprocess.check_call(shlex.split("bash mount.sh cleaner"))
                cleanergrep = greptest("_rfs_{}".format(files_created), cleaner)
                cleaner_layout_score = process_layout("{}/cleanerblktrace_rfs_{}".format(test_name,files_created))
                resultfile.write(str(cleanergrep) + " " + str(cleaner_layout_score) + " ")
            resultfile.write("\n")
            resultfile.flush()

            print(tcolors.bold + '\nresults of grep test ' + str(files_created))
            print('grep test completed in ' + str(agedgrep) + ' seconds')
            if clean.name != "":
                print('clean test completed in ' + str(cleangrep) + ' seconds')
            if cleaner.name != "":
                print('cleaner test completed in ' + str(cleanergrep) + ' seconds')
            print('aged layout score: ' + str(aged_layout_score))
            if clean.name != "":
                print('clean layout score: ' + str(clean_layout_score))
            if cleaner.name != "":
                print('cleaner layout score: ' + str(cleaner_layout_score))
            print(tcolors.end)
            
            if keep_traces != True:
                print("rm {}/*blktrace*".format(test_name))
                subprocess.check_call("rm {}/*blktrace*".format(test_name), shell=True)

        if files_created == file_count:
            break

    resultfile.close()

################################################################################
# Random File Structure Test
# creates a random directory tree, then populates it with random files of
# increasing size, then runs a grep test

if fs_test == True:

    print("{}Running Random File Structure Test{}".format(tcolors.bold, tcolors.end))

    # open the results file and give the column headings
    resultfile = open("{}/{}_fs_results.csv".format(test_name,test_name),'w')
    resultfile.write("file_size fs_size aged_time aged_layout_score ")
    if clean.mntpnt != "":
        resultfile.write(" clean_time clean_layout_score ")
    if cleaner.mntpnt != "":
        resultfile.write(" cleaner_time cleaner_layout_score ")
    resultfile.write("\n")

    file_count = fs_fs_size / 4096

    if os.path.isfile('dir.txt') == False:
        dirfile = open('dir.txt','w')
        dirlist = ['']
        for i in range(0,fs_directory_count):
            parent = random.choice(dirlist)
            dirlist.append("{}dir{}/".format(parent, i))
            dirfile.write("{}dir{}/\n".format(parent, i))
        dirfile.close()

        filefile = open('file.txt','w')
        for i in range(0,file_count):
            parent = random.choice(dirlist)
            filefile.write("{}file{}\n".format(parent, i))
        filefile.close()

    file_size = 8192
    while file_size <= 20*1024:
        subprocess.check_call(shlex.split("bash format.sh aged"))
        print(tcolors.bold + 'creating directory structure' + tcolors.end)
        dirfile = open('dir.txt')
        dirlist = dirfile.readlines()
        for directory in dirlist:
            #print("mkdir " + directory.strip())
            subprocess.check_call(['mkdir',directory.strip()],cwd=aged.mntpnt)
        dirfile.close()

        print(tcolors.bold + 'creating files' + tcolors.end)
        filefile = open('file.txt')
        filelist = filefile.readlines()
        file_count = fs_fs_size / file_size
        files_created = 0
        for filename in filelist:
            subprocess.check_call(shlex.split("bash remount.sh aged"), stdout=FNULL, stderr=subprocess.STDOUT)
            sys.stdout.write("Writing file {file_no: >{max_length}}/{total_files}\r".format(file_no=files_created + 1, max_length=len(str(file_count)), total_files=file_count))
            sys.stdout.flush()
            subprocess.check_call("head -c {} </dev/urandom > {}".format(file_size, filename.strip()), shell=True, cwd=aged.mntpnt)
            files_created = files_created + 1
            if files_created == file_count:
                break

  	fssize = subprocess.check_output(shlex.split("du -s"), cwd=aged.mntpnt).split()[0]
        resultfile.write(str(file_size) + " " + str(fssize))

        print("{}\nrunning aged grep test: {}kb{}".format(tcolors.bold, file_size/1024, tcolors.end))
        agedgrep = greptest("_fs_{}".format(file_size/1024), aged)
        aged_layout_score = process_layout("{}/agedblktrace_fs_{}".format(test_name,file_size/1024))
        resultfile.write(str(agedgrep) + " " + str(aged_layout_score) + " ")

        if clean.mntpnt != "":
            print("{}\nrunning clean grep test: {}kb{}".format(tcolors.bold, file_size/1024, tcolors.end))
            subprocess.check_call(shlex.split("bash format.sh clean"))
            print("cp -a " + aged.mntpnt + "/* " + clean.mntpnt)
            subprocess.check_output("cp -a " + aged.mntpnt + "/* " + clean.mntpnt,shell=True)
            cleangrep = greptest("_fs_{}".format(file_size/1024), clean)
            clean_layout_score = process_layout("{}/cleanblktrace_fs_{}".format(test_name,file_size/1024))
            resultfile.write(str(cleangrep) + " " + str(clean_layout_score) + " ")
        if cleaner.mntpnt != "":
            print("{}\nrunning cleaner grep test: {}kb{}".format(tcolors.bold, file_size/1024, tcolors.end))
            subprocess.check_call(shlex.split("bash unmount.sh clean"))
            subprocess.check_call(shlex.split("bash unmount.sh cleaner"))
            print("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M")
            subprocess.check_call(shlex.split("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M"), stdout=FNULL, stderr=subprocess.STDOUT)
            subprocess.check_call(shlex.split("bash mount.sh clean"))
            subprocess.check_call(shlex.split("bash mount.sh cleaner"))
            cleanergrep = greptest("_fs_{}".format(file_size/1024), cleaner)
            cleaner_layout_score = process_layout("{}/cleanerblktrace_fs_{}".format(test_name,file_size/1024))
            resultfile.write(str(cleanergrep) + " " + str(cleaner_layout_score) + " ")
        resultfile.write("\n")
        resultfile.flush()

        print(tcolors.bold + '\nresults of grep test ' + str(file_size/1024) + 'kb:')
        print('grep test completed in ' + str(agedgrep) + ' seconds')
        if clean.name != "":
            print('clean test completed in ' + str(cleangrep) + ' seconds')
        if cleaner.name != "":
            print('cleaner test completed in ' + str(cleanergrep) + ' seconds')
        print('aged layout score: ' + str(aged_layout_score))
        if clean.name != "":
            print('clean layout score: ' + str(clean_layout_score))
        if cleaner.name != "":
            print('cleaner layout score: ' + str(cleaner_layout_score))
        print(tcolors.end)

        if keep_traces != True:
            print("rm {}/*blktrace*".format(test_name))
            subprocess.check_call("rm {}/*blktrace*".format(test_name), shell=True)
        file_size = file_size + 4096

    resultfile.close()



################################################################################
# Round Robin Appendage Test
# this test creates n files and then proceeds to append m kb chunks of random
# data to them in round robin fashion, timing greps every round for r rounds

if rr_test == True:

    print("{}Running Round Robin Appendage Test{}".format(tcolors.bold, tcolors.end))
    resultfile = open("{}/{}_rr_results.csv".format(test_name, test_name), "w")
    resultfile.write("round fs_size aged_time aged_layout_score")
    if clean.mntpnt != "":
        resultfile.write(" clean_time clean_layout_score")
    if cleaner.mntpnt != "":
        resultfile.write(" cleaner_time cleaner_layout_score")
    resultfile.write("\n")

    subprocess.check_call(shlex.split("bash format.sh aged"))

    print("Creating {} {}kb files".format(rr_file_count, rr_initial_size))
    for j in range(0, rr_file_count):
        print("head -c {} </dev/urandom > {}/file{}".format(rr_initial_size, aged.mntpnt, j))
        subprocess.check_call("head -c {} </dev/urandom > {}/file{}".format(rr_initial_size, aged.mntpnt, j),shell=True)

    for i in range(1, rr_rounds + 1):
        print("{}\nrunning aged grep test: round {}{}".format(tcolors.bold, i, tcolors.end))
        resultfile.write("{} {} ".format(i, rr_file_count*rr_chunk_size*i+rr_file_count*rr_initial_size))
        agedgrep = greptest("_rr_{}".format(i), aged)
        aged_layout_score = process_layout("{}/agedblktrace_rr_{}".format(test_name,i))
        resultfile.write(str(agedgrep) + " " + str(aged_layout_score) + " ")

        if clean.mntpnt != "":
            print("{}\nrunning clean grep test: round {}{}".format(tcolors.bold, i, tcolors.end))
            subprocess.check_call(shlex.split("bash format.sh clean"))
            print("cp -a " + aged.mntpnt + "/* " + clean.mntpnt)
            subprocess.check_output("cp -a " + aged.mntpnt + "/* " + clean.mntpnt,shell=True)
            cleangrep = greptest("_rr_{}".format(i), clean)
            clean_layout_score = process_layout("{}/cleanblktrace_rr_{}".format(test_name,i))
            resultfile.write(str(cleangrep) + " " + str(clean_layout_score) + " ")

        if cleaner.mntpnt != "":
            print("{}\nrunning cleaner grep test: round {}{}".format(tcolors.bold, i, tcolors.end))
            subprocess.check_call(shlex.split("bash unmount.sh clean"))
            subprocess.check_call(shlex.split("bash unmount.sh cleaner"))
            print("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M")
            subprocess.check_call(shlex.split("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M"), stdout=FNULL, stderr=subprocess.STDOUT)
            subprocess.check_call(shlex.split("bash mount.sh clean"))
            subprocess.check_call(shlex.split("bash mount.sh cleaner"))
            cleanergrep = greptest("_rr_{}".format(i), cleaner)
            cleaner_layout_score = process_layout("{}/cleanerblktrace_rr_{}".format(test_name,i))
            resultfile.write(str(cleanergrep) + " " + str(cleaner_layout_score) + " ")
        resultfile.write("\n")
        resultfile.flush()

        print(tcolors.bold + '\nresults of grep test round ' + str(i))
        print('grep test completed in ' + str(agedgrep) + ' seconds')
        if clean.name != "":
            print('clean test completed in ' + str(cleangrep) + ' seconds')
        if cleaner.name != "":
            print('cleaner test completed in ' + str(cleanergrep) + ' seconds')
        print('aged layout score: ' + str(aged_layout_score))
        if clean.name != "":
            print('clean layout score: ' + str(clean_layout_score))
        if cleaner.name != "":
            print('cleaner layout score: ' + str(cleaner_layout_score))
        print(tcolors.end)

        if keep_traces != True:
            print("rm {}/*blktrace*".format(test_name))
            subprocess.check_call("rm {}/*blktrace*".format(test_name), shell=True)

        for j in range(0, rr_file_count):
            print("head -c {} </dev/urandom >> {}/file{}".format(rr_chunk_size, aged.mntpnt, j))
            subprocess.check_call("head -c {} </dev/urandom >> {}/file{}".format(rr_chunk_size, aged.mntpnt, j), shell=True)

    resultfile.close()


################################################################################
# Random Linux Test
# this test copies the files in the linux kernel to the target drive in random
# order, times a grep, then copies them normally and times a grep.

if rlt_test == True:
    subprocess.check_call(shlex.split("bash format.sh aged"))

    print("{}\nRunning Random Linux Test{}{}".format(tcolors.bold, tcolors.end, tcolors.initialization))

    resultfile = open("{}/{}_rlt_results.csv".format(test_name, test_name), "w")
    resultfile.write("aged_time aged_layout_score")
    if clean.mntpnt != "":
        resultfile.write(" clean_time clean_layout_score")
    if cleaner.mntpnt != "":
        resultfile.write(" cleaner_time cleaner_layout_score")
    resultfile.write("\n")

    if os.path.isdir("linux") == False:
        print("linux repo not found")
        print("git clone https://github.com/torvalds/linux.git")
        subprocess.check_call(shlex.split("git clone https://github.com/torvalds/linux.git"), stdout=FNULL, stderr=subprocess.STDOUT)

    if os.path.isfile("randomfilelist.txt") == False:
        print("randomfilelist.txt not found")
        print("find linux -type f | shuf > randomfilelist.txt")
        subprocess.check_call("find linux -type f | shuf > randomfilelist.txt", shell=True)
    linuxfile = open('randomfilelist.txt')
    print(tcolors.end)

    counter = 1
    linuxlines = linuxfile.readlines()
    for line in linuxlines:
        sys.stdout.write("copying file {file_no: >{max_length}}/{total_files}\r".format(file_no=counter, max_length=len(str(len(linuxlines))), total_files=len(linuxlines)))
        sys.stdout.flush()
        subprocess.check_call(shlex.split("cp --parents {} {}".format(line.strip(), aged.mntpnt)))
        counter = counter + 1

    print("{}\nrunning aged grep test{}".format(tcolors.bold, tcolors.end))
    agedgrep = greptest("_rlt", aged)
    aged_layout_score = process_layout("{}/agedblktrace_rlt".format(test_name))
    resultfile.write(str(agedgrep) + " " + str(aged_layout_score) + " ")

    if clean.mntpnt != "":
        print("{}\nrunning clean grep test{}".format(tcolors.bold, tcolors.end))
        subprocess.check_call(shlex.split("bash format.sh clean"))
        print("cp -a " + aged.mntpnt + "/* " + clean.mntpnt)
        subprocess.check_output("cp -a " + aged.mntpnt + "/* " + clean.mntpnt,shell=True)
        cleangrep = greptest("_rlt", clean)
        clean_layout_score = process_layout("{}/cleanblktrace_rlt".format(test_name))
        resultfile.write(str(cleangrep) + " " + str(clean_layout_score) + " ")

    if cleaner.mntpnt != "":
        print("{}\nrunning cleaner grep test{}".format(tcolors.bold, tcolors.end))
        subprocess.check_call(shlex.split("bash unmount.sh clean"))
        subprocess.check_call(shlex.split("bash unmount.sh cleaner"))
        print("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M")
        subprocess.check_call(shlex.split("dd if=" + clean.partition + " of=" + cleaner.partition + " bs=4M"), stdout=FNULL, stderr=subprocess.STDOUT)
        subprocess.check_call(shlex.split("bash mount.sh clean"))
        subprocess.check_call(shlex.split("bash mount.sh cleaner"))
        cleanergrep = greptest("_rlt", cleaner)
        cleaner_layout_score = process_layout("{}/cleanerblktrace_rlt".format(test_name))
        resultfile.write(str(cleanergrep) + " " + str(cleaner_layout_score) + " ")
    resultfile.write("\n")
    resultfile.flush()

    print(tcolors.bold + '\nresults of grep test:')
    print('grep test completed in ' + str(agedgrep) + ' seconds')
    if clean.name != "":
        print('clean test completed in ' + str(cleangrep) + ' seconds')
    if cleaner.name != "":
        print('cleaner test completed in ' + str(cleanergrep) + ' seconds')
    print('aged layout score: ' + str(aged_layout_score))
    if clean.name != "":
        print('clean layout score: ' + str(clean_layout_score))
    if cleaner.name != "":
        print('cleaner layout score: ' + str(cleaner_layout_score))
    print(tcolors.end)

    if keep_traces != True:
        print("rm {}/*blktrace*".format(test_name))
        subprocess.check_call("rm {}/*blktrace*".format(test_name), shell=True)


################################################################################
# Clean Up

try:
    subprocess.call(['kill', '-15', subprocess.check_output(["pidof","-s","blktrace"])])
except Exception, e:
    pass

subprocess.call(shlex.split("bash unmount.sh aged"))
if clean.mntpnt != "":
    subprocess.call(shlex.split("bash unmount.sh clean"))
if cleaner.mntpnt != "":
    subprocess.call(shlex.split("bash unmount.sh cleaner"))

