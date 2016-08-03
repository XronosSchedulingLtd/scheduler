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
require_relative 'misimport/options.rb'
require_relative 'misimport/misrecord.rb'
require_relative 'misimport/misgroup.rb'
#
#  Actual identifiable database things.
#
require_relative 'misimport/hiatus.rb'
require_relative 'misimport/mispupil.rb'
require_relative 'misimport/misstaff.rb'
require_relative 'misimport/mislocation.rb'
require_relative 'misimport/misloader.rb'
require_relative 'misimport/mistutorgroup.rb'
require_relative 'misimport/misteachinggroup.rb'
require_relative 'misimport/miscustomgroup.rb'
require_relative 'misimport/mistimetable.rb'
#
#  Not actually database.
#
require_relative 'misimport/mishouse.rb'
require_relative 'misimport/missubject.rb'

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
    require_relative 'isams/dateextra.rb'
    require_relative 'isams/options.rb'
    require_relative 'isams/slurper.rb'
    require_relative 'isams/depender.rb'
    require_relative 'isams/activityevent.rb'
    require_relative 'isams/activityeventoccurrence.rb'
    require_relative 'isams/activityeventteacherlink.rb'
    require_relative 'isams/misloader.rb'
    require_relative 'isams/creator.rb'
    require_relative 'isams/mispupil.rb'
    require_relative 'isams/misstaff.rb'
    require_relative 'isams/mislocation.rb'
    require_relative 'isams/mistutorgroup.rb'
    require_relative 'isams/misteachinggroup.rb'
    require_relative 'isams/miscustomgroup.rb'
    require_relative 'isams/mistimetable.rb'
    require_relative 'isams/mishouse.rb'
    require_relative 'isams/missubject.rb'
  elsif current_mis == "SchoolBase"
  else
    raise "Don't know how to handle #{current_mis} as our current MIS."
  end
else
  raise "No current MIS configured - can't import."
end

#
#  And finally allow for school-specific adjustments.
#
Dir["school/*.rb"].each do |file|
  require_relative file
end

def finished(options, stage)
  if options.do_timings
    puts "#{Time.now.strftime("%H:%M:%S")} finished #{stage}."
  end
end

begin
  options = Options.new
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
      loader.do_teachinggroups
      finished(options, "teaching groups")
      loader.do_timetable
      finished(options, "timetable")
#      loader.do_cover
#      finished(options, "cover")
#      loader.do_other_half
#      finished(options, "other half")
      loader.do_auto_groups
      finished(options, "automatic groups")
      loader.do_extra_groups
      finished(options, "extra groups")
      loader.do_duties
      finished(options, "duties")
      loader.do_customgroups
      finished(options, "customgroups")
    end
  end
rescue RuntimeError => e
  puts e
end


