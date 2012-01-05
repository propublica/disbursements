#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
    This script is used to convert House Disbursement PDFs into detail and summary CSV files.
        Source PDF: http://disbursements.house.gov/
        Resulting Data: http://www.sunlightfoundation.com/projects/2009/expenditures/

    It was originally authored by Luke Rosiak with improvements by James Turk for Sunlight Labs and is released into the public domain.

    It expects a file (named in the disbursements_file variable below) created as the result of something like the following operation:
       
       pdftotext -layout 2010q1_singlevolume.pdf

    The filename's first six characters must represent the quarter it covers. The file is passed to this script as its only argument:
    
       python parse-disbursements.py 2010q1_singlevolume.txt
      
  
'''


import csv, re, sys, os

BAD_LINE_RE = re.compile('^(Frm|Fmt|Sfmt|Jkt|VerDate|VOUCHER|OFFICIAL\sEXPENSES|MEMBERS\sREPRESENATION\sALLOW|PO|APPS06|PsN:|07:23|M:)')


def known_bad(line):
    return (not line) or BAD_LINE_RE.match(line) or 'dkrause' in line

def main(disbursements_file):
    
    path, filename = os.path.split(disbursements_file)
    year = filename[:4]
    quarter = filename[4:6].upper()
    thisquarter = year + quarter
    
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

    regular_re = re.compile(r"""(\d{2}-\d{2})[\s\.]+            # date
                            (GL\sLAW|GL\sFRM|\w{2})[\s\.]+       # transaction code
                            ([0-9A-Z\-]+)[\s\.]+                # record id
                            (.*?)[\s\.]+                        # recipient
                            (\d{2}/{1}\d{2}/{1}\d{2})[\s\.]+    # date-start
                            (\d{2}/{1}\d{2}/{1}\d{2})[\s\.]+    # date-end
                            (.*?)[\s\.]+                        # description
                            (-?[0-9,]+\.\d{2})                  # amount
                            """, re.VERBOSE)
    personnel_re = re.compile(r"""(.*?)[\s\.]+                  # recipient
                             (\d{2}/{1}\d{2}/{1}\d{2})[\s\.]+   # date-start
                             (\d{2}/{1}\d{2}/{1}\d{2})[\s\.]+   # date-end
                             (.*?)[\s\.]+                       # description
                             (-?[0-9,]+\.\d{2})                 # amount
                             """, re.VERBOSE)
    summary_re = re.compile(r"""(.*?)[\s\.]+                    # category
                            (-?[0-9,]+\.\d{2})\s+               # 2009
                            (-?[0-9,]+\.\d{2})                  # 2009-Q3
                            """, re.VERBOSE)


    benefits_re = re.compile(r"""(\d{2}-\d{2})[\s\.]+           # date
                            (GL\sLAW|GL\sFRM|\w{2})[\s\.]+       # transaction code
                            ([0-9A-Z]+)[\s\.]+                  # record id
                            (.*?)                               # recipient
                            [\s\.]+                             # no dates
                            (.*?)[\s\.]+                        # description
                            (-?[0-9,]+\.\d{2})                  # amount
                            """, re.VERBOSE)


    year_re = re.compile(r"""(FISCAL YEAR\s+)?20([01]\d)\s+(\w+.*)\s*""")


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
'S8': 'equipment plan or maintenance provided through the CAO',

#less detailed codes, used for newer quarters :(
'AP': 'Accounts payable',
'AR': 'Accounts receivable', 
'GL': 'General ledger',
'GL LAW': 'charges for purchase of services for Public Law documentation',
'GL FRM': 'Interface charge for goods purchased through Framing Office'
 } 


    for l in f.readlines():

        # replace UTF-8 minus with normal dash and strip
        # replace smart quotes with regular quotes
        l = l.replace('–','-').replace('″', '"').replace('’', '\'').strip()
        

        # new member
        if year_re.match(l):
            if l.startswith("FISCAL YEAR "):
                thismem = l.replace('—', '')[17:]
                thisyear = l[:16]
            else:
                thismem = l.replace('—', '')[5:]
                thisyear = l[:4]
            if thismem.endswith("Con."):
                thismem = thismem[:-4]
            thismem = thismem.strip()
            thisyear = thisyear.strip()
            continue

        # category
        if l in cats:
            thiscat = l
            continue

        #regular record
        ma = regular_re.match(l)
        if ma:
            m = ma.groups()
            date1 = m[0]
            transcode = m[1]
            recordid = m[2]
            recip = m[3]
            sunrecip = recip
            if recip=='DO': #DO for 'Ditto last line' is not used in newer filings.
                sunrecip = oldrecip
            else:
                oldrecip = recip
            if sunrecip=='':
                sunrecip=recip
            date2 = m[4]
            date3 = m[5]
            descrip = m[6]
            amount = m[7]

            transcodelong = ''
            if transcode in transcodes:
                transcodelong = transcodes[transcode]


            fdetail.writerow([thismem, thisquarter, thiscat, date1, sunrecip, date2, date3, descrip, amount, thisyear, transcode, transcodelong, recordid, recip])
            continue

        # personnel record
        ma = personnel_re.match(l)
        if ma:
            m = ma.groups()
            recip = m[0]
            sunrecip = recip
            if recip=='DO': #DO for 'Ditto last line' is not used in newer filings.
                sunrecip = oldrecip
            else:
                oldrecip = recip
            date2 = m[1]
            date3 = m[2]
            descrip = m[3]
            amount = m[4]
            fdetail.writerow([thismem, thisquarter, thiscat, "", sunrecip, date2, date3, descrip, amount, thisyear, "","","", recip ])
            continue




        # benefits record
        ma = benefits_re.match(l)
        if ma:
            m = ma.groups()
            recip = m[3]
            sunrecip = recip
            if recip=='DO': #DO for 'Ditto last line' is not used in newer filings.
                sunrecip = oldrecip
            else:
                oldrecip = recip
            descrip = m[4]
            amount = m[5]
            date1 = m[0]
            transcode = m[1]
            recordid = m[2]
            transcodelong = ''
            if transcode in transcodes:
                transcodelong = transcodes[transcode]

            # benefits rows don't really have a recipient, this is to kludge around a hard-to-fix bug in benefits_re
            if thiscat == "PERSONNEL BENEFITS":
                descrip = ("%s %s" % (sunrecip, descrip)).strip() # leaves the space in if sunrecip had a value, strips it if not
                sunrecip = ""

            fdetail.writerow([thismem, thisquarter, thiscat, date1, sunrecip, "","", descrip, amount, thisyear, transcode,transcodelong,recordid, recip ])
            
            continue





        # summary record
        ma = summary_re.match(l)
        if ma:
            m = ma.groups()
            if m[0].strip() in cats:
                fsummary.writerow([thismem, thisyear, thisquarter, m[0].strip(), m[1], m[2]])
                continue

        if not known_bad(l):
            trashcan.write(l)

if __name__ == '__main__':
    infile = sys.argv[1]
    main(infile)
