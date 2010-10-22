#!/usr/bin/env ruby

input_file = ARGV.first
output_file = "expenditures-updated.csv"
bioguide_file = "bioguide_ids.csv"

if input_file.nil? or input_file == ""
  puts "Provide the filename of the disbursements CSV file you want to add the bioguide IDs to."
  exit
end


begin
  require 'fileutils'
  require 'rubygems'
  require 'fastercsv'
rescue
  puts "Couldn't load dependencies. Try running:\nsudo gem install fastercsv"
  exit
end

[input_file, bioguide_file].each do |f|
  unless File.exists?(f)
    puts "Couldn't locate #{f}. Place it in the same directory as this script."
    exit
  end
end

# Read through the bioguide ID CSV and create a hash of names to bioguide_ids

legislators = {}
FasterCSV.foreach(bioguide_file) do |row|
  # key is name, value is bioguide_id
  legislators[row[1]] = row[0]
end

# open up a file for writing, and in it:
  # go through the expenditures CSV line by line and find the bioguide_id for each name and re-write it out


FileUtils.rm(output_file) if File.exist? output_file
FasterCSV.open(output_file, "w") do |csv|
  i = 0
  
  FasterCSV.foreach(input_file) do |row|
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