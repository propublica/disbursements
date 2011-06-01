#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
    This script was used to convert the 2009 Q3 House Disbursement PDF into detail and summary CSV files.
        Source PDF: http://disbursements.house.gov/
        Resulting Data: http://www.sunlightfoundation.com/projects/2009/expenditures/

    It was originally authored by Luke Rosiak with improvements by James Turk for Sunlight Labs and is released into the public domain.

    Disclaimer: It was written quickly under deadline and likely contains a few bugs - patches welcome

    It expects a file (named in the disbursements_file variable below) created as the result of something like the following two operations:
       
       pdftk 2010q1_singlevolume.pdf cat 10-3613 output disbursements-only.pdf
       
       pdftotext -layout disbursements-only.pdf


    Update the:
      * disbursements_file variable (input file, e.g. '2010q2-disbursements-only.txt')
      * year (e.g. '2009', '2010')
      * quarter (e.g. 'Q1', 'Q2') 
   
   WARNING: there's a hardcoded or clause with individual years in it - this should be refactored to be an array, or at least kept up to date. I added up to 2015.
'''

disbursements_file = '2011q1-disbursements-only.txt'
year = '2011'
quarter = 'Q1'
thisquarter = year + quarter

import csv, re, sys

BAD_LINE_RE = re.compile('^(Frm|Fmt|Sfmt|Jkt|VerDate|VOUCHER|OFFICIAL\sEXPENSES|MEMBERS\sREPRESENATION\sALLOW|PO|APPS06|PsN:|07:23|M:)')


def known_bad(line):
    return (not line) or BAD_LINE_RE.match(line) or 'dkrause' in line

def main():
    f = open(disbursements_file, "r")

    fsummary = csv.writer(open("%s%s-house-disburse-summary.csv" % (year, quarter), "w"), quoting=csv.QUOTE_ALL)
    fsummary.writerow( ['OFFICE','YEAR','QUARTER','CATEGORY', 'YTD', 'AMOUNT'] )
    fdetail = csv.writer(open("%s%s-house-disburse-detail.csv" % (year, quarter), "w"), quoting=csv.QUOTE_ALL)
    fdetail.writerow( ['OFFICE','QUARTER','CATEGORY','DATE','PAYEE','START DATE','END DATE','PURPOSE','AMOUNT','YEAR', 'TRANSCODE','TRANSCODELONG','RECORDID','RECIP (orig.)'] )
    trashcan = open('%s%s-trashlines.txt' % (year, quarter),'w')

    cats = ['FRANKED MAIL', 'PERSONNEL COMPENSATION', 'PERSONNEL BENEFITS', 'TRAVEL', 'RENT, COMMUNICATION, UTILITIES', 'PRINTING AND REPRODUCTION', 'OTHER SERVICES', 'SUPPLIES AND MATERIALS', 'EQUIPMENT', 'TRANSPORTATION OF THINGS']

    thismem = ''
    thiscat = ''
    thisyear = ''

    oldrecip = None

    regular_re = re.compile(r"""(\d{2}-\d{2})\s+            # date
                            ([0-9A-Z]{2})\s+                # transaction code
                            ([0-9A-Z\-]+)\s+                  # record id
                            (.*?)                           # recipient
                            (\d{2}/{1}\d{2}/{1}\d{2})\s+    # date-start
                            (\d{2}/{1}\d{2}/{1}\d{2})       # date-end
                            (.*?)\s+                        # description
                            (-?[0-9,]+\.\d{2})              # amount
                            """, re.VERBOSE)
    personel_re = re.compile(r"""(.*?)                      # recipient
                             (\d{2}/{1}\d{2}/{1}\d{2})\s+   # date-start
                             (\d{2}/{1}\d{2}/{1}\d{2})      # date-end
                             (.*?)\s+                       # description
                             (-?[0-9,]+\.\d{2})             # amount
                             """, re.VERBOSE)
    summary_re = re.compile(r"""(.*?)\.+\s+         # category
                            (-?[0-9,]+\.\d{2})\s+   # 2009
                            (-?[0-9,]+\.\d{2})      # 2009-Q3
                            """, re.VERBOSE)


    benefits_re = re.compile(r"""(\d{2}-\d{2})\s+            # date
                            ([0-9A-Z]{2})\s+                # transaction code
                            ([0-9A-Z]+)\s+                  # record id
                            (.*?)                           # recipient
                            \s+    # no dates
                            (.*?)\s+                        # description
                            (-?[0-9,]+\.\d{2})              # amount
                            """, re.VERBOSE)



    ditto_re = re.compile(r"""\s*DO[\s\.]*""")


    transcodes = {
'CB':	'FedEx / UPS',
'CO': 'Cash receipt from feds',
'C1': 'Bottled Water',
'C2': 'Office Supplies',
'C3': 'Velocita Wireless',
'F1': 'maintenance on House assets',
'F2': 'equipment recorded as a House asset',
'HR': 'Cash receipt-check or EFT payment',
'HV': 'Adjusting transaction changing accounting strip information',
'PR': 'Payroll and benefit',
'P1': 'Payment/reimbursement requested on a standard voucher',
'P2': 'purchase order',
'P5': 'printing and production',
'P6': 'Student loan',
'P9': 'District Office, long-term automobile lease or vendor contract',
'OP': 'Payment to a Federal entity',
'O4': 'USPS franked mail',
'O5': 'liquidating franked mail portion of a mass mail obligation',
'P7': 'E-mail and web services',
'SF': 'flag purchase',
'S1': 'goods purchased through Office Supply Store',
'S3': 'services from the Offices of Photography and Graphics',
'S4': 'services from the House Recording Studio',
'S5': 'Telecommunication services',
'S6': 'District Office rent in space leased from GSA',
'S7': 'Transit Benefits',
'S8': 'equipment plan or maintenance provided through the CAO' } 


    for l in f.readlines():

        # replace UTF-8 minus with normal dash and strip
        # replace smart quotes with regular quotes
        l = l.replace('–','-').replace('″', '"').replace('’', '\'').strip()
        

        # new member
        #TODO: refactor this to use an array
        if l.startswith("2015 ") or l.startswith("2014 ") or l.startswith("2013 ") or l.startswith("2012 ") or l.startswith("2011 ") or l.startswith("2010 ") or l.startswith("2008 ") or l.startswith("2009 ") or l.startswith('2007 ') or l.startswith("FISCAL YEAR "):
            if l.startswith("FISCAL YEAR "):
                thismem = l.replace('—', '')[17:]
                thisyear = l[:16]
            else:
                thismem = l.replace('—', '')[5:]
                thisyear = l[:4]
            if thismem.endswith("Con."):
                thismem = thismem[:-4]
            continue

        # category
        if l in cats:
            thiscat = l
            continue

        #regular record
        ma = regular_re.search(l)
        if ma:
            m = ma.groups()
            date1 = m[0].replace('–', '-')
            transcode = m[1]
            recordid = m[2]
            recip = m[3].strip().rstrip('.').rstrip('\t')
            sunrecip = recip
            if ditto_re.match(recip):
                sunrecip = oldrecip
            else:
                oldrecip = recip
            if sunrecip=='':
                sunrecip=recip
            date2 = m[4]
            date3 = m[5]
            descrip = m[6].strip().rstrip('.')
            amount = m[7]

            transcodelong = ''
            if transcode in transcodes:
                transcodelong = transcodes[transcode]

            #fdetail.writerow([thismem, thisquarter, thisyear, thiscat, date1, transcode, recordid, sunrecip, recip, date2, date3, descrip, amount])
            fdetail.writerow([thismem, thisquarter, thiscat, date1, sunrecip, date2, date3, descrip, amount, thisyear, transcode, transcodelong, recordid, recip])
            continue

        # personell record
        ma = personel_re.search(l)
        if ma:
            m = ma.groups()
            recip = m[0].strip().rstrip('.')
            sunrecip = recip
            if ditto_re.match(recip):
                sunrecip = oldrecip
            else:
                oldrecip = recip
            date2 = m[1]
            date3 = m[2]
            descrip = m[3].strip().rstrip('.')
            amount = m[4]
            #fdetail.writerow( ['OFFICE','QUARTER','CATEGORY','DATE','PAYEE','START DATE','END DATE','PURPOSE','AMOUNT','YEAR', 'TRANSCODE','TRANSCODELONG','RECORDID','RECIP (orig.)'] )
            #fdetail.writerow([thismem, thisquarter, thisyear, thiscat, "", "", "", sunrecip, recip, date2, date3, descrip, amount])
            fdetail.writerow([thismem, thisquarter, thiscat, "", sunrecip, date2, date3, descrip, amount, thisyear, "","","", recip ])
            continue




        # benefits record
        ma = benefits_re.search(l)
        if ma:
            m = ma.groups()
            recip = m[3].strip().rstrip('.')
            sunrecip = recip
            if ditto_re.match(recip):
                sunrecip = oldrecip
            else:
                oldrecip = recip
            descrip = m[4].strip().rstrip('.')
            amount = m[5]
            date1 = m[0].replace('–', '-')
            transcode = m[1]
            recordid = m[2]
            transcodelong = ''
            if transcode in transcodes:
                transcodelong = transcodes[transcode]


            #fdetail.writerow( ['OFFICE','QUARTER','CATEGORY','DATE','PAYEE','START DATE','END DATE','PURPOSE','AMOUNT','YEAR', 'TRANSCODE','TRANSCODELONG','RECORDID','RECIP (orig.)'] )
            print [thismem, thisquarter, thiscat, date1, sunrecip, "","", descrip, amount, thisyear, transcode,transcodelong,recordid, recip ]
            fdetail.writerow([thismem, thisquarter, thiscat, date1, sunrecip, "","", descrip, amount, thisyear, transcode,transcodelong,recordid, recip ])
            continue





        # summary record
        ma = summary_re.search(l)
        if ma:
            m = ma.groups()
            if m[0].strip() in cats:
                fsummary.writerow([thismem, thisyear, thisquarter, m[0].strip(), m[1], m[2]])
                continue

        if not known_bad(l):
            trashcan.write(l)

if __name__ == '__main__':
    main()
