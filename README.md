## Processing House Disbursements

This repository contains various scripts for manipulating the House's expenditure (disbursement) reports, published at [disbursements.house.gov](http://disbursements.house.gov).


### Process for parsing disbursements

1. When new disbursement reports are released, quarterly, download the latest "single volume" PDF for that quarter.

2. Chop that PDF off at either end so that it contains strictly pages reflecting actual disbursement records.

3. Extract the text from that PDF, and run it through the Python script in `process_new_release/1_parse_disbursements/`, [documented there](process_new_release/1_parse_disbursements), to generate CSVs.

4. Take the generated CSVs and run them through the Ruby scripts in `process_new_release/2_add_bioguide_id/`, [documented there](process_new_release/2_add_bioguide_id), to add a Bioguide ID column to those CSVs.

5. Publish them to Sunlight's [expenditure reports page](http://sunlightfoundation.com/projects/expenditures).

6. Take the published CSVs and run them through the Ruby scripts in `staffers/`, [documented there](staffers), to generate new CSVs of various staff records (`staffers.csv`, `titles.csv`, `offices.csv`, and `positions.csv`).

7. Take those four CSVs and load them into Sunlight's [House Staff Directory](http://staffers.sunlightfoundation.com/), using the [instructions at sunlightlabs/staffers](https://github.com/sunlightlabs/staffers).

We also save various versions of the data along the way in an internal Dropbox account.


### License

Currently [GPLv3](LICENSE).