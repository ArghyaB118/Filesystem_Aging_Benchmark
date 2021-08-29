#! /usr/bin/python

################################################################################
# inter_layout.py
# this script processes raw interfile microbenchmark layout files so they may be
# easily plotted

import argparse
import glob
import re

parser = argparse.ArgumentParser()
parser.add_argument("pathname")

args = parser.parse_args()

layout = []

with open(args.pathname, "r") as interfile:
    interlines = interfile.readlines()
    for i in range(0,len(interlines)):
        layout.append([i, int(interlines[i].split()[0])/8])

min_lba = min(layout, key = lambda x: x[1])[1]
for i in range(0,len(layout)):
    layout[i][1] = layout[i][1] - min_lba
with open("{}.csv".format(args.pathname), "w") as outputfile:
    outputfile.write("request block\n")
    for i in range(0,len(layout)):
        outputfile.write("{} {}\n".format(layout[i][0], layout[i][1]))
