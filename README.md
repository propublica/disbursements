## Processing House Disbursements

This repository contains various scripts for manipulating the House's expenditure (disbursement) reports, published at [disbursements.house.gov](http://disbursements.house.gov).


### Process for parsing disbursements

1. When new disbursement reports are released, quarterly, download the latest "single volume" PDF for that quarter.

2. Chop that PDF off at either end so that it contains strictly pages reflecting actual disbursement records.

3. Extract the text from that PDF, and run it through the Python script in [1_pdf_to_csv/](1_pdf_to_csv) to generate CSVs.

4. Take the generated CSVs and run them through the Ruby scripts in [2_add_bioguide_id/](2_add_bioguide_id) to add a Bioguide ID column to those CSVs.

5. Publish them to Sunlight's [expenditure reports page](http://sunlightfoundation.com/projects/expenditures). Sunlight staff with appropriate access can publish the CSVs to Amazon S3 with `s3cmd put -P -m text/csv [*.csv] s3://assets.sunlightfoundation.com/expenditures/house/`, and update the page [through the Django CMS](http://sunlightfoundation.com/admin/pages/page/39/).

6. Take the **detail CSV only** and run it through the 4 Ruby scripts in [3_extract_staffers/](3_extract_staffers) to generate new CSVs of various staff records (`staffers.csv`, `titles.csv`, `offices.csv`, and `positions.csv`).

7. Take those four CSVs and load them into Sunlight's [House Staff Directory](http://staffers.sunlightfoundation.com/), using the [instructions at sunlightlabs/staffers](https://github.com/sunlightlabs/staffers).

We also save various versions of the data along the way in an internal Dropbox account.


## Public domain

This project is [dedicated to the public domain](LICENSE). As spelled out in [CONTRIBUTING](CONTRIBUTING.md):

> The project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](http://creativecommons.org/publicdomain/zero/1.0/).

> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
