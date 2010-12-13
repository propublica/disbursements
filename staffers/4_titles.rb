#!/usr/bin/env ruby

# will find the unique original titles in positions.csv and append any unseen ones to the end of titles.csv

positions_file = "data/positions.csv"
titles_file = "data/titles.csv"

unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Place it in the same directory as this script."
  exit
end

unless File.exists?(titles_file)
  puts "Couldn't locate #{titles_file}. Place it in the same directory as this script."
  exit
end

begin
  require 'fileutils'
  require 'rubygems'
  require 'fastercsv'
rescue
  puts "Couldn't load FasterCSV. Try running \"sudo gem install fastercsv\" and try again."
  exit
end

titles = []

FasterCSV.foreach(titles_file) do |row|
  next if row[0] == "TITLE (ORIGINAL)" # header row in titles.csv
  titles << row[0]
end

t = 0
p = 0
FasterCSV.open(titles_file, "a") do |csv|
  
  FasterCSV.foreach(positions_file) do |row|
    next if row[0] == "STAFFER NAME (ORIGINAL)" # header row in positions.csv
    
    title = row[1] # original title
    puts title if title == "ASST. COMM DIR AND CONST LIAISON"
    
    next if titles.include?(title)
    
    # split up any ' AND ' titles, unless we specifically list them to be standardized 
    # (in which case they just got skipped in the second 'next' line above)
    if title =~ /\ ?\/\ ?/
      pieces = title.split(/\ ?\/\ ?/)
    elsif title =~ / AND /
      pieces = title.split(/ AND /)
    else
      pieces = [title]
    end
    
    pieces.each do |piece|
      csv << [title, piece]
      p += 1
    end
    
    titles << title
    t += 1
  end
end

puts "Appended #{p} new titles (from #{t} original unique titles) to #{titles_file}."