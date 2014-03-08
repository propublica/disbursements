## Disbursement Converter

Converts House Disbursement PDFs into detail and summary CSV files.

Source PDFs: http://disbursements.house.gov/
Resulting Data: https://sunlightfoundation.com/projects/expenditures/

Originally authored by [Luke Rosiak](https://github.com/lukerosiak) with improvements by [James Turk](https://github.com/jamesturk) for the [Sunlight Foundation](https://sunlightfoundation.com).


### Use

1. Visit [disbursements.house.gov](http://disbursements.house.gov) and download a single volume PDF like this one:

> http://disbursements.house.gov/2013q4/2013q4_singlevolume.pdf

2. Take a single volume PDF and cut it to just the disbursement pages:

```
pdftk 2010q1_singlevolume.pdf cat 9-2342 output 2013q4-disbursements-only.pdf
```

3. Extract the text from this disbursements-only PDF:

```
pdftotext -layout 2013q4-disbursements-only.pdf
```

4. Run this script on that text file:

```
python parse-disbursements.py 2013q4-disbursements-only.txt
```

This script depends on the `.txt` filename's first six characters representing the quarter it covers.