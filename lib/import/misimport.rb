#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# Portions Copyright (C) 2014-16 Abingdon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'ostruct'
require 'yaml'
require 'nokogiri'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

#
#  The idea here is to make as much as possible of this program platform
#  agnostic.  It will define some data structures/classes, and it's then
#  up to the individual platform implementations to flesh them out.  Any
#  processing which is common between platforms should be shared.
#

#
#  Support files.
#
require_relative 'misimport/misrecord.rb'
require_relative 'misimport/misgroup.rb'
#
#  Actual identifiable database things.
#
require_relative 'misimport/mispupil.rb'
require_relative 'misimport/misstaff.rb'
require_relative 'misimport/mislocation.rb'
require_relative 'misimport/misloader.rb'
require_relative 'misimport/mistutorgroup.rb'

#
#  Now we actually access the database to discover what MIS is in use.
#  That will dictate what further files to include.
#
#  Note that at this stage we are still merely defining our classes.
#  Bringing in the actual data and instantiating the objects will
#  come later.
#

current_mis = Setting.current_mis
if current_mis
  if current_mis == "iSAMS"
    require_relative 'isams/misloader.rb'
    require_relative 'isams/creator.rb'
    require_relative 'isams/mispupil.rb'
    require_relative 'isams/misstaff.rb'
    require_relative 'isams/mislocation.rb'
    require_relative 'isams/mistutorgroup.rb'
  elsif current_mis == "SchoolBase"
  else
    raise "Don't know how to handle #{current_mis} as our current MIS."
  end
else
  raise "No current MIS configured - can't import."
end


def finished(options, stage)
  if options.do_timings
    puts "#{Time.now.strftime("%H:%M:%S")} finished #{stage}."
  end
end

begin
  options = OpenStruct.new
  options.verbose         = false
  options.full_load       = false
  options.just_initialise = false
  options.send_emails     = false
  options.do_timings      = false
  options.era             = nil
  options.start_date      = nil
  OptionParser.new do |opts|
    opts.banner = "Usage: misimport.rb [options]"

    opts.on("-i", "--initialise", "Initialise only") do |i|
      options.just_initialise = i
    end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end

    opts.on("-f", "--full",
            "Do a full load",
            "(as opposed to incremental.  Doesn't",
            "actually affect what gets loaded, but",
            "does affect when it's loaded from.)") do |f|
      options.full_load = f
    end

    opts.on("-e", "--era [ERA NAME]",
            "Specify the era to load data into.") do |era|
      options.era = era
    end

    opts.on("--email",
            "Generate e-mails about cover issues.") do |email|
      options.send_emails = email
    end

    opts.on("--timings",
            "Log the time at various stages in the processing.") do |timings|
      options.do_timings = timings
    end

    opts.on("-s", "--start [DATE]", Date,
            "Specify an over-riding start date",
            "for loading events.") do |date|
      options.start_date = date
    end

  end.parse!

  MIS_Loader.new(options) do |loader|
    unless options.just_initialise
      finished(options, "initialisation")
      loader.do_pupils
      finished(options, "pupils")
      loader.do_staff
      finished(options, "staff")
      loader.do_locations
      finished(options, "locations")
      loader.do_tutorgroups
      finished(options, "tutor groups")
#      loader.do_teachinggroups
#      finished(options, "teaching groups")
#      loader.do_timetable
#      finished(options, "timetable")
#      loader.do_cover
#      finished(options, "cover")
#      loader.do_other_half
#      finished(options, "other half")
#      loader.do_auto_groups
#      finished(options, "automatic groups")
#      loader.do_extra_groups
#      finished(options, "extra groups")
#      loader.do_duties
#      finished(options, "duties")
#      loader.do_taggroups
#      finished(options, "tagggroups")
    end
  end
rescue RuntimeError => e
  puts e
end


