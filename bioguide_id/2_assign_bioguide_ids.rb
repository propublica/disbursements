#!/usr/bin/env ruby

filename = ARGV.first

if filename.nil? or filename == ""
  filename = "all-names.csv"
end

known_bioguide_ids = "bioguide_ids.csv"
new_bioguide_ids = "new_bioguide_ids.csv"

begin
  require 'fileutils'
  require 'rubygems'
  require 'sunlight'
  require 'fastercsv'
  require 'active_support'
rescue
  puts "Couldn't load dependencies. Try running two commands and try again:\n\nsudo gem install fastercsv\nsudo gem install sunlight"
  exit
end

unless File.exists?(filename)
  puts "Couldn't locate #{filename}. Place it in the same directory as this script."
  exit
end

@@misses = 0
@@duplicates = 0
Sunlight::Base.api_key = 'sunlight9'

# index by name to known bioguide_id
@@known_bioguide_ids = {}
FasterCSV.foreach(known_bioguide_ids) do |row|
  next if row[0] == 'bioguide_id' # skip header row
  
  if row[0] and row[0] != "" and row[1] and row[1] != ""# bioguide_id
    @@known_bioguide_ids[row[1]] = {
      :bioguide_id => row[0],
      :name_confirm_from_sunlight => row[1],
      :in_office => (row[2] and (row[2] == "true"))
    }
  end
end


def legislator_for_name(name)
  options = {}
  
  if @@known_bioguide_ids[name]
    return @@known_bioguide_ids[name]
  end
  
  puts "Couldn't find #{name} cached, checking with the Sunlight Labs Congress API..."
  
  # get rid of "HON." prefix and split on spaces
  name = name.gsub /^HON\.\s?/i, ''
  pieces = name.split /\s+/
  
  # might be a state in parentheses at the end
  options[:state] = pieces.pop.gsub(/[\(\)]/, '') if pieces.last =~ /^\([a-zA-Z]+\)$/

  # might be a suffix at the end
  options[:name_suffix] = "#{pieces.pop.gsub(/\./, '')}." if pieces.last =~ /^Jr\.?$/i
  options[:name_suffix] = pieces.pop if pieces.last =~ /^I+$/i
  
  options[:lastname] = pieces.pop.gsub /,/, ''
  
  options[:firstname] = pieces.first
  
  results = Sunlight::Legislator.all_where options
  if results.size == 1
    results.first
  
  # no result, could be either the wrong first name, or out of office
  elsif results.size == 0
    # try the name as a nickname first
    options[:nickname] = options.delete :firstname 
    
    results = Sunlight::Legislator.all_where options
    if results.size == 1
      results.first
      
    # must be out of office then?
    elsif results.size == 0
      options[:in_office] = 0
      
      # reset to doing firstname first
      options[:firstname] = options.delete :nickname
      
      results = Sunlight::Legislator.all_where options
      if results.size == 1
        results.first
        
      elsif results.size == 0
        # try as nickname again, this time out of office
        options[:nickname] = options.delete :firstname
        
        results = Sunlight::Legislator.all_where options
        if results.size == 1
          results.first
        
        # OK, we'll accept a result if it matches on last name only, 
        # but only if there's only one result amongst both in and out of office legislators
        elsif results.size == 0
          options.delete :nickname
          options.delete :firstname
          
          if legislator = unique_for(options)
            legislator
            
          else
            # finally, try the combo last name
            options[:lastname] = "#{pieces.pop} #{options[:lastname]}"
            
            if legislator = unique_for(options)
              legislator
              
            else
              @@misses += 1
              puts "I GIVE UP. Couldn't match on options: #{options.merge(:pieces => pieces).inspect}"
            end
          end
          
        elsif results.size > 0
          @@duplicates += 1
          puts "Duplicates for options: #{options.inspect}"
        end
        
      elsif results.size > 0
        @@duplicates += 1
        puts "Duplicates for options: #{options.inspect}"
      end
        
    elsif results.size > 0
      @@duplicates += 1
      puts "Duplicates for options: #{options.inspect}"
    end
    
  # duplicate first name and last name of in-office legislator
  elsif results.size > 0
    @@duplicates += 1
    puts "Duplicates for options: #{options.inspect}"
  end
  
end


# need a unique result or nothing, across both in and out of office legislators, for the given options
# this is done for last name only checks
def unique_for(options)
  options[:in_office] = 1
  in_results = Sunlight::Legislator.all_where options
  return nil if in_results.size > 1
  
  options[:in_office] = 0
  out_results = Sunlight::Legislator.all_where options
  
  if in_results.size == 1 and out_results.size == 0
    in_results.first
  elsif in_results.size == 0 and out_results.size == 1
    out_results.first
  else
    nil
  end
end

def name_for(legislator)
  nickname = legislator.nickname && legislator.nickname != "" ? " \'#{legislator.nickname}\'" : ""
  firstname = "#{legislator.firstname}#{nickname}"
  lastname = legislator.name_suffix && legislator.name_suffix != "" ? "#{legislator.lastname} #{legislator.name_suffix}" : legislator.lastname
  
  "#{legislator.title}. #{firstname} #{lastname}".upcase
end


puts "Trying to match up names in #{filename}..."

names = {}
FasterCSV.foreach(filename) do |row|
  name = row[0]
  
  # Members' names will always start with "HON."
  if name =~ /HON\./
    names[name] = {}
    
    legislator = legislator_for_name(name)
    if legislator
      if legislator.is_a? Sunlight::Legislator
        names[name][:bioguide_id] = legislator.bioguide_id
        names[name][:name_confirm_from_sunlight] = name_for legislator
        names[name][:in_office] = legislator.in_office
      elsif legislator.is_a? Hash
        names[name][:bioguide_id] = legislator[:bioguide_id]
        names[name][:name_confirm_from_sunlight] = legislator[:name_confirm_from_sunlight]
        names[name][:in_office] = legislator[:in_office]
      end
    end
  end
end

FileUtils.rm(new_bioguide_ids) if File.exist? new_bioguide_ids
FasterCSV.open(new_bioguide_ids, "w") do |csv|
  csv << ['bioguide_id', 'name_original', 'name_confirm_from_sunlight', 'in_office']
  names.each do |name, values|
    csv << [values[:bioguide_id], name, values[:name_confirm_from_sunlight], values[:in_office]]
  end
end

puts ""
puts "Out of #{names.keys.size} names:"
puts "#{@@misses} attempts failed to match a legislator entirely."
puts "#{@@duplicates} attempts matched too many legislators."
puts ""
puts "Wrote names and bioguide IDs out to #{new_bioguide_ids}."