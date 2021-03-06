### Bioguide ID Adder

This is a set of 3 scripts that will take the CSV that Sunlight prepares of the House expenditure reports, and attempt to match up all legislator names to bioguide IDs.

This adds a bioguide ID column to the CSV, for the purpose of making it easier to link expenditure reports to other information about a legislator.


### Requirements

Ruby 1.9+, and the `congress` gem.


### Assumptions

It assumes that all legislators in the CSV will have their names prepended with "HON." (with or without a space between "HON." and the rest of their name).  It also assumes that no non-legislators have name fields that begin with "HON.".  This will miss open seats, but for open seats there is no bioguide_id to link to, anyway.

It assumes that if there is a case of two identically named legislators (i.e. Mike Rogers in Q3 and Q4 of 2009), that the state will be noted in the name field in parentheses, i.e. "HON. MIKE ROGERS (MI)" and "HON. MIKE ROGERS (AL)".

**Note**: As of `2012Q3`, the Mike Rogers-es have been distinguished by middle initial, so this convention is *no longer necessary*. Old quarters will still work, however.


### Known Mistakes

Mary Bono Mack is mistaken for Connie Mack.  There's no easy way to correct this without hardcoding Mack into the code.  Make sure to correct this during step 4, unless the correction for this mistake is already safely cached in `bioguide_ids.csv`.


### Instructions

1. Place the expenditures CSV in this directory.  Open a terminal in this directory and run:

```bash
ruby 1_extract_names.rb [expenditures.csv]
```

Replace `[expenditures.csv]` with the name of the actual expenditures CSV file. Don't include the brackets.

2. This will produce a file called `all-names.csv`, containing a row with every unique name found in the name field of the expenditures CSV.

3. Assign Bioguide IDs to any newly extracted names:

```bash
ruby 2_assign_bioguide_ids.rb
```

As this runs, it will print out whenever it can't match a legislator to a bioguide ID, and when it's done it'll print a summary of how many legislators it failed to match.

This will use the existing `bioguide_ids.csv` as a cache of names it's seen before.

4. This will update `bioguide_ids.csv`, containing a row with every legislator's name, a bioguide ID,  and then two fields to help verify the work. The first (under the heading `name_confirm_from_sunlight`) is the full standardized name of the legislator, including their nickname, of the legislator that the script believed was the match.  The second is whether or not the legislator is currently in office ("TRUE") or not in office ("FALSE").

You need to look over this file and fill in the missing bioguide IDs for rows missing them.  They should be at the bottom. The output of the prior script should have said how many missing bioguide IDs there are.

You should also look for mistakes, such as if the two name columns obviously don't match, and replace the bioguide IDs manually.  Look in the "Known Mistakes" section above for any that you should expect to see.


5. For both the `-details` and `-summary` CSV files, run this command:

```bash
ruby 3_update_expenditures.rb [csv]
```

Where `[csv]"` is the actual expenditures CSV file, e.g. `2013Q4-details.csv`.

This will produce `[csv]-updated.csv`, e.g. `2013Q4-details-updated.csv`. It is a copy of the original expenditures CSV, with a bioguide ID column  prepended to the beginning of each row.


### Looking up Bioguide IDs

If you're a developer, the easiest way to find Bioguide IDs is by using the [Sunlight Congress API](http://sunlightlabs.github.io/congress/), using a wrapper tool, such as the "congress" Ruby gem.

If you're not, the easiest way is to visit http://bioguide.congress.gov and use the search feature to find the page for the legislator in question. Once there, look at the URL, it will look something like this:

```
http://bioguide.congress.gov/scripts/biodisplay.pl?index=Y000031
```

In this URL, the bioguide ID is at the very end, after the equals sign: `Y000031`.
