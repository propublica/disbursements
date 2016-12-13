#!/usr/bin/env ruby

# will find the unique original staffer names in positions.csv and append any unseen ones to the end of staffers.csv

positions_file = "data/positions.csv"
staffers_file = "data/staffers.csv"


unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Run 1_positions.rb first to make one."
  exit
end

unless File.exists?(staffers_file)
  puts "Couldn't locate #{staffers_file}. Creating a blank one."
  system "touch #{staffers_file}"
end

require 'fileutils'
require 'csv'

staffers = []

CSV.foreach(staffers_file) do |row|
  next if row[0] == "STAFFER NAME (ORIGINAL)"
  staffers << row[0]
end

i = 0
CSV.open(staffers_file, "a") do |csv|

  CSV.foreach(positions_file) do |row|
    next if row[0] == "STAFFER NAME (ORIGINAL)"
    next if staffers.include?(row[0])

    csv << [row[0], row[0]]
    staffers << row[0]
    i += 1
  end
end

puts "Appended #{i} new staffers to #{staffers_file}."
