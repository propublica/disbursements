#!/usr/bin/env python
from metaphone import dm
import csv
import os
import re
import sys

SUFFIXES = ('association','assoc','assn','incorporated','inc','company','co',
'corporation','corp','committee','cmte','limited','ltd')
SUFFIX_RE = re.compile(r'(%s)$' % '|'.join(SUFFIXES))
NOT_ALPHANUM_RE = re.compile(r'[^a-zA-Z0-9]')
NOT_ALPHANUMSPACE_RE = re.compile(r'[^a-zA-Z0-9 ]')
NAME_SUFFIXES = ('JR','II')

def is_person(name):
    stnd = NOT_ALPHANUMSPACE_RE.sub('', name)
    parts = stnd.split(' ')
    for suffix in NAME_SUFFIXES:
        if suffix in parts:
            parts.remove(suffix)
    min_letter = min([len(s) for s in parts if len(s) > 0])
    return (len(parts) < 4 and min_letter == 1) or (len(parts) == 2 and ',' in name)

def basic_normalizer(s):
    s = s.lower().replace('&', ' and ')
    s = NOT_ALPHANUM_RE.sub('', s)
    s = SUFFIX_RE.sub('', s)
    return s

def phonetic_normalizer(s):
    s = s.lower()
    s = NOT_ALPHANUMSPACE_RE.sub('', s)
    s = "".join(w for w in sorted(s.split(' ')) if w not in SUFFIXES)
    return dm(unicode(s))[0]

OUTFIELDS = ('payee','normalized_basic','normalized_phonetic','payee_standardized')

mapping = {}
normalized = {}
to_normalize = {}

for record in csv.DictReader(open('normalization_mapping.csv')):
    mapping[record['original']] = record['normalized']

for record in csv.reader(open('2009-normalized_payees.csv')):
    normalized[record[0]] = True

path = os.path.abspath(sys.argv[1])
for record in csv.DictReader(open(path, 'U')):
    payee = record['PAYEE'].strip().upper()
    payee = mapping.get(payee, payee)
    if payee and payee not in normalized and payee not in to_normalize:
        if not is_person(payee):
            to_normalize[payee] = {
                'payee': payee,
                'normalized_basic': basic_normalizer(payee),
                'normalized_phonetic': phonetic_normalizer(payee),
                'payee_standardized': payee,
            }

writer = csv.DictWriter(sys.stdout, fieldnames=OUTFIELDS)
writer.writerow(dict(zip(OUTFIELDS, OUTFIELDS)))
for record in to_normalize.itervalues():
    writer.writerow(record)