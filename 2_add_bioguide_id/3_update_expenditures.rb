#!/usr/bin/env ruby

input_file = ARGV.first
bioguide_file = "bioguide_ids.csv"

if input_file.nil? or input_file == ""
  puts "Provide the filename of the disbursements CSV file you want to add the bioguide IDs to."
  exit
end

output_file = "#{File.basename input_file, ".csv"}-updated.csv"

require 'fileutils'
require 'rubygems'
require 'csv'

[input_file, bioguide_file].each do |f|
  unless File.exists?(f)
    puts "Couldn't locate #{f}. Place it in the same directory as this script."
    exit
  end
end

# Read through the bioguide ID CSV and create a hash of names to bioguide_ids

legislators = {}
CSV.foreach(bioguide_file, :encoding => 'windows-1251:utf-8') do |row|
  # key is name, value is bioguide_id
  if row[0] and row[0] != ""
    legislators[row[1]] = row[0]
  end
end

# open up a file for writing, and in it:
  # go through the expenditures CSV line by line and find the bioguide_id for each name and re-write it out


FileUtils.rm(output_file) if File.exist? output_file
CSV.open(output_file, "w") do |csv|
  i = 0

  CSV.foreach(input_file, :encoding => 'windows-1251:utf-8') do |row|
    if row[0] == "OFFICE" # header row
      row.unshift "BIOGUIDE_ID"
    else
      name = row[0]
      row.unshift legislators[name]
    end

    csv << row

    i += 1
    puts "Wrote #{i} rows..." if i % 50000 == 0
  end

end

puts ""
puts "Wrote out updated expenditure report to #{output_file}."
