#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts the CSV Output from the Google Sheets Input Template to SciolyFF

require 'csv'
require 'date'
require 'yaml'

if ARGV.empty?
  puts 'needs a file to convert'
  exit 1
end

csv = CSV.read(ARGV.first)

tournament = {}
tournament['name']     = csv.first[0] unless csv.first[0].nil?
tournament['location'] = csv.first[1]
tournament['state']    = csv.first[2]
tournament['level']    = csv.first[3]
tournament['division'] = csv.first[4]
tournament['year']     = csv.first[5].to_i
tournament['date']     = Date.parse(csv.first[6])

events =
  csv[1].map.with_index do |event_name, i|
    event = {}
    event['name']    = event_name
    event['trial']   = true if csv[2][i] == 'Trial'
    event['trialed'] = true if csv[2][i] == 'Trialed'
    event
  end

teams =
  csv[3..102].take_while { |row| !row.first.nil? }.map do |row|
    team = {}
    team['number']              = row[0].to_i
    team['school']              = row[1]
    team['school abbreviation'] = row[2]
    team['suffix']              = row[3]
    team['city']                = row[4]
    team['state']               = row[5]
    team['subdivision']         = row[6]
    team['exhibition']          = true if row[7] == 'Yes'
    team['penalty points']      = row[8] # will be converted to penalty later
    team.reject { |_, v| v.nil? }
  end

placings =
  teams.map.with_index do |team, t_i|
    events.map.with_index do |event, e_i|
      placing = {}
      placing['team']  = team['number']
      placing['event'] = event['name']

      raw_place = csv[103..202][t_i][e_i]
      case raw_place
      when 'PO' then placing['participated'] = true # not strictly needed
      when 'NS' then placing['participated'] = false
      when 'DQ' then placing['disqualified'] = true
      when 'L'  then placing['low place']    = true # not yet supported
      else           placing['place']        = raw_place.to_i
      end
      placing
    end
  end.flatten

penalties =
  teams.map do |team|
    penalty = {}
    points = team.delete('penalty points')
    next if points.nil?

    penalty['team']   = team['number']
    penalty['points'] = points
    penalty
  end.compact

# Identify and fix placings that are just participations points
events.map { |e| e['name'] }.each do |event_name|
  last_place_placings = placings.select do |p|
    p['event'] == event_name &&
      p['place'] == teams.count
  end
  next if placings.find do |p|
            p['event'] == event_name && p['place'] == (teams.count - 1)
          end

  last_place_placings.each do |placing|
    placing.store('participated', true)
    placing.delete('place')
  end
end

rep = {}
rep['Tournament'] = tournament
rep['Events']     = events
rep['Teams']      = teams
rep['Placings']   = placings
rep['Penalties']  = penalties unless penalties.empty?

puts YAML.dump(rep)
