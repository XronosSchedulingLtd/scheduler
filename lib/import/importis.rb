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
  #  Default to true.  May well be over-ridden in the class.
  #
  def wanted
    true
  end

  #
  #  Likewise, may well be over-ridden.
  #
  def adjust
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
          rec = self.new(entry)
          rec.adjust
          if rec.wanted
            results << rec
          end
        end
      else
        puts "Unable to find entries using selector \"#{self::SELECTOR}\"."
      end
      results
    end
  end
end

module DatabaseAccess

  PRIMARY_DATA_SOURCE = "iSAMS"
  SECONDARY_DATA_SOURCE = "SchoolBase"

  #
  #  There's quite a bit of fun here setting up variables to be used
  #  later.  Some of them are to be instance variables, and thus can
  #  be set up only when the including class is instantiated.  It is
  #  thus done by hooking into that class's intialize method.
  #
  #  Others are to be class instance variables (not to be confused with
  #  class variables - which begin with @@ - and are now apparently out
  #  of fashion).  They can be set at the time we are included.
  #
  module Initializer
    def initialize options = {}
      @dbrecord = nil
      @belongs_to_era = nil
      @checked_dbrecord = false
      @element_id = nil
      super
    end

  end

  def self.included(base)
    base.send :prepend, Initializer
    base.instance_variable_set(
      "@primary_datasource_id",
       Datasource.find_by(name: PRIMARY_DATA_SOURCE).id)
    base.instance_variable_set(
      "@secondary_datasource_id",
       Datasource.find_by(name: SECONDARY_DATA_SOURCE).id)
  end

  #
  #  Compares selected fields in a database record and a memory record,
  #  and updates any which differ.  If anything is changed, then saves
  #  the record back to the database.  Gives the calling code a chance
  #  to add changes too.
  #
  def check_and_update(extras = nil)
    #
    #  For this first reference, we call the dbrecord method, rather than
    #  accessing the instance variable directly.  This is in order to cause
    #  it to be initialised if it isn't already.
    #
    return false unless dbrecord
    changed = false
    self.class.const_get(:FIELDS_TO_UPDATE).each do |field_name|
      if @dbrecord.send(field_name) != self.instance_variable_get("@#{field_name}")
        puts "Field #{field_name} differs for #{self.name}"
        puts "d/b: \"#{@dbrecord.send(field_name)}\" IS: \"#{self.instance_variable_get("@#{field_name}")}\""
#        @dbrecord[field_name] = self.instance_variable_get("@#{field_name}")
#                entry.send("#{attr_name}=", row[column_hash[attr_name]])
         @dbrecord.send("#{field_name}=",
                        self.instance_variable_get("@#{field_name}"))
        changed = true
      end
    end
    if extras
      #
      #  extras should be a hash of additional things to change.
      #
      extras.each do |key, value|
        dbvalue = @dbrecord.send("#{key}")
        if dbvalue != value
          puts "Field #{key} differs for #{self.name}"
          puts "d/b: \"#{dbvalue}\"  IS: \"#{value}\""
          @dbrecord.send("#{key}=", value)
          changed = true
        end
      end
    end
    if changed
      if @dbrecord.save
        true
      else
        puts "Failed to save #{self.class} record #{self.name}"
        false
      end
    else
      false
    end
  end

  def save_to_db(extras = nil)
    if dbrecord
      puts "Attempt to re-create d/b record of type #{self.class.const_get(:DB_CLASS)} for #{self.source_id}"
      false
    else
      newrecord = self.class.const_get(:DB_CLASS).new
      key_field = self.class.const_get(:DB_KEY_FIELD)
      if key_field.instance_of?(Array)
        key_field.each do |kf|
          newrecord.send("#{kf}=",
                         self.send("#{kf}"))
        end
      else
        newrecord.send("#{key_field}=",
                       self.send("#{key_field}"))
      end
      self.class.const_get(:FIELDS_TO_CREATE).each do |field_name|
         newrecord.send("#{field_name}=",
                        self.instance_variable_get("@#{field_name}"))
      end
      if extras
        extras.each do |key, value|
          newrecord.send("#{key}=", value)
        end
      end
      if newrecord.save
        newrecord.reload
        @dbrecord = newrecord
        @belongs_to_era = newrecord.respond_to?(:era)
        @checked_dbrecord = true
        true
      else
        puts "Failed to create d/b record of type #{self.class.const_get(:DB_CLASS)} for #{self.source_id}"
        false
      end
    end
  end

  def dbrecord
    #
    #  Don't keep checking the database if it isn't there.
    #
    unless @checked_dbrecord
      @checked_dbrecord = true
      db_class = self.class.const_get(:DB_CLASS)
      #
      #  Does this particular database record hang off an era?
      #
      @belongs_to_era = db_class.new.respond_to?(:era)
      key_field = self.class.const_get(:DB_KEY_FIELD)
      find_hash = Hash.new
      if key_field.instance_of?(Array)
        key_field.each do |kf|
          find_hash[kf] = self.send("#{kf}")
        end
      else
        if key_field == :source_id
          find_hash[:datasource_id] =
            self.class.instance_variable_get("@primary_datasource_id")
        end
        find_hash[key_field] = self.send("#{key_field}")
      end
      if @belongs_to_era
        find_hash[:era_id] = self.instance_variable_get("@era_id")
      end
#      puts "Trying: #{find_hash.inspect}"
      @dbrecord =
        db_class.find_by(find_hash)
      unless @dbrecord
        #
        #  Didn't find it that way.  It may be possible to do
        #  it a slightly different way.
        #
        if key_field == :source_id
          find_hash = Hash.new
          find_hash[:datasource_id] =
            self.class.instance_variable_get("@secondary_datasource_id")
          find_hash[key_field] = self.send("#{key_field}", true)
          if @belongs_to_era
            find_hash[:era_id] = self.instance_variable_get("@era_id")
          end
#          puts "Trying: #{find_hash.inspect}"
          @dbrecord =
            db_class.find_by(find_hash)
          if @dbrecord
            #
            #  To make things as transparent as possible to the
            #  calling code, we're going to fix this now.
            #
            @dbrecord.source_id = self.send("#{key_field}")
            @dbrecord.datasource_id =
              self.class.instance_variable_get("@primary_datasource_id")
            @dbrecord.save!
            @dbrecord.reload
          end
        end
      end
    end
    @dbrecord
  end

  #
  #  A defensive (and cached) way to get this item's element id.
  #
  def element_id
    unless @element_id
      dbr = dbrecord
      if dbr
        #
        #  Special processing needed for locations.
        #
        if dbr.class == Locationalias
          if dbr.location
            if dbr.location.element
              @element_id = dbr.location.element.id
            end
          end
        else
          if dbr.element
            @element_id = dbr.element.id
          end
        end
      end
    end
    @element_id
  end

end

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
    IsamsField["Id",                 :isams_id,  :integer],
    IsamsField["SchoolCode",         :sb_id,     :integer],
    IsamsField["Initials",           :initials,  :string],
    IsamsField["Title",              :title,     :string],
    IsamsField["Forename",           :forename,  :string],
    IsamsField["Surname",            :surname,   :string],
    IsamsField["EmailAddress",       :email,     :string],
    IsamsField["NCYear",             :nc_year,   :integer],
    IsamsField["Fullname",           :full_name, :string],
    IsamsField["Preferredname",      :known_as,  :string]
  ]

  DB_CLASS = Pupil
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current,
    :datasource_id
  ]

  FIELDS_TO_UPDATE = [
    :name,
    :surname,
    :forename,
    :known_as,
    :email,
    :current
  ]

  include Creator
  include DatabaseAccess

  attr_reader :name, :datasource_id

  def initialize(entry)
    do_initialize(entry)
    #
    #  These two are used if a new d/b record is created.
    #
    @current = true
    @datasource_id =
      self.class.instance_variable_get("@primary_datasource_id")
  end

  def adjust
    @email.downcase!
    @name = "#{@known_as} #{@surname}"
  end

  def wanted
    @nc_year && @nc_year < 20
  end

  def source_id(secondary = false)
    if secondary
      @sb_id
    else
      @isams_id
    end
  end

  #
  #  In what year would this pupil have started in the 1st year (NC year 7).
  #  Calculated from his current year group, plus the current academic
  #  year.
  #
  def effective_start_year(era)
    era.starts_on.year + 7 - self.nc_year
  end

end


class IS_Loader

  attr_reader :verbose, :full_load, :era, :send_emails

  def read_isams_data(options)
    data = Nokogiri::XML(File.open(Rails.root.join(IMPORT_DIR, "data.xml")))
    @staff =  IS_Staff.slurp(data)
    puts "Got #{@staff.count} staff." if options.verbose
    @pupils = IS_Pupil.slurp(data)
    puts "Got #{@pupils.count} pupils." if options.verbose
    @pupil_hash = Hash.new
    @pupils.each do |pupil|
      @pupil_hash[pupil.isams_id] = pupil
    end
  end

  def initialize(options)
    @verbose     = options.verbose
    @full_load   = options.full_load
    @send_emails = options.send_emails
    if options.era
      @era = Era.find_by_name(options.era)
      raise "Era #{options.era} not found in d/b." unless @era
    else
      @era = Setting.current_era
      raise "Current era not set." unless @era
    end
    raise "Perpetual era not set." unless Setting.perpetual_era
    read_isams_data(options)
    yield self if block_given?
  end

  def do_staff
  end

  #
  #  Compare our list of pupils read from iSAMS with those currently
  #  held in Scheduler.  Update as appropriate.
  #
  def do_pupils
    pupils_changed_count   = 0
    pupils_unchanged_count = 0
    pupils_loaded_count    = 0
    original_pupil_count = Pupil.current.count
    @pupils.each do |pupil|
      dbrecord = pupil.dbrecord
      unless dbrecord.current
        puts "Pupil #{dbrecord.name} does not seem to be current."
      end
      if dbrecord
        if pupil.check_and_update({start_year: pupil.effective_start_year(@era)})
          pupils_changed_count += 1
        else
          pupils_unchanged_count += 1
        end
      else
        if pupil.save_to_db({start_year: pupil.effective_start_year(@era)})
          pupils_loaded_count += 1
        end
      end
    end
    #
    #  Need to check for pupils who have now left.
    #
    pupils_left_count = 0
    Pupil.current.each do |dbpupil|
      pupil = @pupil_hash[dbpupil.source_id]
      unless pupil && dbpupil.datasource_id == pupil.datasource_id
        dbpupil.current = false
        dbpupil.save!
        pupils_left_count += 1
      end
    end
    final_pupil_count = Pupil.current.count
    if @verbose || pupils_changed_count > 0
      puts "#{pupils_changed_count} pupil record(s) amended."
    end
    if @verbose || pupils_loaded_count > 0
      puts "#{pupils_loaded_count} pupil record(s) created."
    end
    if @verbose || pupils_left_count > 0
      puts "#{pupils_left_count} pupil record(s) marked as left."
    end
    if @verbose
      puts "#{pupils_unchanged_count} pupil record(s) untouched."
    end
    if @verbose || original_pupil_count != final_pupil_count
      puts "Started with #{original_pupil_count} current pupils and finished with #{final_pupil_count}."
    end
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
    opts.banner = "Usage: importis.rb [options]"

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


