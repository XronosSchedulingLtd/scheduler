#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'ostruct'
require 'csv'
require 'charlock_holmes'
require 'digest/md5'
require 'yaml'
require 'ri_cal'
#require 'ruby-prof'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

#
#  A script to load in the calendar files which come from the school's
#  legacy calendar system.
#

IMPORT_DIR = 'import'

class CalendarLoader

  def initialize(options)
    filename = Rails.root.join(IMPORT_DIR, "Abingdon.ics")
    raw_contents = File.read(filename)
    puts "raw_contents.size = #{raw_contents.size}"
    detection = CharlockHolmes::EncodingDetector.detect(raw_contents)
    utf8_encoded_raw_contents =
      CharlockHolmes::Converter.convert(raw_contents,
                                        detection[:encoding],
                                        'UTF-8')
    puts "utf8_encoded_raw_contents.size = #{utf8_encoded_raw_contents.size}"
    rawcalendars = RiCal.parse_string(utf8_encoded_raw_contents)
    puts "rawcalendars.size = #{rawcalendars.size}"
    puts "rawcalendars[0].events.size = #{rawcalendars[0].events.size}"
  end

end

begin
  options = OpenStruct.new
  options.verbose         = false
  options.just_initialise = false
  options.era             = nil
  options.start_date      = nil
  OptionParser.new do |opts|
    opts.banner = "Usage: importcal.rb [options]"

    opts.on("-i", "--initialise", "Initialise only") do |i|
      options.just_initialise = i
    end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end

    opts.on("-e", "--era [ERA NAME]",
            "Specify the era to load data into.") do |era|
      options.era = era
    end

    opts.on("-s", "--start [DATE]", Date,
            "Specify an over-riding start date",
            "for loading events.") do |date|
      options.start_date = date
    end

  end.parse!

  CalendarLoader.new(options) do |loader|
    unless options.just_initialise
      loader.update_db
    end
  end
rescue RuntimeError => e
  puts e
end


