#!/usr/bin/env ruby

# will find the unique original office names in positions.csv and append any unseen ones to the end of offices.csv

positions_file = "data/positions.csv"
offices_file = "data/offices.csv"

unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Place it in the same directory as this script."
  exit
end

unless File.exists?(offices_file)
  puts "Couldn't locate #{offices_file}. Place it in the same directory as this script."
  exit
end

require 'fileutils'
require 'csv'

offices = []

CSV.foreach(offices_file) do |row|
  next if row[0] == "OFFICE NAME (ORIGINAL)" # header row of offices.csv
  offices << row[0]
end

i = 0
CSV.open(offices_file, "a") do |csv|
  
  CSV.foreach(positions_file) do |row|
    next if row[0] == "STAFFER NAME (ORIGINAL)" # header row of positions.csv
    next if row[3] != nil and row[3] != "" # has a bioguide ID, we'll handle them separately
    next if offices.include?(row[4])
    
    csv << [row[4], row[4]]
    offices << row[4]
    i += 1
  end
end

puts "Appended #{i} new offices to #{offices_file}."