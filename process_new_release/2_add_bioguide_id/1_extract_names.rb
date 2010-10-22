#!/usr/bin/env ruby

filename = ARGV.first

if filename.nil? or filename == ""
  puts "Provide the filename of the CSV file with disbursement details as an argument."
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

unless File.exists?(filename)
  puts "Couldn't locate #{filename}. Place it in the same directory as this script."
  exit
end


puts "Reading #{filename} for names..."
names = {}
i = 0
FasterCSV.foreach(filename) do |row|
  name = row[0]
  names[name] ||= 0
  names[name] += 1
  
  i += 1
  puts "Read #{i} rows..." if i % 50000 == 0
end

FileUtils.rm("all-names.csv") if File.exist?("all-names.csv")
FasterCSV.open("all-names.csv", "w") do |csv|
  csv << ['name', 'num_rows']
  names.keys.sort.each do |key|
    csv << [key, names[key]]
  end
end
puts "Wrote names to all-names.csv."