#!/usr/bin/env ruby
# frozen_string_literal: true

# Given a SciolyFF file, modifiy it so that all places including and after the
# given place are shifted down by one.
#
# Used in manually adding exhibition teams.

require 'yaml'

if ARGV.size != 3
  puts 'needs a file to modify, and an event and place to shift'
  exit 1
end

file = File.read(ARGV[0])
event = ARGV[1]
place = ARGV[2].to_i

rep = YAML.load(file)
rep['Placings'].map! do |placing|
  if placing['event'] == event &&
     placing['place'] &&
     placing['place'] >= place
    placing['place'] += 1
  end
  placing
end

puts YAML.dump(rep)
