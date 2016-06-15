#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# Portions Copyright (C) 2014 Abingdon School
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
#  A script to load in the XML file which exports from iSAMS.
#

IMPORT_DIR = 'import'

IsamsField = Struct.new(:selector, :attr_name, :target_type)

module Creator
  def self.included(parent)
    parent.extend ClassMethods
    parent::REQUIRED_FIELDS.each do |field|
      attr_accessor field[:attr_name]
    end
  end

  #
  #  I could just call this function initialize, but give it a slightly
  #  different name so that the includer can add more processing before or
  #  after our work.
  #
  def do_initialize(entry)
    self.class::REQUIRED_FIELDS.each do |field|
      attr_name = field[:attr_name]
      if field[:selector] == "Id"
        #
        #  Special case.  This one comes through as an attribute and
        #  is always numeric.
        #
        self.send("#{attr_name}=", entry.attribute("Id").value.to_i)
      else
        contents = entry.at_css(field[:selector])
        if contents
          if field[:target_type] == :string
            self.send("#{attr_name}=", contents.text)
          else
            self.send("#{attr_name}=", contents.text.to_i)
          end
        else
          #
          #  For ease of processing, missing strings are taken as
          #  empty strings, but missing values are set as nil.
          #
          if field[:target_type] == :string
            self.send("#{attr_name}=", "")
          else
            self.send("#{attr_name}=", nil)
          end
        end
      end
    end
  end

  module ClassMethods
    def slurp(data)
      results = Array.new
      entries = data.css(self::SELECTOR)
      if entries && entries.size > 0
        entries.each do |entry|
          results << self.new(entry)
        end
      else
        puts "Unable to find entries using selector \"#{self::SELECTOR}\"."
      end
      results
    end
  end
end

class IS_Loader
  class IS_Staff
    SELECTOR = "HRManager CurrentStaff StaffMember"
    REQUIRED_FIELDS = [
      IsamsField["Id",                 :isams_id, :integer],
      IsamsField["PreviousMISId",      :sb_id,    :integer],
      IsamsField["Initials",           :initials, :string],
      IsamsField["Title",              :title,    :string],
      IsamsField["Forename",           :forename, :string],
      IsamsField["Surname",            :surname,  :string],
      IsamsField["SchoolEmailAddress", :email,    :string]
    ]

    include Creator

    def initialize(entry)
      do_initialize(entry)
    end

  end

  class IS_Pupil
    SELECTOR = "PupilManager CurrentPupils Pupil"
    REQUIRED_FIELDS = [
      IsamsField["Id",                 :isams_id, :integer],
      IsamsField["SchoolCode",         :sb_id,    :integer],
      IsamsField["Initials",           :initials, :string],
      IsamsField["Title",              :title,    :string],
      IsamsField["Forename",           :forename, :string],
      IsamsField["Surname",            :surname,  :string],
      IsamsField["EmailAddress",       :email,    :string]
    ]

    include Creator

    def initialize(entry)
      do_initialize(entry)
    end

  end

  def read_isams_data(options)
    data = Nokogiri::XML(File.open(Rails.root.join(IMPORT_DIR, "data.xml")))
    @staff =  IS_Staff.slurp(data)
    puts "Got #{staff.count} staff." if options.verbose
    @pupils = IS_Pupil.slurp(data)
    puts "Got #{pupils.count} pupils." if options.verbose
  end

  def do_staff
  end

  #
  #  Compare our list of pupils read from iSAMS with those currently
  #  held in Scheduler.  Update as appropriate.
  #
  def do_pupils
    if @pupils
    else
    end
  end

  def initialize(options)
    read_isams_data(options)
    yield self if block_given?
  end

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
    opts.banner = "Usage: importsb.rb [options]"

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

  IS_Loader.new(options) do |loader|
    unless options.just_initialise
      finished(options, "initialisation")
      loader.do_pupils
      finished(options, "pupils")
      loader.do_staff
      finished(options, "staff")
#      loader.do_locations
#      finished(options, "locations")
#      loader.do_tutorgroups
#      finished(options, "tutor groups")
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


