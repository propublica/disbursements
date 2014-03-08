
## normalization-candidates.py <path-to-disbursement-csv>

Read the disbursement CSV and generate a list of payee names that have not been standardized. For each name, generate a simple normalization and a normalization using metaphone. A fourth column, payee_standardized, has been added to help in the manual process of normalization. It is populated with the raw value of payees. Reviewers can replace this value with the correct name if the payee name is incorrect.

This script requires normalization_mapping-<year>.csv and normalized_payees-<year>.csv to ensure that the normalization candidate list only contains names that have not been corrected or approved in previous years.

The CSV is written to stdout.


## normalize-payee.py <path-to-disbursement-csv>

This script takes a disbursement CSV and generates a new CSV with the corrected payee names as found in normalization_mapping-<year>.csv. The resulting CSV has an additional PAYEE_NORM field added that contains the original name or the normalized name if the it has been changed. Additionally:

* duplicate records are removed
* BIOGUIDE_ID fields are renamed and fixed
* records where PAYEE == 'DO' are updated with the last actual PAYEE

The CSV is written to stdout.


## data files

normalization_mapping-<year>.csv
    A mapping of messy names to correct names

normalized_payees-<year>.csv
    A full list of names that are either approved as-is or that have been corrected