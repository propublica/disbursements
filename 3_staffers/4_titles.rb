#!/usr/bin/env ruby

# will find the unique original titles in positions.csv and append any unseen ones to the end of titles.csv

positions_file = "data/positions.csv"
titles_file = "data/titles.csv"

unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Run 1_positions.rb first to make one."
  exit
end

unless File.exists?(titles_file)
  puts "Couldn't locate #{titles_file}. Creating one now."
  system "touch #{titles_file}"
end

require 'fileutils'
require 'csv'

titles = []

CSV.foreach(titles_file) do |row|
  next if row[0] == "TITLE (ORIGINAL)" # header row in titles.csv
  titles << row[0]
end

i = 0
CSV.open(titles_file, "a") do |csv|
  
  CSV.foreach(positions_file) do |row|
    next if row[0] == "STAFFER NAME (ORIGINAL)" # header row in positions.csv
    row[1] ||= ""
    
    # strip off common addendums
    ["(OTHER COMPENSATION)", "(OVERTIME)"].each do |addendum|
      row[1].sub! addendum, ''
    end
    row[1].strip!
    
    next if titles.include?(row[1])
    
    csv << [row[1], '']
    titles << row[1]
    i += 1
  end
end

puts "Appended #{i} new titles to #{titles_file}."