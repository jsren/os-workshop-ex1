#!/usr/bin/python
# patch64.py - (c) 2018 James Renwick
# Patches GCC configuration to disable red zone for libgcc

from __future__ import print_function
import re
import sys
import os
from shutil import copyfile

regex = re.compile("^x86_64-\\*-elf\\*\\)$")
patch = "\ttmake_file=\"${tmake_file} i386/t-x86_64-elf\"\n"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Failed: missing target file argument", file=sys.stderr)
        exit(1)

    copyfile(sys.argv[1], sys.argv[1] + '.old')
    with open(sys.argv[1] + '.old', 'r') as infile:
        with open(sys.argv[1], 'w') as outfile:
            insert = False
            done = False
            index = 0
            for line in infile:
                if regex.match(line):
                    insert = True
                elif insert:
                    if line != patch:
                        outfile.write(patch)
                        print("Patched line {}".format(index))
                    else:
                        print("Line already patched at {}".format(index))
                    done = True
                    insert = False
                outfile.write(line)
                index += 1
            if not done:
                print("Failed: could not locate line to patch!", file=sys.stderr)
                exit(2)
