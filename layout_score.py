#!/usr/bin/env python
import argparse
import os
import subprocess
import shlex
import time

def process_layout(filename):
    if verbose:
        print("processing " + filename + " to compute layout score")
        print('blkparse -a issue -f "%S %n\\n" -i ' + filename)
    while os.path.isfile("{}.blktrace.0".format(filename)) == False:
        if verbose:
            print("file not yet created")
        time.sleep(1)
    total_blocks = 0
    while total_blocks == 0:
        if verbose:
            print("blkparse...")
        blktrace_output = subprocess.check_output(shlex.split('blkparse -a issue -f "%S %n\n" -i ' + filename))
        blktrace_lines = blktrace_output.decode().split('\n')
        if verbose:
            print(len(blktrace_lines))
        blktrace_lines.pop() # removes the trailing empty string
        discont = -1 # number of discontiguous blocks
        total_blocks = 0 # total number of blocks
        last_sector = -1 # the last sector read
        for line in blktrace_lines:
            splitline = line.split()
            if verbose:
                print(splitline)
            if len(splitline) != 0 and splitline[0].isdigit(): # this makes sure we're not at one of blkparse's trailing non-data lines
                sector = int(splitline[0])
                length = int(splitline[1])
                if last_sector != sector:
                    discont = discont + 1
                last_sector = sector + length
                total_blocks = total_blocks + (length + 7) // 8
    return float(1) - float(discont)/float(total_blocks)

verbose = False
parser = argparse.ArgumentParser()
parser.add_argument("filename", help="filename of blktrace")
args = parser.parse_args()
filename = args.filename
layout_score = process_layout(filename)
exit(str(layout_score))