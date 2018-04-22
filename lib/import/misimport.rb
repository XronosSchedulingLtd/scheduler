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
#  The following module must be implemented as school-specific code.
#
module MIS_Utils
  #
  #  Different schools refer to their year groups in different ways.
  #  Some use the National Curriculum year groups, "Year 9" etc.
  #  Others use the older "1st year", "2nd year" etc.
  #
  #  This method takes a numeric National Curriculum year and converts
  #  it to the local numeric value.
  #
  #  def local_yeargroup(nc_year)

  #
  #  And this one formats a local numeric value as text.
  #
  #    Year 9
  #    1st year
  #
  #  etc.
  #
  #  def local_yeargroup_text(yeargroup)

  #
  #  If a pupil is in National Curriculum year nc_year for the era
  #  indicated by era, then in what calendar year would he have started
  #  in the school's local idea of the first year?  Note - not the
  #  date at which he or she *did* start at the school, just what year
  #  would it have been if the start had been in local year 1.
  #
  # def local_effective_start_year(era, nc_year, ahead = 0)
  #

  #  We can potentially filter out incoming records by NC year.
  #  This is, for instance, used at Abingdon to filter out all
  #  pupils, tutor groups and teaching groups where the NC year
  #  number is greater than 20, indicating they belong to the prep
  #  school.
  #
  # def local_wanted(nc_year)
  #
  
  #
  #  And also filter out weeks.  This is more interesting and must be
  #  implemented in a school specific way.  Abingdon wants its two
  #  A and B weeks, but not the prep school week.
  #
  #  A and B weeks are loaded according to the schedule provided by
  #  iSAMS, but then extra local knowledge is needed to decide whether
  #  to load any others.
  #
  #  def local_week_load_regardless(week)

  UTILS_NEEDED = [
    :local_yeargroup,
    :local_yeargroup_text,
    :local_effective_start_year,
    :local_wanted,
    :local_week_load_regardless
  ]

  def utils_ok?
    result = true
    UTILS_NEEDED.each do |un|
      unless self.respond_to?(un)
        puts "A method #{un} must be defined to suit the current school"
        result = false
      end
    end
    result
  end
end

#
#  Support files.
#
require_relative 'misimport/options.rb'
require_relative 'misimport/misrecord.rb'
require_relative 'misimport/misgroup.rb'
require_relative 'misimport/misproperty.rb'
require_relative 'misimport/parserecurring.rb'

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
require_relative 'misimport/misohgroup.rb'
require_relative 'misimport/miscover.rb'
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
    require_relative 'isams/activitygroup.rb'
    require_relative 'isams/activitygrouppupillink.rb'
    require_relative 'isams/covermanagercover.rb'
    require_relative 'isams/misloader.rb'
    require_relative 'isams/creator.rb'
    require_relative 'isams/mispupil.rb'
    require_relative 'isams/misstaff.rb'
    require_relative 'isams/mislocation.rb'
    require_relative 'isams/mistutorgroup.rb'
    require_relative 'isams/misteachinggroup.rb'
    require_relative 'isams/miscustomgroup.rb'
    require_relative 'isams/mistimetable.rb'
    require_relative 'isams/misohgroup.rb'
    require_relative 'isams/mishouse.rb'
    require_relative 'isams/missubject.rb'
    require_relative 'isams/miscover.rb'
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
#puts "Running from #{File.dirname(__FILE__)}"
Dir[File.join(File.dirname(__FILE__), "school/*.rb")].each do |file|
#  puts "Requiring \"#{file}\"."
  #
  #  Need to use an absolute path, because otherwise if file happens to be
  #  something like "lib/import/school/banana.rb" then the load will fail.
  #
  require File.absolute_path(file)
end

def finished(options, stage)
  if options.do_timings
    puts "#{Time.now.strftime("%H:%M:%S")} finished #{stage}."
  end
end

class LocalTester
  include MIS_Utils
end

begin
  lt = LocalTester.new
  unless lt.utils_ok?
    exit
  end
  options = Options.new
  MIS_Loader.new(options) do |loader|
    unless options.just_initialise
      finished(options, "initialisation")
      if options.check_recurring
        loader.check_recurring
        finished(options, "checking recurring files")
      else
        loader.do_pupils
        finished(options, "pupils")
        loader.do_staff
        finished(options, "staff")
        #
        #  Arguably, subjects exist before staff, but the way we
        #  accumulate information in memory is to attach a list of
        #  staff to the subject record, and so it makes sense to
        #  load the subjects after the staff, setting up the d/b
        #  records connecting the two.
        #
        loader.do_subjects
        finished(options, "subjects")
        loader.do_locations
        finished(options, "locations")
        loader.do_tutorgroups
        finished(options, "tutor groups")
        loader.do_teachinggroups
        finished(options, "teaching groups")
        if options.activities
          loader.do_otherhalfgroups
          finished(options, "other half groups")
        end
        loader.do_timetable
        finished(options, "timetable")
        if options.cover
          loader.do_cover
          finished(options, "cover")
        end
        loader.do_auto_groups
        finished(options, "automatic groups")
        loader.do_extra_groups
        finished(options, "extra groups")
        loader.do_recurring_events
        finished(options, "recurring events")
        loader.do_customgroups
        finished(options, "customgroups")
      end
    end
  end
rescue RuntimeError => e
  puts "Got a run time error."
  puts e
end


