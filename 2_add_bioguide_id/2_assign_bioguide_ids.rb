#!/usr/bin/env ruby

names_file = ARGV.first

if names_file.nil? or names_file == ""
  names_file = "all-names.csv"
end

bioguide_file = "bioguide_ids.csv"

require 'fileutils'
require 'rubygems'
require 'csv'

unless File.exists?(names_file)
  puts "Couldn't locate #{names_file}. Place it in the same directory as this script."
  exit
end

@misses = 0
@missed_names = []

@duplicates = 0
#@congress_client = Congress::Client.new('sunlight9')

# index by name to known bioguide_id
@known_bioguide_ids = {}
CSV.foreach(bioguide_file, :encoding => 'windows-1251:utf-8') do |row|
  next if row[0] == 'bioguide_id' # skip header row

  if row[0] and row[0] != "" and row[1] and row[1] != ""# bioguide_id
    @known_bioguide_ids[row[1]] = {
      bioguide_id: row[0],
      name_confirm_from_sunlight: row[1],
      in_office: (row[2] and (row[2] == "true"))
    }
  end
end

def legislators_for(options)
  #puts "\tAsking for legislators with options:\n\t\t#{options.inspect}"
  #results = @congress_client.legislators(options).results
  #puts "\tGot #{results.size} results"
  #results
end

def capitalize(name)
  return name if name.nil?

  new_name = name.downcase.capitalize

  # handle "Mc" and "Mac" cases
  new_name = new_name.sub(/^(Ma?c)(\w)/) {$1 + $2.capitalize}

  new_name
end

def legislator_for_name(name)
  options = {}

  puts "Couldn't find #{name} cached, checking with the Sunlight Labs Congress API..."

  # get rid of "HON." prefix and split on spaces
  pieces = name.gsub(/201\d HON\.\s?/i, '').gsub('--','').split /\s+/

  # might be a state in parentheses at the end
  options[:state] = pieces.pop.gsub(/[\(\)]/, '') if pieces.last =~ /^\([a-zA-Z]+\)$/

  # might be a suffix at the end
  options[:name_suffix] = "#{pieces.pop.gsub(/\./, '')}." if pieces.last =~ /^Jr\.?$/i
  options[:name_suffix] = pieces.pop if pieces.last =~ /^I+$/i

  options[:last_name] = pieces.pop.gsub /,/, ''
  options[:first_name] = pieces.first

  [:name_suffix, :last_name, :first_name].each do |field|
    options[field] = capitalize options[field]
  end

  # may try later
  alt_last_name = capitalize pieces.pop

  results = legislators_for options

  if results

    if results.size == 1
      results.first

    # no result, could be either the wrong first name, or out of office
    elsif results.size == 0
      # try the name as a nickname first
      options[:nickname] = options.delete :first_name

      results = legislators_for options
      if results.size == 1
        results.first

      # must be out of office then?
      elsif results.size == 0
        options[:in_office] = true

        # reset to doing firstname first
        options[:first_name] = options.delete :nickname

        results = legislators_for options
        if results.size == 1
          results.first

        elsif results.size == 0
          # try as nickname again, this time out of office
          options[:nickname] = options.delete :first_name

          results = legislators_for options
          if results.size == 1
            results.first

          # OK, we'll accept a result if it matches on last name only,
          # but only if there's only one result amongst both in and out of office legislators
          elsif results.size == 0
            options.delete :nickname
            options.delete :first_name

            if legislator = unique_for(options)
              legislator

            else
              # finally, try the combo last name
              options[:last_name] = "#{alt_last_name} #{options[:last_name]}"

              if legislator = unique_for(options)
                legislator

              else
                @misses += 1
                puts "I GIVE UP. Couldn't match on options: #{options.merge(pieces: pieces).inspect}"
                @missed_names << name
                puts "Added name to bottom of bioguide_ids.csv WITHOUT a bioguide_id, match by hand"
              end
            end

          elsif results.size > 0
            @duplicates += 1
            puts "Duplicates for options: #{options.inspect}"
          end

        elsif results.size > 0
          @duplicates += 1
          puts "Duplicates for options: #{options.inspect}"
        end

      elsif results.size > 0
        @duplicates += 1
        puts "Duplicates for options: #{options.inspect}"
      end

    # duplicate first name and last name of in-office legislator
      elsif results.size > 0
        @duplicates += 1
        puts "Duplicates for options: #{options.inspect}"
      end
    else
      @misses += 1
      puts "I GIVE UP. Couldn't match on options: #{options.merge(pieces: pieces).inspect}"
      @missed_names << name
      puts "Added name to bottom of bioguide_ids.csv WITHOUT a bioguide_id, match by hand"
    end
end


# need a unique result or nothing, across both in and out of office legislators, for the given options
# this is done for last name only checks
def unique_for(options)
  options[:in_office] = true
  in_results = legislators_for options
  return nil if in_results.size > 1

  options[:in_office] = false
  out_results = legislators_for options

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
  first_name = "#{legislator.first_name}#{nickname}"
  last_name = legislator.name_suffix && legislator.name_suffix != "" ? "#{legislator.last_name} #{legislator.name_suffix}" : legislator.last_name

  "#{legislator.title}. #{first_name} #{last_name}".upcase
end


puts "Trying to match up names in #{names_file}..."

names = {}
CSV.foreach(names_file, :encoding => 'windows-1251:utf-8') do |row|
  name = row[0]
#  name.gsub("2016 ","").gsub("2017 ","")

  # Members' names will always start with "HON."
  if name =~ /201\d HON\./


    if legislator = @known_bioguide_ids[name.gsub('--','')]
      # do nothing, we have it in bioguide_ids.csv already
      # names[name][:bioguide_id] = legislator[:bioguide_id]
      # names[name][:name_confirm_from_sunlight] = legislator[:name_confirm_from_sunlight]
      # names[name][:in_office] = legislator[:in_office]

    elsif legislator = legislator_for_name(name)
      names[name] = {
        bioguide_id: legislator.bioguide_id,
        name_confirm_from_sunlight: name_for(legislator),
        in_office: legislator.in_office
      }
    end
  end
end


CSV.open(bioguide_file, "a") do |csv|
  names.each do |name, values|
    csv << [values[:bioguide_id], name, values[:name_confirm_from_sunlight], values[:in_office]]
  end

  @missed_names.uniq.each do |name|
    csv << [nil, name, nil]
  end
end

puts ""
puts "Out of #{names.keys.size} names:"
puts "#{@misses} attempts failed to match a legislator entirely, requires manual matching."
puts "#{@duplicates} attempts matched too many legislators."
puts ""
puts "Appended any new names and bioguide IDs to #{bioguide_file}."
