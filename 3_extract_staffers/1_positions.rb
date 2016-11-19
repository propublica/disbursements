#!/usr/bin/env ruby

input_file = ARGV.first

# will append blindly to positions.csv
positions_file = "data/positions.csv"

require 'fileutils'
FileUtils.mkdir_p "data"

if input_file.nil? or input_file == ""
  puts "Provide the input_file of the CSV file with disbursement details as an argument."
  exit
end

unless File.exists?(input_file)
  puts "Couldn't locate #{input_file}."
  exit
end

unless File.exists?(positions_file)
  puts "Couldn't locate #{positions_file}. Creating one now."
  system "touch #{positions_file}"
end

require 'csv'

i = 0

CSV.open(positions_file, "a") do |positions|

  CSV.foreach(input_file) do |row|
    category = row[3]

    if category.upcase == 'PERSONNEL COMPENSATION'
      name = row[5] ? row[5].strip : ''
      title = row[8] ? row[8].strip : ''
      quarter = row[2] ? row[2].strip : ''
      bioguide_id = row[0] ? row[0].strip : ''
      office_name = row[1] ? row[1].strip : ''

      office_name = office_name.gsub('--','')

      if title.size > 0
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
