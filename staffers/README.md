This directory scripts to compile House disbursments data, for a separate project, a [searchable directory of House staffers](http://staffers.sunlightfoundation.com/).  The code for that staff directory is separate, at [sunlightlabs/staffers](/sunlightlabs/staffers).

This process produces 4 CSV files: `positions.csv`, `staffers.csv`, `offices.csv`, and `titles.csv`.

1) Create a "data" folder in this directory, if it does not exist. If you are updating **existing** staffers data, place the most current version of those data files into a folder in this directory named "data".

3) Run each disbursements detail file for *new quarters only* through `1_positions.rb`. If you are updating **existing** staffers data, this will just be the most recent quarter. If you are starting from scratch, run each details file through `1_positions.rb` in turn.

  ./1_positions.rb [details-filename.csv]

This will blindly append *all* new staff records from the details file (where the category is "PERSONNEL COMPENSATION") to positions.csv.

3) Run `2_staffers.rb`. This will extract unique new staffer names from positions.csv (that don't yet appear in staffers.csv), and append them to staffers.csv.

4) Run `3_offices.rb`. This will extract unique new office names from positions.csv (that don't yet appear in offices.csv, and aren't member offices), and append them to offices.csv.

5) Run `4_titles.rb`. This will extract all unique new titles from positions.csv (that don't yet appear in titles.csv), and append them to titles.csv.