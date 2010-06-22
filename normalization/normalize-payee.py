#!/usr/bin/env python
# -*- coding: utf-8 -*-
import csv
import hashlib
import os
import sys

"""
Standardized PAYEE field from CSV on stdin and write normalized records to stdout.
"""

mapping = {}
for year in (2009,2010):
    for old, new, y in csv.reader(open(os.path.abspath('normalization_mapping-%s.csv' % year))):
        mapping[old] = new

OUT_FIELDS = "BIOGUIDE_ID,OFFICE,QUARTER,CATEGORY,DATE,PAYEE,PAYEE_NORM,START DATE,END DATE,PURPOSE,AMOUNT,YEAR,TRANSCODE,TRANSCODELONG,RECORDID,RECIP (orig.)".split(',')

uniques = {}

writer = csv.DictWriter(sys.stdout, OUT_FIELDS)
writer.writerow(dict(zip(OUT_FIELDS, OUT_FIELDS)))

last_payee = None

for record in csv.DictReader(sys.stdin):
    
    key = unicode("|".join(["%s:%s" % (k, v) for k, v in record.iteritems()]), errors='ignore')
    hsh = hashlib.md5(key.encode('ascii', 'ignore')).hexdigest()
    
    if hsh in uniques:
        
        uniques[hsh]['dupes'] += 1
        
    else:
        
        uniques[hsh] = {"record": record, "dupes": 0}
        
        amount = float(record['AMOUNT'].replace(',', '') or 0)
        
        if 'BIOGUIDE_ID' not in record and '' in record:
            record['BIOGUIDE_ID'] = record['']
            del record['']
        
        # normalize payee
        payee = record['PAYEE'].strip().upper()
        if payee == 'DO':
            payee = last_payee
        record['PAYEE_NORM'] = mapping.get(payee, payee)
        
        writer.writerow(record)
    
        last_payee = payee