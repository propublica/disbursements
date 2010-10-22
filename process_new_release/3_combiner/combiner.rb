#!/usr/bin/env ruby

files = ARGV

if files.empty?
  puts "No files given."
  exit
end

if files.size == 1
  puts "Only one file given. Give at least 2."
  exit
end

missing = files.select {|f| !File.exists? f}
if missing.any?
  puts "missing files: #{missing.join ', '}"
  exit
end


begin
  require 'fileutils'
  require 'rubygems'
  require 'fastercsv'
rescue
  puts "Couldn't load dependencies. Try running two commands and try again:\n\nsudo gem install fastercsv"
  exit
end


out_file = "combined-#{files.first}" # first file keeps headers

FileUtils.rm(out_file) if File.exists? out_file
FasterCSV.open(out_file, "w") do |csv|
  files.each do |file|
    skipped_header = false
    
    puts "Processing #{file}..."
    FasterCSV.foreach(file) do |row|
      if (file != files.first) and !skipped_header
        puts "\tSkipped header for #{file}..."
        skipped_header = true
        next
      end
      
      csv << row
    end
  end
end