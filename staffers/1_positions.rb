#!/usr/bin/env ruby

input_file = ARGV.first

# will append blindly to positions.csv
positions_file = "data/positions.csv"

if input_file.nil? or input_file == ""
  puts "Provide the input_file of the CSV file with disbursement details as an argument."
  exit
end

unless File.exists?(input_file)
  puts "Couldn't locate #{input_file}. Place it in the same directory as this script."
  exit
end

unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Place it in the same directory as this script."
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


i = 0

FasterCSV.open(positions_file, "a") do |positions|
    
  FasterCSV.foreach(input_file) do |row|
    category = row[3]
    
    if category.upcase == 'PERSONNEL COMPENSATION'
      name = row[5] ? row[5].strip : ''
      title = row[8] ? row[8].strip : ''
      quarter = row[2] ? row[2].strip : ''
      bioguide_id = row[0] ? row[0].strip : ''
      office_name = row[1] ? row[1].strip : ''
      
      if title.any?
        positions << [name, title, quarter, bioguide_id, office_name]
      else
        puts "[#{i}] No title for #{name}, skipping"
      end
      
      i += 1
      puts "Read #{i} rows..." if i % 50000 == 0
    end
  end
  
end

puts "Finished appending #{i} new staffer position records from #{input_file} to #{positions_file}."