#!/usr/bin/env python
import os
import sys

"""
Convert a universal new-line file to a normal new line file.
"""

inpath = os.path.abspath(sys.argv[1])

(filename, ext) = inpath.rsplit('.', 1)
outpath = "%s.nl.%s" % (filename, ext)

out = open(outpath, 'w')
for line in open(inpath, 'Ur'):
    out.write(line + '\n')