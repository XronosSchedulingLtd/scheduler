#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# Portions Copyright (C) 2014 Abingdon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'optparse'
require 'optparse/date'
require 'ostruct'
require 'csv'
require 'charlock_holmes'
require 'digest/md5'
require 'yaml'
#require 'ruby-prof'

#
#  The following line means I can just run this as a Ruby script, rather
#  than having to do "rails r <script name>"
#
require_relative '../../config/environment'

#
#  A script to load in the CSV files which I've exported from SchoolBase.
#
#  We could really do with some sort of run-time flag to indicate whether
#  this is an original loading, in which case dates should probably be
#  taken as running from the start of the year, or a daily update, in
#  which case we should use today's date to indicate when a membership
#  started or finished.
#

IMPORT_DIR = 'import'

#
#  The purpose of this class is to keep track of which teachers teach which
#  subjects to which year groups, and to regurgitate that information later.
#
#  Each instantiation of the class holds information for one subject.
#
class WhoTeachesWhat

  attr_reader :teachers, :year_teachers, :groups, :year_groups

  @@subjects = Hash.new

  def initialize(subject)
    @subject = subject
    @teachers        = Array.new
    @year_teachers   = Hash.new
    @groups          = Array.new
    @year_groups     = Hash.new
  end
  @@not_by_subject = WhoTeachesWhat.new("None")
  @@ps_invigilators = Array.new

  def note_teacher(staff, group)
    unless @teachers.include?(staff)
#      puts "Adding #{staff.name} to #{@subject.subject_name} teachers."
      @teachers << staff
    end
    unless @groups.include?(group)
      @groups << group
    end
    year_record =
      @year_teachers[group.year.year_num] ||= Array.new
    unless year_record.include?(staff)
#      puts "Adding #{staff.name} to year #{group.year.year_num} #{@subject.subject_name} teachers."
      year_record << staff
    end
    year_group_record =
      @year_groups[group.year.year_num] ||= Array.new
    unless year_group_record.include?(group)
      year_group_record << group
    end
  end

  def self.note_teacher(subject, staff, group)
    subject_record =
      @@subjects[subject.subject_name] ||= WhoTeachesWhat.new(subject)
    subject_record.note_teacher(staff, group)
    @@not_by_subject.note_teacher(staff, group)
  end

  def self.note_ps_invigilator(staff)
    unless @@ps_invigilators.include?(staff)
      @@ps_invigilators << staff
    end
  end

  def self.teachers_by_subject
    @@subjects.each do |subject_name, record|
      yield subject_name, record.teachers
    end
  end

  def self.groups_by_subject
    @@subjects.each do |subject_name, record|
      yield subject_name, record.groups
    end
  end

  def self.teachers_by_subject_and_year
    @@subjects.each do |subject_name, record|
      record.year_teachers.each do |year_num, teachers|
        yield subject_name, year_num, teachers
      end
    end
  end

  def self.groups_by_subject_and_year
    @@subjects.each do |subject_name, record|
      record.year_groups.each do |year_num, groups|
        yield subject_name, year_num, groups
      end
    end
  end

  def self.ps_invigilators
    @@ps_invigilators
  end

  #
  #  Return teachers grouped by the years which they teach.
  #
  def self.teachers_by_year
    @@not_by_subject.year_teachers.each do |year_num, teachers|
      yield year_num, teachers
    end
  end

  #
  #  Return an array of anyone recorded as teaching anything.
  #
  def self.all_teachers
    @@not_by_subject.teachers
  end
end

#
#  And this one is for pupils in a similar fashion.
#
class WhoStudiesWhat

  attr_reader :pupils, :year_pupils

  @@subjects = Hash.new

  def initialize(subject)
    @subject = subject
    @pupils = Array.new
    @year_pupils = Hash.new
  end

  def note_pupils(group)
    group.records.each do |ar|
      unless @pupils.include?(ar.pupil)
#        puts "Adding #{ar.pupil.name} to #{@subject.subject_name} pupils."
        @pupils << ar.pupil
      end
      year_record =
        @year_pupils[group.year.year_num] ||= Array.new
      unless year_record.include?(ar.pupil)
#        puts "Adding #{ar.pupil.name} to year #{group.year.year_num} #{@subject.subject_name} pupils."
        year_record << ar.pupil
      end
    end
  end

  def self.note_pupils(subject, group)
    subject_record =
      @@subjects[subject.subject_name] ||= WhoStudiesWhat.new(subject)
    subject_record.note_pupils(group)
  end

  def self.pupils_by_subject
    @@subjects.each do |subject_name, record|
      yield subject_name, record.pupils
    end
  end

  def self.pupils_by_subject_and_year
    @@subjects.each do |subject_name, record|
      record.year_pupils.each do |year_num, pupils|
        yield subject_name, year_num, pupils
      end
    end
  end

end

#
#  A class to store information about gaps in lessons.  These can be
#  occasions when lessons are suspended for a particular year group
#  (e.g. for study leave or exams) or chunks of the year when nothing
#  is to happen at all (e.g. for athletics or the road relay).
#
#  It is sub-classed to store the data needed by SB_SuspendedLesson
#
class Hiatus

  def initialize(hard_or_soft, times_by_day)
    @hard_or_soft = hard_or_soft   # :hard or :soft
    @times_by_day = times_by_day   # true or false
    @year_group_idents = Array.new
    #
    #  For hiatuses specified with times_by_day = true
    #
    @start_date = nil
    @end_date   = nil
    @start_mins = nil
    @end_mins   = nil
    #
    #  For hiatuses specified with times_by_day = false
    #
    @starts_at = nil
    @ends_at   = nil
  end

  def note_dates_and_times(start_date, end_date, start_mins, end_mins)
    @start_date = start_date
    @end_date   = end_date
    @start_mins = start_mins
    @end_mins   = end_mins
  end

  def note_start_and_end(starts_at, ends_at)
    @starts_at = starts_at
    @ends_at   = ends_at
  end

  def note_year_ident(year_ident)
    @year_group_idents << year_ident
  end

  def complete?
    if @times_by_day
      !(@start_date == nil ||
        @end_date == nil ||
        @start_mins == nil ||
        @end_mins == nil)
    else
      !(@starts_at = nil || @ends_at == nil)
    end
  end

  def hard?
    @hard_or_soft == :hard
  end

  def soft?
    @hard_or_soft == :soft
  end

  #
  #  Does this hiatus apply for an indicated lesson time?
  #
  def applies_to_lesson?(date, period_time)
    if @times_by_day
      #
      #  First the dates have to match, then the times.  If we overlap
      #  the indicated period then we match.
      #
      date >= @start_date &&
      date <= @end_date &&
      period_time.start_mins < @end_mins &&
      period_time.end_mins > @start_mins
    else
      given_starts_at = Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
      given_ends_at   = Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
      given_starts_at < @ends_at && given_ends_at > @starts_at
    end
  end

  #
  #  Does this hiatus apply to the indicated year group.  This will be true
  #  if either:
  #
  #    a) The year_ident is in our list
  #    b) Our list is empty
  #
  #  As a further case, if the year_ident we're given is 0, indicating that
  #  the lesson has a mixture of year groups in it, then we apply provided
  #  our list is empty.  This actually happens without any special code,
  #  but it is intentional.
  #
  def applies_to_year?(year_ident)
    @year_group_idents.empty? || @year_group_idents.include?(year_ident)
  end

  def effective_end_date
    if @times_by_day
      @end_date
    else
      @ends_at.to_date
    end
  end

  #
  #  For filtering out suspensions which are just plain old.
  #
  def occurs_after?(date)
    self.complete? &&
    self.effective_end_date >= date
  end
end


Column = Struct.new(:label, :attr_name, :numeric)

#
#  A module containing the common code used to read in a CSV file
#  and save it in memory records.
#
module Slurper
  def self.included(parent)
    parent::REQUIRED_COLUMNS.each do |column|
      attr_accessor column[:attr_name]
    end
    parent.send :extend, ClassMethods
  end

  module ClassMethods
    def slurp(loader, allow_empty)
      #
      #  Slurp in a file full of records and return them as an array.
      #
      #  Try to coerce everything to utf-8 at point of entry to avoid
      #  problems later.
      #
      raw_contents = File.read(Rails.root.join(IMPORT_DIR, self::FILE_NAME))
      detection = CharlockHolmes::EncodingDetector.detect(raw_contents)
      utf8_encoded_raw_contents =
        CharlockHolmes::Converter.convert(raw_contents,
                                          detection[:encoding],
                                          'UTF-8')
      contents = CSV.parse(utf8_encoded_raw_contents)
#      contents = CSV.read(Rails.root.join(IMPORT_DIR, self::FILE_NAME))
#      puts "Read in #{contents.size} lines."
      #
      #  Do we have the necessary columns?
      #
      missing = false
      column_hash = {}
      self::REQUIRED_COLUMNS.each do |column|
        index = contents[0].find_index(column[:label])
        if index
          column_hash[column[:attr_name]] = index
        else
          missing = true
        end
      end
      if missing
        return nil, "One or more required column(s) missing."
      else
        entries = []
        contents.each_with_index do |row, i|
          if i != 0
            entry = self.new
            self::REQUIRED_COLUMNS.each do |column|
              attr_name = column[:attr_name]
              if column.numeric
                #
                #  Leave as nil if nothing provided.
                #
                unless row[column_hash[attr_name]].blank?
                  entry.send("#{attr_name}=", row[column_hash[attr_name]].to_i)
                end
              else
                entry.send("#{attr_name}=",
                           row[column_hash[attr_name]] ?
                           row[column_hash[attr_name]].strip : "")
              end
            end
            entry.adjust(loader)
            if entry.wanted?(loader)
              entries << entry
            end
          end
        end
        if allow_empty || entries.size > 0
          return entries, nil
        else
          return nil, "File #{self::FILE_NAME} is empty."
        end
      end
    end
  end
end


module DatabaseAccess

  def self.included(base)
    @dbrecord = nil
    @belongs_to_era = nil
    @checked_dbrecord = false
    @element_id = nil
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
        puts "d/b: \"#{@dbrecord.send(field_name)}\" SB: \"#{self.instance_variable_get("@#{field_name}")}\""
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
          puts "d/b: \"#{dbvalue}\"  SB: \"#{value}\""
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
    if @checked_dbrecord
      @dbrecord
    else
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
        find_hash[key_field] = self.send("#{key_field}")
      end
      if @belongs_to_era
        find_hash[:era_id] = self.instance_variable_get("@era_id")
      end
      @dbrecord =
        db_class.find_by(find_hash)
#        self.class.const_get(:DB_CLASS).find_by_source_id(self.source_id)
    end
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


class SB_AcademicRecord
  FILE_NAME = "academicrecord.csv"
  REQUIRED_COLUMNS = [Column["AcrIdent",    :acr_ident,     true],
                      Column["AcYearIdent", :ac_year_ident, true],
                      Column["PupOrigNum",  :pupil_ident,   true],
                      Column["CurrIdent",   :curriculum_ident, true],
                      Column["GroupIdent",  :group_ident,      true]]

  include Slurper

  attr_reader :pupil

  def initialize
    @pupil = nil
  end

  def adjust(loader)
    @pupil = loader.pupil_hash[@pupil_ident]
  end

  def wanted?(loader)
    @pupil != nil
  end

end


class SB_AcademicYear
  FILE_NAME = "academicyear.csv"
  REQUIRED_COLUMNS = [Column["AcYearIdent", :ac_year_ident, true],
                      Column["AcYearName",  :ac_year_name,  false]]

  include Slurper

  def adjust(loader)
  end

  def wanted?(loader)
    #
    #  Only want the one.
    #
    @ac_year_ident == loader.send("era").source_id
  end

end


class SB_Curriculum
  FILE_NAME = "curriculum.csv"
  REQUIRED_COLUMNS = [Column["CurrIdent",    :curriculum_ident, true],
                      Column["AcYearIdent",  :ac_year_ident,    true],
                      Column["YearIdent",    :year_ident,       true],
                      Column["SubjectIdent", :subject_ident,    true]]

  include Slurper

  def adjust(loader)
  end

  def wanted?(loader)
    #
    #  Only want those for our academic year, and for which we know
    #  the year group.
    #
    (self.ac_year_ident == loader.era.source_id) &&
    (loader.year_hash[self.year_ident] != nil)
  end

end


class SB_Date
  #
  #  This is an idiotic table.  Why have a look-up table for dates instead
  #  of simply storing dates?!?
  #
  #  The idiocy is compounded by the fact that it then requires another
  #  layer of error checking to be added.  If you have a date then you
  #  have a date, but if you merely have an index into this table then
  #  you have to do a lookup, then check that the lookup didn't fail.
  #
  FILE_NAME = "days.csv"
  REQUIRED_COLUMNS =
    [Column["Days",      :date_text,  false],
     Column["DateIdent", :date_ident, true]]

  include Slurper

  attr_reader :date

  def initialize
    @date = nil
  end

  def adjust(loader)
    @date = Date.parse(@date_text) unless @date_text.blank?
  end

  def wanted?(loader)
    !!@date
  end

  def source_id
    @date_ident
  end

end


class SB_Group
  FILE_NAME = "groups.csv"
  REQUIRED_COLUMNS = [Column["GroupIdent", :group_ident,      true],
                      Column["GroupName",  :name,             false],
                      Column["YearIdent",  :year_ident,       true],
                      Column["SubIdent",   :subject_ident,    true],
                      Column["CurrIdent",  :curriculum_ident, true]]

  FIELDS_TO_UPDATE = [:name, :current]
  FIELDS_TO_CREATE = [:name, :current]
  DB_CLASS = Teachinggroup
  DB_KEY_FIELD = :source_id

  include Slurper
  include DatabaseAccess

  attr_accessor :records, :era_id
  attr_reader   :year, :curriculum

  def initialize
    @records = Array.new
    @current = true
  end

  def add(record)
    @records << record
  end

  def num_pupils
    @records.size
  end

  def adjust(loader)
    @era_id     = loader.era.id
    @year       = loader.year_hash[self.year_ident]
    @curriculum = loader.curriculum_hash[self.curriculum_ident]
  end

  def wanted?(loader)
    #
    #  We only want groups related to our current academic year.
    #  Note that groups must be loaded from file after curriculum and
    #  academic year, or they'll all get rejected.
    #
    !!(self.year &&
       self.curriculum &&
       self.curriculum.ac_year_ident == loader.era.source_id)
  end

  def source_id
    @group_ident
  end

end


class SB_Location
  FILE_NAME = "room.csv"
  REQUIRED_COLUMNS = [Column["RoomIdent", :room_ident, true],
                      Column["Room",      :short_name, false],
                      Column["RoomName",  :name,       false]]
  FIELDS_TO_UPDATE = [:name]
  DB_CLASS = Locationalias
  FIELDS_TO_CREATE = [:name]
  DB_KEY_FIELD = :source_id

  include Slurper
  include DatabaseAccess

  def adjust(loader)
    if self.name.blank? && !self.short_name.blank?
      self.name = self.short_name
    elsif self.short_name.blank? && !self.name.blank?
      self.short_name = self.name
    end
  end

  def wanted?(loader)
    !(self.name.blank? || self.short_name.blank?)
  end

  def source_id
    @room_ident
  end

  #
  #  We have to have our own saving method because we're slightly
  #  weird.
  #
  def save_location_to_db(extras = nil)
    if dbrecord
      puts "Attempt to re-create d/b record of type #{self.class.const_get(:DB_CLASS)} for #{self.source_id}"
      false
    else
      newrecord = Locationalias.new
      newrecord.name      = self.short_name
      newrecord.source_id = self.source_id
      newrecord.display   = false
      newrecord.friendly  = false
      if newrecord.save
        newrecord.reload
        @dbrecord = newrecord
        @checked_dbrecord = true
        if self.name == self.short_name
          true
        else
          #
          #  Need to create a second one for the other name.
          #
          newrecord = Locationalias.new
          newrecord.name      = self.name
          newrecord.location  = @dbrecord.location
          newrecord.source_id = self.source_id
          newrecord.display   = false
          newrecord.friendly  = false
          if newrecord.save
            true
          else
            puts "Failed to create d/b record of type #{DB_CLASS} for #{self.source_id}"
            false
          end
        end
      else
        puts "Failed to create d/b record of type #{DB_CLASS} for #{self.source_id}"
        false
      end
    end
  end

end


class SB_OtherHalfOccurence
  FILE_NAME = "rtrwgroups.csv"
  REQUIRED_COLUMNS = [Column["RTRWGroupsIdent", :oh_occurence_ident, true],
                      Column["RTRotaWeekIdent", :rota_week_ident,    true],
                      Column["GroupIdent",      :group_ident,        true],
                      Column["GroupDay",        :day_of_week,        true],
                      Column["GroupStart",      :start_mins,         true],
                      Column["GroupEnd",        :end_mins,           true],
                      Column["RoomIdent",       :room_ident,         true],
                      Column["StaffIdent",      :staff_ident1,       true],
                      Column["StaffIdent2",     :staff_ident2,       true],
                      Column["UserIdent3",      :staff_ident3,       true],
                      Column["UserIdent4",      :staff_ident4,       true],
                      Column["GroupName",       :activity_name,      false],
                      Column["DateIdent",       :date_ident,         true]]

  include Slurper

  attr_reader :starts_at,
              :ends_at,
              :staff,
              :group,
              :location

  def adjust(loader)
    got_time = false
    got_staff = false
    got_pupils = false
    got_location = false
    #
    #  Can we establish when this is occuring?
    #
    if @date_ident && loader.date_hash[@date_ident] && @day_of_week
      occurence_date = loader.date_hash[@date_ident].date.beginning_of_week(:sunday) + @day_of_week.days
    elsif @rota_week_ident && loader.rota_week_hash[@rota_week_ident] && @day_of_week
      occurence_date =
        loader.rota_week_hash[@rota_week_ident].start_date + @day_of_week.days
    else
      occurence_date = nil
    end
    if occurence_date && @start_mins && @end_mins
      start_time = sprintf("%02d:%02d", @start_mins / 60, @start_mins % 60)
      end_time   = sprintf("%02d:%02d", @end_mins / 60,   @end_mins % 60)
#      puts "Occurence date is #{occurence_date.to_s}"
#      puts "Start time is #{start_time}"
#      puts "End time is #{end_time}"
      @starts_at =
        Time.zone.parse("#{occurence_date.to_s} #{start_time}")
      @ends_at =
        Time.zone.parse("#{occurence_date.to_s} #{end_time}")
      got_time = true
    end
    #
    #  And which staff are involved?
    #
    @staff = []
    [@staff_ident1, @staff_ident2, @staff_ident3, @staff_ident4].each do |si|
      if si && loader.staff_hash[si]
        @staff << loader.staff_hash[si]
      end
    end
    @staff.uniq!
    got_staff = !@staff.empty?
    #
    #  And which group of pupils?
    #
    if @group_ident && loader.group_hash[@group_ident]
      @group = loader.group_hash[@group_ident]
      got_pupils = true
    end
    #
    #  And where?
    #
    if @room_ident && loader.location_hash[@room_ident]
      @location = loader.location_hash[@room_ident]
      got_location = true
    end
    @complete = got_time && (got_staff || got_pupils)
#    if !@complete && loader.verbose
#      puts "Other half activity #{@activity_name} rejected because:"
#      puts "  No time" unless got_time
#      puts "  No staff" unless got_staff
#      puts "  No pupils" unless got_pupils
#      puts "  No location" unless got_location
#    end
  end

  def wanted?(loader)
    @complete &&
    !@activity_name.blank? &&
    @starts_at >= loader.era.starts_on &&
    @starts_at <= loader.era.ends_on &&
    @starts_at <= @ends_at
  end

  def <=>(other)
    self.starts_at <=> other.starts_at
  end

end


class SB_Period
  FILE_NAME = "period.csv"
  REQUIRED_COLUMNS = [Column["Period",         :period_ident,    true],
                      Column["DayName",        :day_name,        false],
                      Column["TeachingPeriod", :teaching_period, true],
                      Column["PeriodWeek",     :week_id,         true]]

  include Slurper

  attr_reader :time

  def adjust(loader)
    if @teaching_period == 1
      @teaching_period = true
    else
      @teaching_period = false
    end
    @time = loader.period_time_hash[self.period_ident]
  end

  def week_letter
    @week_id == 1 ? "A" : "B"
  end

  def wanted?(loader)
#    if @time == nil
#      puts "Period #{@period_ident} has no time."
#    end
    @time != nil
  end

end

PT_Correction = Struct.new(:wrong_start, :wrong_end, :right_start, :right_end)

class SB_PeriodTime
  FILE_NAME = "periodtimes.csv"
  REQUIRED_COLUMNS = [Column["PeriodTimesIdent", :period_time_ident, true],
                      Column["PeriodTimeStart",  :start_mins,        true],
                      Column["PeriodTimeEnd",    :end_mins,          true],
                      Column["Period",           :period_ident,      true],
                      Column["PeriodTimeSetIdent", :period_time_set_ident, true]]
  TIME_CORRECTIONS = [
    PT_Correction[510, 540, 515, 535],  # 08:30 - 09:00 becomes 08:35 - 08:55
    PT_Correction[540, 595, 540, 590],  # 09:00 - 09:55 becomes 09:00 - 09:50
    PT_Correction[670, 730, 670, 725],  # 11:10 - 12:10 becomes 11:10 - 12:05
    PT_Correction[730, 790, 730, 785],  # 12:10 - 13:10 becomes 12:10 - 13:05
    PT_Correction[840, 900, 840, 895],  # 14:00 - 15:00 becomes 14:00 - 14:55
    PT_Correction[900, 960, 900, 955],  # 15:00 - 16:00 becomes 15:00 - 15:55
    PT_Correction[825, 885, 825, 880],  # 13:45 - 14:45 becomes 13:45 - 14:40
    PT_Correction[730, 770, 730, 765],  # 12:10 - 12:50 becomes 12:10 - 12:45
    PT_Correction[770, 810, 770, 805],  # 12:50 - 13:30 becomes 12:50 - 13:25
    PT_Correction[845, 865, 845, 875]]  # 14:05 - 14:25 becomes 14:05 - 14:35

  include Slurper

  attr_reader :starts_at, :ends_at, :start_mins, :end_mins

  def adjust(loader)
    #
    #  SB has some of the period times recorded wrongly.
    #
    correction = TIME_CORRECTIONS.detect do |tc|
      tc.wrong_start == @start_mins && tc.wrong_end == @end_mins
    end
    if correction
      @start_mins = correction.right_start
      @end_mins   = correction.right_end
    end
    #
    #  Create textual times from the minutes-since-midnight which we
    #  receive.
    #
    @starts_at = sprintf("%02d:%02d", @start_mins / 60, @start_mins % 60)
    @ends_at   = sprintf("%02d:%02d", @end_mins / 60,   @end_mins % 60)
  end

  #
  #  These next two are really horrible.  The problem is, period 6 on a
  #  Wednesday is from 13:30 to 14:25 for most people.  However for the
  #  lower school it is from 13:00 to 13:55.  SB simply can't cope with
  #  this at all and gives the wrong time.  I would prefer if possible
  #  to have the right time.
  #
  #  810 is 13:30
  #  865 is 14:25
  #
  #  Fortunately this particular pattern for start and end time occurs
  #  only for period 6 on a Wednesday.
  #
  def ls_starts_at
    if @start_mins == 810 && @end_mins == 865
      "13:00"
    else
      @starts_at
    end
  end

  def ls_ends_at
    if @start_mins == 810 && @end_mins == 865
      "13:55"
    else
      @ends_at
    end
  end

  def wanted?(loader)
    @period_time_set_ident == 2
  end

end


class SB_Pupil
  FILE_NAME = "pupil.csv"
  REQUIRED_COLUMNS = [Column["PupOrigNum",       :pupil_ident,     true],
                      Column["Pu_Surname",       :surname,         false],
                      Column["Pu_Firstname",     :forename,        false],
                      Column["Pu_GivenName",     :known_as,        false],
                      Column["PupReportName",    :name,            false],
                      Column["PupEmail",         :email,           false],
                      Column["Pu_CandNo",        :candidate_no,    false],
                      Column["PupUCI",           :uci,             false],
                      Column["YearIdent",        :year_ident,      true],
                      Column["Pu_Doe",           :date_of_entry,   false],
                      Column["PupDateofLeaving", :date_of_leaving, false],
                      Column["PType",            :ptype,           true]]
  FIELDS_TO_UPDATE = [:name,
                      :surname,
                      :forename,
                      :known_as,
                      :email,
                      :candidate_no]
  DB_CLASS = Pupil
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [:name,
                      :surname,
                      :forename,
                      :known_as,
                      :email,
                      :candidate_no,
                      :current]

  include Slurper
  include DatabaseAccess

  def initialize
    @current = true
  end

  def adjust(loader)
    #
    #  Whoever enters e-mail address into SB puts in random capitalisation.
    #  Take it out again.
    #
    unless self.email.blank?
      self.email.downcase!
    end
  end

  def wanted?(loader)
    #
    #  He must have a date of entry.
    #
    self.ptype == 60
#    !self.date_of_entry.blank?
  end

  def source_id
    @pupil_ident
  end

  def force_save
    if self.dbrecord
      self.dbrecord.save!
    end
  end

end


class SB_RotaWeek
  FILE_NAME = "rtrotaweek.csv"
  REQUIRED_COLUMNS = [Column["RTRotaWeekIdent", :rota_week_ident, true],
                      Column["DateIdent",       :date_ident,      true]]

  include Slurper

  attr_reader :start_date

  def adjust(loader)
    #
    #  Let's find out what date this week starts on.  SB seems to go
    #  for the Monday on which it starts, but I've no guarantee of that.
    #  Also, calculations are simpler if you go for the Sunday, as then
    #  you can add the day number to the date to get individual day dates.
    #
    date_hash = loader.send("date_hash")
    indicated_date = date_hash[@date_ident]
    if indicated_date
      @start_date = indicated_date.date.beginning_of_week(:sunday)
    else
      @start_date = nil
    end
  end

  def wanted?(loader)
    @start_date != nil
  end

end


class SB_Staff
  FILE_NAME = "staff.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",     :staff_ident, true],
                      Column["UserName",      :name,        false],
                      Column["UserMnemonic",  :initials,    false],
                      Column["UserSurname",   :surname,     false],
                      Column["UserTitle",     :title,       false],
                      Column["UserForename",  :forename,    false],
                      Column["UserLeft",      :left,        true],
                      Column["UserTeach",     :teacher,     true],
                      Column["UserDoesCover", :cover,       true],
                      Column["UserEmail",     :email,       false],
                      Column["PType",         :ptype,       true]]
  FIELDS_TO_UPDATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :current,
                      :teaches,
                      :does_cover]
  DB_CLASS = Staff
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :active,
                      :current,
                      :teaches,
                      :does_cover]

  attr_accessor :active, :current, :teaches, :does_cover

  include Slurper
  include DatabaseAccess

  def adjust(loader)
    #
    #  We can perhaps improve the SB data a little?
    #
    if self.name.blank? && !(self.surname.blank? && self.forename.blank?)
      self.name = "#{self.forename} #{self.surname}"
    end
    #
    #  Whoever enters e-mail address into SB puts in random capitalisation.
    #  Take it out again.
    #
    unless self.email.blank?
      self.email.downcase!
    end
    #
    #  We don't really know which of the ones we get from SB are valid
    #  and which aren't.  We take an initial stab at it.
    #
    self.active = !!(self.email =~ /\@abingdon\.org\.uk$/)
    self.current = (self.left != 1)
    self.teaches = (self.teacher == 1)
    self.does_cover = (self.cover == 1)
  end

  def wanted?(loader)
    #
    #  Current or past senior school staff.
    #
    self.ptype == 60 || self.ptype == 100
  end

  def source_id
    @staff_ident
  end

end


class SB_StaffAbLine
  FILE_NAME = "staffabline.csv"
  REQUIRED_COLUMNS =
    [Column["StaffAbLineIdent", :staff_ab_line_ident, true],
     Column["StaffAbIdent",     :staff_ab_ident,      true],
     Column["StaffAbsenceDate", :absence_date,        true],
     Column["Period",           :period,              true],
     Column["StaffAbCoverNeed", :cover_needed,        true],
     Column["UserIdent",        :staff_ident,         true],
     Column["RoomIdent",        :room_ident,          true],
     Column["TimetableIdent",   :timetable_ident,     true]]

  include Slurper

  def adjust(loader)
  end

  def wanted?(loader)
    true
  end

  def source_id
    @staff_ab_line_ident
  end

end


class SB_StaffAbsence
  FILE_NAME = "staffabsence.csv"
  REQUIRED_COLUMNS =
    [Column["StaffAbIdent",      :staff_ab_ident, true],
     Column["StaffAbsenceDate",  :absence_date,   true],
     Column["Period",            :period,         true],
     Column["StaffAbsenceDate2", :absence_date2,  true],
     Column["Period2",           :period2,        true],
     Column["UserIdent",         :staff_ident,    true],
     Column["RoomIdent",         :room_ident,     true]]


  include Slurper

  def adjust(loader)
  end

  def wanted?(loader)
    true
  end

  def source_id
    @staff_ab_ident
  end

end


class SB_StaffCover
  FILE_NAME = "staffcovers.csv"
  REQUIRED_COLUMNS =
    [Column["StaffAbLineIdent", :staff_ab_line_ident, true],
     Column["AbsenceDate",      :absence_date,        true],
     Column["UserIdent",        :staff_ident,         true],
     Column["Staff",            :staff_name,          false],
     Column["PType",            :ptype,               true]]

  include Slurper

  attr_accessor :sal, :date, :staff_covering, :staff_covered

  attr_reader :date, :cover_or_invigilation, :period

  #
  #  A class for recording details of an apparent clash.  For a clash
  #  to exist, the same resource must have a commitment to two simultaneous
  #  events.  This class therefore simply records references to the two
  #  commitments.
  #
  class Clash

    attr_reader :cover_commitment, :clashing_commitment

    require_relative 'permitted_overloads'

    def initialize(cover_commitment, clashing_commitment)
      @cover_commitment    = cover_commitment
      @clashing_commitment = clashing_commitment
    end

    #
    #  Clashes are sorted chronologically.
    #
    def <=>(other)
      self.cover_commitment.event.starts_at <=> other.cover_commitment.event.starts_at
    end

    def to_partial_path
      "user_mailer/clash"
    end

    def self.permitted_overload(cover_commitment, clashing_commitment)
      PERMITTED_OVERLOADS.each do |pe|
        if pe.cover_event_body =~ cover_commitment.event.body &&
           pe.clash_event_body =~ clashing_commitment.event.body
          return true
        end
      end
      false
    end

    def self.find_clashes(cover_commitment)
      #
      #  Finds anything which apparently clashes with this cover commitment.
      #  Ignores:
      #
      #    The cover commitment itself
      #    Additional commitments to the same event
      #    Commitments to events flagged as unimportant
      #    Commitments to events of the same category, flagged as mergeable,
      #    happening at exactly the same time (e.g. registration)
      #    Events flagged as can_borrow, where more then one member of
      #    staff is committed to the event.
      #
      #  It is possible for someone to be committed more than once
      #  to the same event, if he or she is a member of more than one
      #  group committed to the event.  Make sure we report on each
      #  clashing event only once.
      #
      clashes = []
      #
      #  Special case.  ICF uses a convention of saying an individual
      #  is covering his or her own lesson to indicate that no cover
      #  is actually needed at all.  Identify this case, and if we
      #  have it then do no further checks.
      #
      unless cover_commitment.element == cover_commitment.covering.element
        event_ids_seen = []
        all_commitments =
          cover_commitment.element.commitments_during(
            start_time: cover_commitment.event.starts_at,
            end_time:   cover_commitment.event.ends_at)
        if all_commitments.size > 1
          #
          #  Possibly a problem.
          #
  #        puts "Possible cover clash for #{cover_commitment.element.name}."
          all_commitments.each do |c|
  #          puts "  #{c.event.starts_at}"
  #          puts "  #{c.event.ends_at}"
  #          puts "  #{c.event.body}"
            unless (c == cover_commitment) ||
                   (c.event == cover_commitment.event) ||
                   (c.covered) ||
                   (c.event.eventcategory.unimportant) ||
                   (c.event.eventcategory.can_merge &&
                    c.event.eventcategory == cover_commitment.event.eventcategory &&
                    c.event.starts_at == cover_commitment.event.starts_at &&
                    c.event.ends_at   == cover_commitment.event.ends_at) ||
                   (c.event.eventcategory.can_borrow &&
                    c.event.staff(true).size > 1) ||
                   permitted_overload(cover_commitment, c) ||
                   event_ids_seen.include?(c.event.id)
              clashes << Clash.new(cover_commitment, c)
              event_ids_seen << c.event.id
            end
          end
        end
      end
      clashes
    end

  end

  class Oddity

    attr_reader :descriptive_text

    #
    #  New version - now passed the actual cover commitment.
    #
    def initialize(staff_cover,
                   descriptive_text)
#      puts "Creating an oddity"
      @staff_cover        = staff_cover
      @descriptive_text   = descriptive_text
      #
      #  Now prepare the bits we need to produce formatted output.
      #

    end

    def to_partial_path
      "user_mailer/oddity"
    end

    def effective_date
      @staff_cover.date
    end

    def oddity_type
      @staff_cover.cover_or_invigilation
    end

    def activity_text
      @staff_cover.cover_or_invigilation == :cover ? "Cover" : "Invigilation"
    end
    
    def start_time
      @staff_cover.period.time.starts_at
    end

    def end_time
      @staff_cover.period.time.ends_at
    end

    def person
      @staff_cover.staff_covering.name
    end

    def problem
      @descriptive_text
    end

    def <=>(other)
      self.effective_date <=> other.effective_date
    end

  end

  def initialize
    @sal  = nil
    @date = nil
    @staff_covering        = nil
    @staff_covered         = nil
    @cover_or_invigilation = nil
    @invigilation_location = nil
    @dbrecord              = nil
  end

  def adjust(loader)
  end

  def wanted?(loader)
    #
    #  Current or past senior school staff.
    #
    self.ptype == 60 || self.ptype == 100
  end

  def source_id
    @staff_ab_line_ident
  end

  #
  #  Prepares a SB cover record for subsequent loading/checking in the d/b.
  #  Returns true if we are ready, or false if this one isn't suitable -
  #  wrong type or don't have all the necessary info.
  #
  #  Discard here any which are in the past.
  #
  def prepare(loader, oddities)
    result = false
    if @ptype == 60
      @date = loader.safe_date(@absence_date)
      #
      #  Silently ignore any which are in the past.
      #
      if @date && @date >= loader.start_date
        #
        #  We try to gather all the relevant information up front,
        #  checking as we go.
        #
        #  sc    Staff cover
        #  sal   Staff absence line
        #  sa    Staff absence
        #
        #  sc => sal => sa
        #
        @sal = loader.sal_hash[@staff_ab_line_ident]
        @staff_covering = loader.staff_hash[@staff_ident]
        if @sal && @staff_covering
          #
          #  Is it cover or invigilation?
          #
          if @sal.timetable_ident
            #
            #  Cover.  Can we find the target lesson?
            #
            @cover_or_invigilation = :cover
            @sa = loader.sa_hash[@sal.staff_ab_ident]
            if @sa
              @staff_covered = loader.staff_hash[@sa.staff_ident]
              @period = loader.period_hash[@sal.period]
              if @staff_covered && @period && @period.time
                #
                #  Have all we need to be able to process this one.
                #
                result = true
              else
                #
                #  Can't find covered staff member.
                #
                puts "Can't find staff member #{@sa.staff_ident} to cover."
  #              puts self.inspect
              end
            else
              #
              #  Can't find the absence record - which would tell us
              #  which lesson to cover.
              #
              puts "Can't find absence record #{@sal.staff_ab_ident} for cover."
            end
          else
            #
            #  Invigilation
            #
            @cover_or_invigilation = :invigilation
            puts "An invigilation slot for #{@staff_covering.name} on #{@date}." if loader.verbose
            #
            #  Is there a room specified which we know about?
            #
            @sa = loader.sa_hash[@sal.staff_ab_ident]
            if @sa
              @invigilation_location = loader.location_hash[@sa.room_ident]
            end
            @period = loader.period_hash[@sal.period]
            if @period && @period.time
              result = true
            else
              puts "Couldn't find period #{@sal.period} for invigilation."
            end
          end
          if result
            #
            #  Cross check that SB isn't asking us to do something
            #  impossible.
            #
            unless @staff_covering.dbrecord &&
                   @staff_covering.dbrecord.active
              puts "#{@staff_covering.name} is due to #{@sal.timetable_ident ? "cover" : "invigilate"} on #{@date} but is inactive."
              oddities << Oddity.new(self,
                                     "not a current member of the teaching staff")
              result = false
            end
          end
        end
      end
    end
    result
  end

  def ensure_db(loader)
    added    = 0
    amended  = 0
    deleted  = 0
    clashes  = []
    oddities = []
    if @cover_or_invigilation == :cover
      #
      #  Is it already in the database?
      #  It's a bit weird, but Ian sometimes does cover for non-existent
      #  lessons.
      #
      candidates =
        Commitment.commitments_on(startdate: self.date,
                                  include_nonexistent: true).
                   covering_commitment.
                   where(source_id: self.source_id)
      if candidates.size == 0
        #
        #  Not there - need to create it.  Can we find the corresponding
        #  lesson?
        #
        #  Need to find the commitment by the covered teacher
        #  to the indicated lesson.
        #
        if SB_Timetableentry.been_merged?(@sal.timetable_ident)
          dblesson = Event.on(@date).
                           eventsource_id(loader.event_source.id).
                           source_hash(
                             SB_Timetableentry.merged_source_hash(@sal.timetable_ident))[0]
        else
          dblesson = Event.on(@date).
                           eventsource_id(loader.event_source.id).
                           source_id(@sal.timetable_ident)[0]
        end
        if dblesson
#        puts "Found the corresponding lesson."
          #
          #  Need to find the commitment by the covered teacher
          #  to the indicated lesson.
          #
          if dblesson.non_existent
            oddities << Oddity.new(self, "lesson is suspended")
          end
          original_commitment =
            Commitment.by(@staff_covered.dbrecord).to(dblesson)[0]
          if original_commitment
            if original_commitment.covered
              puts "Commitment seems to be covered already."
            end
            cover_commitment = Commitment.new
            cover_commitment.event = original_commitment.event
            cover_commitment.element = @staff_covering.dbrecord.element
            cover_commitment.covering = original_commitment
            cover_commitment.source_id = self.source_id
            if cover_commitment.save
              added += 1
              cover_commitment.reload
              #
              #  Does this clash with anything?
              #
              clashes = Clash.find_clashes(cover_commitment)
            else
              puts "Failed to save cover."
              cover_commitment.errors.full_messages.each do |msg|
                puts msg
              end
              puts "staff_ab_line_ident = #{@staff_ab_line_ident}"
              puts "staff_covering:"
              puts "  name #{@staff_covering.name}"
              puts "  does_cover #{@staff_covering.does_cover}"
              puts "dblesson:"
              puts "  body: #{dblesson.body}"
              puts "  eventcategory: #{dblesson.eventcategory.name}"
              puts "  starts_at: #{dblesson.starts_at}"
              puts "  ends_at: #{dblesson.ends_at}"
              puts "original_commitment:"
              puts "  element.name: #{original_commitment.element.name}"
            end
          else
            puts "Failed to find original commitment."
            puts "staff_ab_line_ident = #{@staff_ab_line_ident}"
          end
        else
          puts "Failed to find corresponding lesson."
        end
      elsif candidates.size == 1
        cover_commitment = candidates[0]
#        puts "Cover is already there."
#        puts "Event #{candidates[0].event.body} at #{candidates[0].event.starts_at}"
        #
        #  Is it the right person doing it?
        #
        if cover_commitment.element != @staff_covering.dbrecord.element
          #
          #  No.  Adjust.
          #
          cover_commitment.element = @staff_covering.dbrecord.element
          if cover_commitment.save
            amended += 1
          else
            puts "Failed to save amended cover."
          end
          #
          #  Reload regardless of whether or not the save succeeded,
          #  because if it failed we want to get back the consistent
          #  record which we had before.
          #
          cover_commitment.reload
        end
        #
        #  Again, need to check if it clashes with anything.
        #
        clashes = Clash.find_clashes(cover_commitment)
        if cover_commitment.event.non_existent
          oddities << Oddity.new(self, "lesson is suspended")
        end
      else
        puts "Weird - cover item #{self.source_id} is there more than once."
        candidates.each do |c|
          c.destroy
          deleted += 1
        end
      end
    else
      #
      #  Is it already in the database?
      #
      dbinvigilation =
        Event.on(@date).
              eventsource_id(loader.event_source.id).
              eventcategory_id(loader.invigilation_category.id).
              source_id(@sal.staff_ab_line_ident)[0]
      if dbinvigilation
        newly_created = false
      else
        newly_created = true
        starts_at =
          Time.zone.parse("#{@date.to_s} #{@period.time.starts_at}")
        ends_at   =
          Time.zone.parse("#{@date.to_s} #{@period.time.ends_at}")
        event = Event.new
        event.body          = "Invigilation"
        event.eventcategory = loader.invigilation_category
        event.eventsource   = loader.event_source
        event.starts_at     = starts_at
        event.ends_at       = ends_at
        event.approximate   = false
        event.non_existent  = false
        event.private       = false
        event.all_day       = false
        event.compound      = false
        event.source_id     = @sal.staff_ab_line_ident
        if event.save
          event.reload
          dbinvigilation = event
          added += 1
        else
          puts "Failed to create invigilation event."
        end
      end
      if dbinvigilation
        #
        #  Event is now in the d/b.  Make sure it has the right resources.
        #
        sb_element_ids = Array.new
        if @staff_covering.dbrecord.element
          sb_element_ids << @staff_covering.dbrecord.element.id
        else
          puts "Invigilation by #{@staff_covering.initials} who has no element."
        end
        if @invigilation_location &&
           @invigilation_location.dbrecord &&
           @invigilation_location.dbrecord.location &&
           @invigilation_location.dbrecord.location.active
          sb_element_ids << @invigilation_location.dbrecord.location.element.id
        end
        db_element_ids = dbinvigilation.commitments.collect {|c| c.element_id}
        db_only = db_element_ids - sb_element_ids
        sb_only = sb_element_ids - db_element_ids
        if sb_only.size > 0
          sb_only.each do |sbid|
            c = Commitment.new
            c.event      = dbinvigilation
            c.element_id = sbid
            c.save
            amended += 1 unless newly_created
          end
          dbinvigilation.reload
        end
        if db_only.size > 0
          dbinvigilation.commitments.each do |c|
            if db_only.include?(c.element_id)
              c.destroy
              amended += 1
            end
          end
          dbinvigilation.reload
        end
        #
        #  And check for clashes.
        #
        dbinvigilation.commitments.each do |c|
          #
          #  Only need to check for members of staff.  If we check locations
          #  then we're bound to get clashes.
          #
          if c.element.entity.instance_of?(Staff)
            clashes += Clash.find_clashes(c)
          end
        end
      end
    end
#    if oddities.size > 0
#      puts "Returning #{oddities.size} oddities."
#    end
    [added, amended, deleted, clashes, oddities]
  end

end


class SB_Subject
  FILE_NAME = "subjects.csv"
  REQUIRED_COLUMNS =
    [Column["SubCode",     :subject_code,  false],
     Column["SubName",     :subject_name,  false],
     Column["SubIdent",    :subject_ident, true]]

  NOT_REALLY_SUBJECTS = ["Assembly",
                         "Chapel",
                         "Tutor"]

  WANTED_SUBJECTS = ["Ancient History",
                     "Art",
                     "Be the Best",
                     "Biology",
                     "Chemistry",
                     "Chinese",
                     "Classical Civilisation",
                     "Computing",
                     "Design & Technology",
                     "Drama",
                     "Economics",
                     "Electronics",
                     "English",
                     "EFL",
                     "French",
                     "Further Maths",
                     "General Studies Core Skills",
                     "General Studies Roundabout",
                     "Geography",
                     "German",
                     "Greek",
                     "GSCS",
                     "History",
                     "ICT",
                     "Italian",
                     "Latin",
                     "Library",
                     "Mandarin",
                     "Mathematics",
                     "Music",
                     "Music Singing",
                     "Philosophy",
                     "Physical Education",
                     "Physics",
                     "PSHE",
                     "PSHCE",
                     "Psychology",
                     "Religious Studies",
                     "Russian",
                     "Science",
                     "Spanish",
                     "Sport",
                     "Theatre Studies"]
  include Slurper

  attr_reader :type

  def adjust(loader)
    if WANTED_SUBJECTS.detect {|ws| ws == self.subject_name}
      @type = :proper_subject
    elsif NOT_REALLY_SUBJECTS.detect {|ws| ws == self.subject_name}
      @type = :pseudo_subject
    else
      @type = :unwanted
    end
  end

  def wanted?(loader)
    @type != :unwanted
  end

  def source_id
    self.subject_ident
  end

end


class SB_SuspendedLesson < Hiatus
  FILE_NAME = "suspendedlessons.csv"
  #
  #  Note that the d of "date" in the start date is lower case, whilst
  #  the D in Date of the end date is upper case.  Furlong need to be
  #  given a really big shake.
  #
  REQUIRED_COLUMNS =
    [Column["SusIdent",     :suspension_ident,   true],
     Column["SusStartdate", :start_date_ident,   true],
     Column["SusEndDate",   :end_date_ident,     true],
     Column["YearIdent",    :year_ident,         true],
     Column["StartPeriod",  :start_period_ident, true],
     Column["EndPeriod",    :end_period_ident,   true]]

  include Slurper

  attr_reader :end_date

  def initialize
    super(:soft, true)
  end

  def adjust(loader)
    #
    #  Need to work out our actual start and finish times.
    #
    start_date   = loader.safe_date(self.start_date_ident)
    end_date     = loader.safe_date(self.end_date_ident)
    start_period = loader.period_hash[self.start_period_ident]
    end_period   = loader.period_hash[self.end_period_ident]
    #
    #  There appears to be (yet another) bug in SB in that it sometimes
    #  fails to record the start period.  Assume it to be 1.
    #
    if start_date && end_date && end_period && !start_period
      start_period = loader.period_hash[1]
    end
    if start_date && end_date && start_period && end_period
      start_mins = start_period.time.start_mins
      end_mins   = end_period.time.end_mins
    end
    #
    #  Although we could access the Hiatus data structures directly,
    #  prefer to keep them out of sight.
    #
    self.note_dates_and_times(start_date, end_date, start_mins, end_mins)
    self.note_year_ident(@year_ident)
  end

  def wanted?(loader)
    self.complete? && self.occurs_after?(loader.start_date)
  end

  def source_id
    @suspension_ident
  end

  def initialise_from_extra(es)
    self.note_dates_and_times(es.start_date,
                              es.end_date,
                              es.start_mins,
                              es.end_mins)
    self.note_year_ident(es.year_ident)
  end

  def self.create_extra(es)
    new_one = self.new
    new_one.initialise_from_extra(es)
    new_one
  end

end


class SB_ExtraSuspension
  attr_reader :start_date,
              :end_date,
              :year_ident,
              :start_mins,
              :end_mins
end


class SB_Taggroup
  FILE_NAME = "tags.csv"
  REQUIRED_COLUMNS = [Column["TagNo",      :taggroup_ident, true],
                      Column["TagUse",     :name,           false],
                      Column["TagDate",    :starts_at,      false],
                      Column["TagDelDate", :ends_at,        false],
                      Column["UserIdent",  :staff_ident,    true],
                      Column["TagPrivate", :is_private,     true]]
  include Slurper

  FIELDS_TO_UPDATE = [:name]
  DB_CLASS = Taggroup
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [:name, :current, :era_id, :owner_id]

  include DatabaseAccess

  attr_reader :staff, :owner_id, :records

  def initialize
    @staff = nil
    @owner_id = nil
    @records = Array.new
    @current = true
    @era_id = Setting.perpetual_era.id
  end

  def add(record)
    @records << record
  end

  def adjust(loader)
    @staff = loader.staff_hash[@staff_ident]
    #
    #  Arguably we could get a new staff record and new tag groups
    #  for that same staff member in the same run.  It would be
    #  necessary for the new staff member to log in between those
    #  two bits of processing though, so I don't think we need to
    #  worry about it.  In practice, the tag groups will just
    #  be delayed by a day.
    #
    if @staff &&
       @staff.dbrecord &&
       @staff.dbrecord.element &&
       @staff.dbrecord.element.concerns.me.size > 0
      @owner_id = @staff.dbrecord.element.concerns.me[0].user_id
    end
  end

  def wanted?(loader)
    @staff != nil && @owner_id != nil
  end

  def source_id
    @taggroup_ident
  end

  def current
    true
  end

  def num_pupils
    @records.size
  end

  def ensure_db(loader)
    loaded_count           = 0
    changed_count          = 0
    unchanged_count        = 0
    reincarnated_count     = 0
    member_loaded_count    = 0
    member_removed_count   = 0
    member_unchanged_count = 0
    #
    #  First call the method, then we can access @dbrecord directly.
    #
    self.dbrecord
    if @dbrecord
      #
      #  It's possible that, although there is a record in the d/b
      #  it is no longer current.
      #
      unless @dbrecord.current
        @dbrecord.reincarnate
        @dbrecord.reload
        reincarnated_count += 1
      end
      #
      #  Need to check the group details still match.
      #
      if self.check_and_update
        changed_count += 1
      else
        unchanged_count += 1
      end
    else
      if self.save_to_db(starts_on: loader.start_date)
        loaded_count += 1
      end
    end
    if @dbrecord
      #
      #  And now sort out the pupils for this tag group.
      #
      db_member_ids =
        @dbrecord.members(loader.start_date).collect {|s| s.source_id}
      sb_member_ids = self.records.collect {|r| r.pupil_ident}
      missing_from_db = sb_member_ids - db_member_ids
      missing_from_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          begin
            if @dbrecord.add_member(pupil.dbrecord, loader.start_date)
              member_loaded_count += 1
            else
              puts "Failed to add #{pupil.name} to taggroup #{self.name}"
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to add #{pupil.name} to taggroup #{self.name}"
            puts e
          end
        end
      end
      extra_in_db = db_member_ids - sb_member_ids
      extra_in_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          @dbrecord.remove_member(pupil.dbrecord, loader.start_date)
          member_removed_count += 1
        end
      end
      member_unchanged_count += (db_member_ids.size - extra_in_db.size)
    end
    [loaded_count,
     reincarnated_count,
     changed_count,
     unchanged_count,
     member_loaded_count,
     member_removed_count,
     member_unchanged_count]
  end

end

class SB_Taggroupmembership
  FILE_NAME = "puptag.csv"
  REQUIRED_COLUMNS = [Column["PupOrigNum", :pupil_ident, true],
                      Column["TagNo",      :taggroup_ident, true]]

  include Slurper

  attr_reader :pupil, :taggroup

  def initialize
    @pupil    = nil
    @taggroup = nil
  end

  def adjust(loader)
    @pupil    = loader.pupil_hash[@pupil_ident]
    @taggroup = loader.taggroup_hash[@taggroup_ident]
  end

  def wanted?(loader)
    @pupil != nil && @taggroup != nil
  end

end

class SB_Timetableentry
  FILE_NAME = "timetable.csv"
  SUSPENDABLE_TYPES = [:assembly,
                       :lesson,
                       :registration,
                       :chapel,
                       :tutor_period,
                       :supervised_study]
  REQUIRED_COLUMNS = [Column["TimetableIdent", :timetable_ident, true],
                      Column["GroupIdent",     :group_ident,     true],
                      Column["StaffIdent",     :staff_ident,     true],
                      Column["RoomIdent",      :room_ident,      true],
                      Column["Period",         :period_ident,    true],
                      Column["AcYearIdent",    :ac_year_ident,   true],
                      Column["TimeNote",       :time_note,       false]]

  include Slurper

  attr_reader :compound,
              :source_hash,
              :staff_idents,
              :group_idents,
              :room_idents,
              :lower_school,
              :period,
              :period_time

  #
  #  The following item exists to allow us to find the right merged
  #  event, given the ident of an original un-merged event.
  #
  @@merged_event_source_hash_hash = Hash.new

  def initialize
    @compound = false
    @source_hash = ""
    @staff_idents = []
    @group_idents = []
    @room_idents  = []
    @body_text = nil
    @lower_school = false
    @suspensions = []
    @year_group_id = nil
    @event_type = nil
  end

  def adjust(loader)
    if loader.period_hash[self.period_ident]
      @period = loader.period_hash[self.period_ident]
      @period_time = @period.time
    else
      @period = nil
      @period_time = nil
    end
  end

  def wanted?(loader)
    #
    #  For now we require either that they involve a teaching group
    #  (a normal lesson) or they have a time_note (usually a meeting).
    #
    #  They must also involve *some* known resource - a member of
    #  staff or a group of pupils.
    #
    if @ac_year_ident == loader.era.source_id &&
       (@group_ident != nil || !@time_note.blank?) &&
       (loader.staff_hash[self.staff_ident] != nil ||
        loader.group_hash[self.group_ident] != nil)
      if @period && @period_time
        true
      else
#        puts "Timetable entry #{self.timetable_ident} has no period."
        false
      end
    else
      false
    end
  end

  def note_hiatuses(loader, hiatuses)
    #
    #  Are there any suspensions which might apply to this lesson?
    #
    @gaps, @suspensions = hiatuses.select {
      |hiatus| hiatus.applies_to_year?(self.year_ident(loader))}.partition {
      |hiatus| hiatus.hard? }
  end

  def <=>(other)
    self.timetable_ident <=> other.timetable_ident
  end

  def atomic?
    !@compound
  end

  #
  #  Check whether this particular lesson is suspended on the indicated
  #  date.  Take account of the time of this lesson.
  #
  def suspended_on?(loader, date)
    if SUSPENDABLE_TYPES.include?(self.event_type(loader)) &&
       @suspensions.detect {|s| s.applies_to_lesson?(date, @period_time)}
      true
    else
      false
    end
  end

  #
  #  And does this lesson exist at all on the specified date.  Typically
  #  this gets rid of lessons on, e.g. Inset days.
  #
  def exists_on?(date)
    @gaps.detect {|gap| gap.applies_to_lesson?(date, @period_time)} == nil
  end

  #
  #  Returns our year group id, or 0 if we don't seem to have one.
  #  Information is cached.
  #
  #  For compound events, all the groups have to have the same year
  #  ident for us to return it.
  #
  def year_ident(loader)
    unless @year_group_id
      group = nil
      if atomic?
        group = loader.group_hash[self.group_ident]
      else
        if self.group_idents.size > 0
          group = loader.group_hash[self.group_idents[0]]
          #
          #  Check whether there's another group with a different
          #  year id.  If there is, then we can't return a meaningful
          #  value.
          #
          exception =
            self.group_idents.detect {|gi|
              g = loader.group_hash[gi]
              g != nil && g.year_ident != group.year_ident}
          if exception
            group = nil
          end
        end
      end
      if group
        @year_group_id = group.year_ident
      else
        @year_group_id = 0
      end
    end
    @year_group_id
  end

  def identify_ls(loader)
    if atomic?
      #
      #  We need to have a group associated and the year for that group
      #  needs to be 7 or 8.
      #
      group = loader.group_hash[self.group_ident]
      if group && (group.year.year_num == 7 || group.year.year_num == 8)
        @lower_school = true
      end
    else
      if self.group_idents.size > 0
        group = loader.group_hash[self.group_idents[0]]
        if group && (group.year.year_num == 7 || group.year.year_num == 8)
          @lower_school = true
        end
      end
    end
  end

  def meeting?
    #
    #  Lessons have a teaching group.  Meetings have a title (@time_note).
    #  Which is the definitive decider?  Not sure, but since we've already
    #  rejected records which have neither group_ident nor time_note, this
    #  test should be OK.
    #
    @group_ident == nil && @group_idents.size == 0
  end

  #
  #  Calculate and cache our event type.
  #
  def event_type(loader)
    unless @event_type
      if self.meeting?
        if @time_note == "PS"
          @event_type = :supervised_study
        else
          @event_type = :meeting
        end
      elsif self.body_text(loader) == "Assembly"
        @event_type = :assembly
      elsif self.body_text(loader) == "Chapel"
        @event_type = :chapel
      elsif self.period_time.starts_at == "08:35" &&
            self.period_time.ends_at == "08:55"
        @event_type = :registration
      elsif (self.period_time.starts_at == "12:10" &&
             self.period_time.ends_at == "12:45") ||
            (self.period_time.starts_at == "12:50" &&
             self.period_time.ends_at == "13:25") ||
            (self.period_time.starts_at == "14:05" &&
             self.period_time.ends_at == "14:35")
        @event_type = :tutor_period
      else
        @event_type = :lesson
      end
    end
    @event_type
  end

  def eventcategory(loader)
    case self.event_type(loader)
      when :meeting
        loader.meeting_category
      when :supervised_study
        loader.supervised_study_category
      when :assembly
        loader.assembly_category
      when :chapel
        loader.chapel_category
      when :registration
        loader.registration_category
      when :tutor_period
        loader.tutor_category
      else
        loader.lesson_category
    end
  end

  def description
    #
    #  A one-line description of this timetable entry.
    #
    "Period #{
      self.period_ident
     }, group #{
      self.group_ident ? self.group_ident : "nil"
     }, staff #{
      self.staff_ident ? self.staff_ident : "nil"
     }, room #{
      self.room_ident ? self.room_ident : "nil"
     }"
  end

  #
  #  Provides body text for this event when loaded into the d/b.
  #
  def body_text(loader)
    unless @body_text
      if meeting?
        @body_text = self.time_note
      else
        if loader.group_hash[self.group_ident]
          @body_text = loader.group_hash[self.group_ident].name
        else
          @body_text = "Unknown"
        end
        if @compound && / Assem\Z/ =~ @body_text
          @body_text = "Assembly"
        elsif @compound && / Chap\Z/ =~ @body_text
          @body_text = "Chapel"
        end
      end
    end
    @body_text
  end
  #
  #  A method to encapsulate the code which decides whether two entries
  #  are sufficiently similar to be merged.
  #
  def can_merge?(loader, other)
    if self.group_ident && loader.group_hash[self.group_ident]
      own_group_name = loader.group_hash[self.group_ident].name
    else
      own_group_name = ""
    end
    if other.group_ident && loader.group_hash[other.group_ident]
      other_group_name = loader.group_hash[other.group_ident].name
    else
      other_group_name = ""
    end
    self.atomic? && other.atomic? && self.period_ident == other.period_ident &&
    (
      #
      #  Lots of people at a single meeting?
      #
      (self.meeting? &&
       other.meeting? &&
       self.time_note == other.time_note) ||
      #
      #  An assembly?
      #
      (!self.meeting? && !other.meeting? &&
       / Assem\Z/ =~ own_group_name &&
       / Assem\Z/ =~ other_group_name) ||
      #
      #  Or chapel?
      #
      (!self.meeting? && !other.meeting? &&
       / Chap\Z/ =~ own_group_name &&
       / Chap\Z/ =~ other_group_name) ||
      #
      #  Or sport/PE/General Studies?  Note that for these, the two should
      #  boast the same group, not just ones with similar names.
      #
      (!self.meeting? && !other.meeting? &&
       / (Spt|PE|GSRA)\Z/ =~ own_group_name &&
       self.group_ident == other.group_ident) ||
      #
      #  Or finally, the same group in the same place.
      #
      (!self.meeting? && !other.meeting? &&
       self.group_ident == other.group_ident &&
       self.room_ident  == other.room_ident)
    )
  end

  #
  #  Passed an array of Timetableentries, we sort them and identify any
  #  that can be merged into a single event.
  #
  def self.sort_and_merge(loader, ttes)
#    puts "Entering sort_and_merge"
    #
    #  We are looking for events which share the same period_ident, and
    #  either the same group_ident or the same room_ident (or both).  Any
    #  set of such which we find can be merged into a single event.
    #
    #  Above comment temporarily suspended.  For now I'm doing a merge
    #  solely for meetings, which means the period and time_note must match.
    #
    result = []
    rest = ttes
    while rest.size > 0
#      puts "rest.size = #{rest.size}"
      sample = rest[0]
      matching, rest = rest.partition {|tte|
        tte == sample || sample.can_merge?(loader, tte)
      }
      if matching.size > 1
#        puts "Merging the following events."
#        matching.each do |tte|
#          puts "  #{tte.description}"
#        end
        compounded = matching[0].clone
        #
        #  Don't want to provide a general method to write to these
        #  instance variables, but it's legitimate to use instance_variable_set
        #  here as we're inside the implementation of the object.
        #
        compounded.instance_variable_set("@compound", true)
        compounded.instance_variable_set(
          "@source_hash",
          SB_Timetableentry.generate_hash(matching))
        compounded.instance_variable_set(
          "@staff_idents",
          matching.collect {|tte| tte.staff_ident}.uniq.compact)
        compounded.instance_variable_set(
          "@group_idents",
          matching.collect {|tte| tte.group_ident}.uniq.compact)
        compounded.instance_variable_set(
          "@room_idents",
          matching.collect {|tte| tte.room_ident}.uniq.compact)
#        puts "Combined #{matching.size} events with digest #{compounded.source_hash}."
#        puts "Event is #{compounded.time_note} and involves #{compounded.staff_idents.size} staff."
        result << compounded
        #
        #  This is so that, if we subsequently get given the ident of
        #  an original un-merged event, we can find the corresponding
        #  merged event.
        #
        matching.each do |mevent|
          @@merged_event_source_hash_hash[mevent.timetable_ident] =
            compounded.source_hash
        end
      else
        result << matching[0]
      end
    end
#    puts "Leaving sort_and_merge"
    result
  end

  def self.been_merged?(source_ident)
    @@merged_event_source_hash_hash[source_ident] != nil
  end

  def self.merged_source_hash(source_ident)
    @@merged_event_source_hash_hash[source_ident]
  end

  #
  #  Generate a hash from a set of timetablentries, using just their
  #  timetable_idents to drive it.
  #
  #  In the case of meetings, the unique identifier is simply the
  #  text and the period id.
  #
  def self.generate_hash(ttes)
    if ttes[0].meeting?
      Digest::MD5.hexdigest("#{ttes[0].time_note}/#{ttes[0].period_ident}")
    else
      Digest::MD5.hexdigest(
        ttes.sort.collect {|tte| tte.timetable_ident.to_s}.join("/"))
    end
  end

end


class SB_Tutorgroupentry
  FILE_NAME = "tutorgroup.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :user_ident,  true],
                      Column["YearIdent",    :year_ident,  true],
                      Column["PupOrigNum",   :pupil_ident, true],
                      Column["Pu_House",     :house,       false]]

  include Slurper

  def adjust(loader)
    #
    #  Nothing for now.
    #
  end

  def wanted?(loader)
    self.user_ident != 0 &&
    self.year_ident != 0 &&
    self.pupil_ident != 0 &&
    self.pupil_ident != -1
  end

end


class SB_Tutorgroup
  FIELDS_TO_UPDATE = [:name, :era_id, :current]
  DB_CLASS = Tutorgroup
  DB_KEY_FIELD = [:staff_id, :house, :start_year]
  FIELDS_TO_CREATE = [:name, :era_id, :current]

  include DatabaseAccess

  attr_accessor :name,
                :house,
                :staff_id,
                :era_id,
                :start_year,
                :records,
                :year_group


  def initialize(year, staff, tge, era)
    @records = Array.new
    @current = true
    @year_group = year.year_num - 6
    @name       = "#{@year_group}#{staff.initials}"
    @house      = tge.house
    @staff_id   = staff.dbrecord.id
    @era_id     = era.id
    @start_year = year.start_year
  end

  def add(record)
    @records << record
  end

  def num_pupils
    @records.size
  end

  def source_id
    @name
  end

  #
  #  Ensure this tutor group is correctly represented in the
  #  database.
  #
  def ensure_db(loader)
    loaded_count           = 0
    changed_count          = 0
    unchanged_count        = 0
    reincarnated_count     = 0
    member_loaded_count    = 0
    member_removed_count   = 0
    member_unchanged_count = 0
    #
    #  First call the method, then we can access @dbrecord directly.
    #
    self.dbrecord
    if @dbrecord
      #
      #  It's possible that, although there is a record in the d/b
      #  no longer current.
      #
      unless @dbrecord.current
        @dbrecord.reincarnate
        @dbrecord.reload
        #
        #  Reincarnating a group sets its end date to nil, but we kind
        #  of want it to be the end of the current era.
        #
        @dbrecord.ends_on = loader.era.ends_on
        @dbrecord.save
        reincarnated_count += 1
      end
      #
      #  Need to check the group details still match.
      #
      if self.check_and_update
        changed_count += 1
      else
        unchanged_count += 1
      end
    else
      if num_pupils > 0
        if self.save_to_db(starts_on: loader.start_date,
                           ends_on: loader.era.ends_on)
          loaded_count += 1
        end
      end
    end
    if @dbrecord
      #
      #  And now sort out the pupils for this tutor group.
      #
      db_member_ids =
        @dbrecord.members(loader.start_date).collect {|s| s.source_id}
      sb_member_ids = self.records.collect {|r| r.pupil_ident}
      missing_from_db = sb_member_ids - db_member_ids
      missing_from_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          begin
            if @dbrecord.add_member(pupil.dbrecord, loader.start_date)
              #
              #  Adding a pupil to a tutor group effectively changes the
              #  pupil's element name.  Save the pupil record so the
              #  element name gets updated.
              #
              pupil.force_save
              member_loaded_count += 1
            else
              puts "Failed to add #{pupil.name} to tutorgroup #{self.name}"
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to add #{pupil.name} to tutorgroup #{self.name}"
            puts e
          end
        end
      end
      extra_in_db = db_member_ids - sb_member_ids
      extra_in_db.each do |pupil_id|
        pupil = loader.pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          @dbrecord.remove_member(pupil.dbrecord, loader.start_date)
          #
          #  Likewise, removing a pupil can change his element name.
          #
          pupil.force_save
          member_removed_count += 1
        end
      end
      member_unchanged_count += (db_member_ids.size - extra_in_db.size)
    end
    [loaded_count,
     reincarnated_count,
     changed_count,
     unchanged_count,
     member_loaded_count,
     member_removed_count,
     member_unchanged_count]
  end

end

class SB_Year
  FILE_NAME = "years.csv"
  REQUIRED_COLUMNS = [Column["YearIdent", :year_ident, true],
                      Column["YearDesc",  :year_num,   true],
                      Column["YearName",  :year_name,  false],
                      Column["Ptype",     :ptype,      true]]

  include Slurper

  attr_reader :start_year

  def adjust(loader)
    #
    #  Nothing for now.
    #
    @era = loader.era
    @start_year = @era.starts_on.year + 7 - self.year_num
  end

  def wanted?(loader)
    #
    #  60 seems to be the main school, whilst 40 is the prep school.
    #
    self.ptype == 60
  end

  def year_ordinal
    (self.year_num - 6).ordinalize
  end

end

class SB_Loader

  KNOWN_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

  InputSource = Struct.new(:array_name,
                           :loader_class,
                           :allow_empty,
                           :hash_prefix,
                           :key_field,
                           :extra)

  INPUT_SOURCES = [InputSource[:academicyears, SB_AcademicYear, false],
                   InputSource[:years, SB_Year, false, :year, :year_ident],
                   InputSource[:curriculums, SB_Curriculum, false, :curriculum,
                               :curriculum_ident],
                   InputSource[:tutorgroupentries, SB_Tutorgroupentry, false],
                   InputSource[:pupils, SB_Pupil, false, :pupil, :pupil_ident],
                   InputSource[:staff, SB_Staff, false, :staff, :staff_ident],
                   InputSource[:locations, SB_Location, false,
                               :location, :room_ident],
                   InputSource[:groups, SB_Group, false, :group, :group_ident],
                   InputSource[:ars, SB_AcademicRecord, false],
                   #
                   #  SB's data structures are slightly loony here (surprise!)
                   #  Instead of periods referencing period times as you
                   #  might expect, the period times reference periods.
                   #  The period time records have their own idents, but
                   #  they're never referenced again.  Instead each
                   #  period time record contains the ident of a period
                   #  record.
                   #
                   #  If it were done the sensible way around, then a period
                   #  time record could be referenced by more than one period,
                   #  allowing different periods (say on different days) to
                   #  share the same period time record.
                   #
                   #  As it's the way round it is, the only many-to-one
                   #  relationship you can manage is for one period to have
                   #  more than one period time record pointing at it, which
                   #  would be a nonsense.  There is thus no point in them
                   #  being separate tables, and they would be better
                   #  implemented as a single table.
                   #
                   #  We cope with it by loading period times first, hashing
                   #  them by period id, then loading periods and linking
                   #  them to period times as they're loaded.  A period
                   #  without a matching period time is an error.
                   #
                   #  The timetable entries can then be loaded later and
                   #  be linked to both periods and period times as they
                   #  are loaded, saving work and checking later on.  Again,
                   #  a timetable entry which references a non-existent
                   #  period is an error.
                   #
                   InputSource[:period_times,
                               SB_PeriodTime, false,
                               :period_time,
                               :period_ident],
                   InputSource[:periods, SB_Period, false,
                               :period, :period_ident],
                   InputSource[:subjects, SB_Subject, false,
                               :subject, :subject_ident],
                   InputSource[:dates, SB_Date, false, :date, :date_ident],
                   InputSource[:hiatuses, SB_SuspendedLesson, true,
                               nil, nil, :get_extra_suspensions],
                   InputSource[:timetable_entries, SB_Timetableentry, false,
                               :tte, :timetable_ident],
                   InputSource[:staffablines, SB_StaffAbLine, false, :sal,
                               :staff_ab_line_ident],
                   InputSource[:staffabsences, SB_StaffAbsence, false, :sa,
                               :staff_ab_ident],
                   InputSource[:staffcovers, SB_StaffCover, false],
                   InputSource[:rtrotaweek, SB_RotaWeek, false,
                               :rota_week, :rota_week_ident],
                   InputSource[:other_half, SB_OtherHalfOccurence, false,
                               :other_half, :oh_occurence_ident],
                   InputSource[:taggroups, SB_Taggroup, true,
                               :taggroup, :taggroup_ident],
                   InputSource[:taggroupmemberships, SB_Taggroupmembership,
                               true]]

    EXTRA_GROUP_FILES = [
      {file_name: "extra_staff_groups.yml", dbclass: Staff},
      {file_name: "extra_pupil_groups.yml", dbclass: Pupil},
      {file_name: "extra_group_groups.yml", dbclass: Group}
    ]

    EXTRA_SUSPENSION_FILES = [
      "extra_suspensions.yml"
    ]

  attr_reader :era,
              :hiatuses,
              :curriculum_hash,
              :date_hash,
              :group_hash,
              :taggroup_hash,
              :location_hash,
              :pupil_hash,
              :rota_week_hash,
              :sal_hash,
              :sa_hash,
              :staff_hash,
              :year_hash,
              :verbose,
              :lesson_category,
              :meeting_category,
              :supervised_study_category,
              :invigilation_category,
              :assembly_category,
              :chapel_category,
              :duty_category,
              :registration_category,
              :tutor_category,
              :event_source,
              :period_hash,
              :period_time_hash,
              :start_date

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
    #
    #  If an explicit date has been specified then we use that.
    #  Otherwise, if a full load has been specified then we use
    #  the start date of the era.
    #  Otherwise, we use either today's date, or the start date of
    #  the era, whichever is the later.
    #
    if options.start_date
      @start_date = options.start_date
    elsif @full_load || Date.today < @era.starts_on
      @start_date = @era.starts_on
    else
      @start_date = Date.today
    end
    puts "Reading data files." if @verbose
    INPUT_SOURCES.each do |is|
      array, msg = is.loader_class.slurp(self, is.allow_empty)
      if msg.blank?
        puts "Read #{array.size} records as #{is.array_name}." if @verbose
        #
        #  It's legitimate to use instance_variable_set because I'm fiddling
        #  with my own instance variables.
        #
        self.instance_variable_set("@#{is.array_name}", array)
        if is.key_field
          tmphash = Hash.new
          array.each do |item|
            #
            #  Now I'm accessing another class's internals so I need to
            #  send a message.
            #
            tmphash[item.send(is.key_field)] = item
          end
          self.instance_variable_set("@#{is.hash_prefix}_hash", tmphash)
        end
      else
        raise "Failed to read #{is.array_name} - #{msg}."
      end
      if is.extra
        self.send(is.extra)
      end
    end
    load_hiatuses
    #
    #  Now need to give all our timetable entries the chance to take
    #  note of our hiatuses.  These may have come from a file, or from
    #  the d/b, so we can't do it until now.
    #
    @timetable_entries.each do |te|
      te.note_hiatuses(self, @hiatuses)
    end
    #
    #  If we get this far then all the files have been succesfully read.
    #  We can perform initial organisation on our data.
    #
    if @academicyears.size != 1
      raise "SchoolBase doesn't have an academic year #{@era.source_ident}"
    end
    puts "Performing initial organisation." if @verbose
#    @period_times.each do |period_time|
#      if period = @period_hash[period_time.period_ident]
#        period.time ||= period_time
#      end
#    end
    puts "Attempting to construct tutor groups." if @verbose
    @tutorgroups = []
    @tg_hash = {}
    @house_hash = {}
    tge_accepted_count = 0
    tge_ignored_count = 0
    @tutorgroupentries.each do |tge|
      staff = @staff_hash[tge.user_ident]
      year  = @year_hash[tge.year_ident]
      pupil = @pupil_hash[tge.pupil_ident]
      if staff && year && pupil && staff.dbrecord && staff.dbrecord.active
        tge_accepted_count += 1
        unless @tg_hash[tge.user_ident]
          tg = SB_Tutorgroup.new(year, staff, tge, @era)
          @tg_hash[tge.user_ident] = tg
          if @house_hash[tg.house]
            @house_hash[tg.house] << tg
          else
            @house_hash[tg.house] = [tg]
          end
        end
        @tg_hash[tge.user_ident].add(tge)
      else
        tge_ignored_count += 1
      end
    end
    puts "Accepted #{tge_accepted_count} tutor group entries." if @verbose
    puts "Ignored #{tge_ignored_count} tutor group entries." if @verbose
    puts "Constructed #{@tg_hash.size} tutor groups." if @verbose
    puts "Sorting academic records into teaching groups." if @verbose
    @ars.each do |ar|
      pupil = @pupil_hash[ar.pupil_ident]
      if pupil && (group = @group_hash[ar.group_ident])
        group.add(ar)
      end
    end
    puts "Finished sorting academic records." if @verbose
    puts "Sorting tag group memberships into tag groups." if @verbose
    @taggroupmemberships.each do |tgm|
      tgm.taggroup.add(tgm)
    end
    puts "Finished sorting tag group memberships." if @verbose
    puts "Merging compound timetable entries." if @verbose
    puts "#{@timetable_entries.size} timetable entries before merge." if @verbose
    @timetable_entries =
      SB_Timetableentry.sort_and_merge(self, @timetable_entries)
    puts "#{@timetable_entries.size} timetable entries after merge." if @verbose
    #
    #  Let's have a separate hash for finding compound ttes.
    #
    @ctte_hash = Hash.new
    @timetable_entries.select {|tte| tte.compound}.each do |ctte|
      @ctte_hash[ctte.source_hash] = ctte
    end
    puts "Sorting periods by week and day." if @verbose
    #
    #  Sort by week and day of the week.
    #
    @periods_by_week = {}
    @periods_by_week["A"] = {}
    @periods_by_week["B"] = {}
    KNOWN_DAY_NAMES.each do |day_name|
      @periods_by_week["A"][day_name] = []
      @periods_by_week["B"][day_name] = []
    end
    @timetable_entries.each do |te|
      period = @period_hash[te.period_ident]
      if period.time && KNOWN_DAY_NAMES.include?(period.day_name)
        @periods_by_week[period.week_letter][period.day_name] << te
      end
    end
    #
    #  Identify which timetable entries refer to lower school lessons.
    #  This can only be done once the hashes have been created.
    #
    @timetable_entries.each do |te|
      te.identify_ls(self)
    end
    #
    #  Make a list of which teachers teach each of the subjects,
    #  and which students study them.
    #  Don't go for d/b records yet because we may yet need to create them.
    #
    @timetable_entries.each do |te|
      if te.compound
        te.group_idents.each do |group_ident|
          group = @group_hash[te.group_ident]
          if group
            subject = @subject_hash[group.subject_ident]
            if subject && subject.type == :proper_subject
              te.staff_idents.each do |staff_ident|
                staff = @staff_hash[staff_ident]
                if staff && staff.active && staff.current
                  WhoTeachesWhat.note_teacher(subject, staff, group)
                end
              end
              WhoStudiesWhat.note_pupils(subject, group)
            end
          elsif te.event_type == :supervised_study
            te.staff_idents.each do |staff_ident|
              staff = @staff_hash [staff_ident]
              if staff && staff.active && staff.current
                WhoTeachesWhat.note_ps_invigilator(staff)
              end
            end
          end
        end
      else
        group = @group_hash[te.group_ident]
        if group
          subject = @subject_hash[group.subject_ident]
          if subject && subject.type == :proper_subject
            staff = @staff_hash[te.staff_ident]
            if staff && staff.active && staff.current
              WhoTeachesWhat.note_teacher(subject, staff, group)
            end
            WhoStudiesWhat.note_pupils(subject, group)
          end
        elsif te.event_type(self) == :supervised_study
          staff = @staff_hash[te.staff_ident]
          if staff && staff.active && staff.current
            WhoTeachesWhat.note_ps_invigilator(staff)
          end
        end
      end
    end
    #
    #  And all the event categories which we need.
    #
    @week_letter_category = Eventcategory.find_by_name("Week letter")
    raise "Can't find event category for week letters." unless @week_letter_category
    @lesson_category = Eventcategory.find_by_name("Lesson")
    raise "Can't find event category for lessons." unless @lesson_category
    @assembly_category = Eventcategory.find_by_name("Assembly")
    raise "Can't find event category for assemblies." unless @assembly_category
    @chapel_category = Eventcategory.find_by_name("Religious service")
    raise "Can't find event category for chapel." unless @chapel_category
    @meeting_category = Eventcategory.find_by_name("Meeting")
    raise "Can't find event category for meetings." unless @meeting_category
    @supervised_study_category = Eventcategory.find_by_name("Supervised study")
    raise "Can't find event category for supervised study." unless @supervised_study_category
    @invigilation_category =
      Eventcategory.find_by_name("Invigilation") ||
      Eventcategory.find_by_name("Exam invigilation")
    raise "Can't find event category for invigilations." unless @invigilation_category
    @other_half_category = Eventcategory.find_by_name("Other Half")
    raise "Can't find event category for Other Half." unless @other_half_category
    @duty_category = Eventcategory.find_by_name("Duty")
    raise "Can't find event category for duties." unless @duty_category
    @registration_category = Eventcategory.find_by_name("Registration")
    raise "Can't find event category for registration." unless @registration_category
    @tutor_category = Eventcategory.find_by_name("Tutor period")
    raise "Can't find event category for tutor period." unless @tutor_category
    @event_source = Eventsource.find_by_name("SchoolBase")
    raise "Can't find event source \"SchoolBase\"." unless @event_source
    @yaml_source = Eventsource.find_by_name("Yaml")
    raise "Can't find event source \"Yaml\"." unless @yaml_source
    #
    #  Dump to file(s).
    #
    puts "Dumping parsed data." if @verbose
    File.open(Rails.root.join(IMPORT_DIR, "staff.yml"), "w") do |file|
      file.puts YAML::dump(@staff)
    end
    File.open(Rails.root.join(IMPORT_DIR, "pupils.yml"), "w") do |file|
      file.puts YAML::dump(@pupils)
    end
    File.open(Rails.root.join(IMPORT_DIR, "groups.yml"), "w") do |file|
      file.puts YAML::dump(@groups)
    end
    File.open(Rails.root.join(IMPORT_DIR, "subjects.yml"), "w") do |file|
      file.puts YAML::dump(@subjects)
    end
    File.open(Rails.root.join(IMPORT_DIR, "tutorgroups.yml"), "w") do |file|
      file.puts YAML::dump(@tg_hash)
    end
    File.open(Rails.root.join(IMPORT_DIR, "periods.yml"), "w") do |file|
      file.puts YAML::dump(@periods)
    end
    File.open(Rails.root.join(IMPORT_DIR, "periodtimes.yml"), "w") do |file|
      file.puts YAML::dump(@period_times)
    end
    File.open(Rails.root.join(IMPORT_DIR, "lessons.yml"), "w") do |file|
      file.puts YAML::dump(@timetable_entries)
    end
    File.open(Rails.root.join(IMPORT_DIR, "locations.yml"), "w") do |file|
      file.puts YAML::dump(@locations)
    end
    File.open(Rails.root.join(IMPORT_DIR, "years.yml"), "w") do |file|
      file.puts YAML::dump(@years)
    end
    File.open(Rails.root.join(IMPORT_DIR, "hiatuses.yml"), "w") do |file|
      file.puts YAML::dump(@hiatuses)
    end
    puts "Finished data initialisation." if @verbose
    yield self if block_given?
  end

  #
  #  Find any gaps currently configured in the database.
  #
  def load_hiatuses
    gap_property = Property.find_by(name: "Gap")
    if gap_property
#      puts "Found the gap property"
      gap_property.element.events_on(@start_date,
                                     @era.ends_on).each do |gap_event|
#        puts "Processing a gap"
        gap = Hiatus.new(:hard, false)
        gap.note_start_and_end(gap_event.starts_at,
                               gap_event.ends_at)
        #
        #  Need a list of the year groups involved in this event.
        #
        gap_event.pupil_year_groups(true).each do |year_group|
          #
          #  year_group is Abingdon years.
          #  year_num is national curriculum (Abingdon + 6)
          #
#          puts "Applies to #{year_group.ordinalize} years."
          year = @years.detect {|year| year.year_num == year_group + 6}
          if year
            gap.note_year_ident(year.year_ident)
          end
        end
#        puts "And recording the gap"
        @hiatuses << gap
      end
    else
      puts "Unable to find a Gap property."
    end
    suspension_property = Property.find_by(name: "Suspension")
    if suspension_property
#      puts "Found the suspension property."
      suspension_property.element.events_on(
        @start_date,
        @era.ends_on).each do |suspension_event|
#        puts "Found a suspension event"
        suspension = Hiatus.new(:soft, false)
        suspension.note_start_and_end(suspension_event.starts_at,
                                      suspension_event.ends_at)
        suspension_event.pupil_year_groups(true).each do |year_group|
#          puts "Applies to #{year_group.ordinalize} years."
          year = @years.detect {|year| year.year_num == year_group + 6}
          if year
            suspension.note_year_ident(year.year_ident)
          end
        end
#        puts "And saving the suspension."
        @hiatuses << suspension
      end
    else
      puts "Unable to find a Suspension property."
    end
  end

  #
  #  Note that none of these methods needs to check whether data have
  #  been read successfully.  We can't get here unless they have been.
  #
  def do_pupils
    pupils_changed_count   = 0
    pupils_unchanged_count = 0
    pupils_loaded_count    = 0
    original_pupil_count = Pupil.current.count
    @pupils.each do |pupil|
      year = @year_hash[pupil.year_ident]
      if year
        dbrecord = pupil.dbrecord
        if dbrecord
          if pupil.check_and_update({start_year: year.start_year})
            pupils_changed_count += 1
          else
            pupils_unchanged_count += 1
          end
        else
          if pupil.save_to_db({start_year: year.start_year})
            pupils_loaded_count += 1
          end
        end
      end
    end
    #
    #  Need to check for pupils who have now left.
    #
    pupils_left_count = 0
    Pupil.current.each do |dbpupil|
      pupil = @pupil_hash[dbpupil.source_id]
      unless pupil
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

  def do_staff
    staff_changed_count   = 0
    staff_unchanged_count = 0
    staff_loaded_count    = 0
    staff_deleted_count   = 0
    @staff.each do |s|
      dbrecord = s.dbrecord
      if dbrecord
        #
        #  Staff record already exists.  Any changes?
        #
        if s.check_and_update
          staff_changed_count += 1
        else
          staff_unchanged_count += 1
        end
      else
        #
        #  d/b record does not yet exist.
        #
        if s.save_to_db
          staff_loaded_count += 1
        end
      end
    end
    #
    #  Any there who shouldn't be there?
    #
    Staff.all.each do |dbrecord|
      if dbrecord.source_id && (dbrecord.source_id != 0)
        unless @staff_hash[dbrecord.source_id]
          #
          #  A member of staff seems to have gone away from SB.  This
          #  shouldn't really happen, but it seems it sometimes does.
          #
          #  My approach is to delete them *only* if there is no ancillary
          #  information.
          #
          if dbrecord.element &&
             (dbrecord.element.memberships.count > 0 ||
              dbrecord.element.commitments.count > 0)
            #
            #  Useful information about this staff member which should
            #  be kept.
            #
            if dbrecord.current
              puts "Marking #{dbrecord.name} no longer current."
              dbrecord.current = false
              dbrecord.save
              staff_changed_count += 1
            end
          else
            puts "Deleting #{dbrecord.name}"
            dbrecord.destroy
            staff_deleted_count += 1
          end
        end
      end
    end
    if @verbose || staff_changed_count > 0
      puts "#{staff_changed_count} staff record(s) amended."
    end
    if @verbose || staff_loaded_count > 0
      puts "#{staff_loaded_count} staff record(s) created."
    end
    if @verbose
      puts "#{staff_unchanged_count} staff record(s) untouched."
    end
    if @verbose || staff_deleted_count > 0
      puts "#{staff_deleted_count} staff record(s) deleted."
    end
  end

  def do_locations
    locations_loaded_count    = 0
    @locations.each do |location|
      dbrecord = location.dbrecord
      #
      #  We're not actually terribly interested in SB's idea of what
      #  places are called.  Naming in SB is a mess.  As long as we can
      #  identify where is meant, we leave well alone.
      #
      unless dbrecord
        #
        #  Don't seem to have anything for this location yet.  We need
        #  to be slightly circuitous in how we do our save.
        #
        if location.save_location_to_db
          locations_loaded_count += 1
        end
      end
    end
    if @verbose || locations_loaded_count > 0
      puts "#{locations_loaded_count} location records created."
    end
  end

  def do_tutorgroups
    tg_changed_count      = 0
    tg_unchanged_count    = 0
    tg_loaded_count       = 0
    tg_reincarnated_count = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    tgmember_loaded_count    = 0
    pupils_renamed           = 0
    tg_at_start = Tutorgroup.current.count
    @tg_hash.each do |key, tg|
      #
      #  There must be a more idiomatic way of doing this.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = tg.ensure_db(self)
      tg_loaded_count          += loaded
      tg_reincarnated_count    += reincarnated
      tg_changed_count         += changed
      tg_unchanged_count       += unchanged
      tgmember_loaded_count    += member_loaded
      tgmember_removed_count   += member_removed
      tgmember_unchanged_count += member_unchanged
    end
    #
    #  It's possible that a tutor group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    tg_deleted_count = 0
    sb_tg_ids = @tg_hash.collect { |key, tg| tg.dbrecord.id }.compact
    db_tg_ids = Tutorgroup.current.collect {|dbtg| dbtg.id}
    extra_ids = db_tg_ids - sb_tg_ids
    extra_ids.each do |eid|
      dbtg = Tutorgroup.find(eid)
      puts "Tutor group #{dbtg.name} exists in the d/b but not in the files." if @verbose
      #
      #  All the pupils in this group will need to have their names updated.
      #
      erstwhile_pupils =
        dbtg.members(nil, false, true).select {|member| member.class == Pupil}
      dbtg.ceases_existence(@start_date)
      erstwhile_pupils.each do |pupil|
        pupil.reload
        if pupil.element_name != pupil.element.name
          pupil.save
          pupils_renamed += 1
        end
      end
      tg_deleted_count += 1
    end
    tg_at_end = Tutorgroup.current.count
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} tutor group records deleted."
      if pupils_renamed > 0
        puts "as a result of which, #{pupils_renamed} pupils were renamed."
      end
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} tutor group records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} tutor group records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} tutor group records created."
    end
    if @verbose || tg_reincarnated_count > 0
      puts "#{tg_reincarnated_count} tutor group records reincarnated."
    end
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from tutor groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to tutor groups."
    end
    if @verbose || tg_at_start != tg_at_end
      puts "Started with #{tg_at_start} tutor groups and finished with #{tg_at_end}."
    end
  end

  def do_teachinggroups
    groups_created_count    = 0
    groups_amended_count    = 0
    groups_unchanged_count  = 0
    pupils_added_count      = 0
    pupils_removed_count    = 0
    pupils_left_alone_count = 0
    empty_tg_count          = 0
    dbera_hash = {}
    groups_at_start = Teachinggroup.current.count
    puts "Starting working through #{@groups.size} teaching groups." if @verbose
    @groups.each do |group|
      #
      #  Can we find this group in the d/b?
      #
      dbgroup = group.dbrecord
      if dbgroup
        #
        #  Need to check the group details still match.
        #
        if group.check_and_update
          groups_amended_count += 1
        else
          groups_unchanged_count += 1
        end
      else
        #
        #  We only bother to create groups which have members, or which look
        #  like actual teaching or tutor groups.
        #
        if group.num_pupils > 0 ||
           /\A[1234567]/ =~ group.name ||
           /\AS[1234567]/ =~ group.name ||
           / Tu\Z/ =~ group.name ||
           / Chap\Z/ =~ group.name ||
           / Assem\Z/ =~ group.name
          if group.save_to_db(era: @era,
                              starts_on: @start_date)
            dbgroup = group.dbrecord
            groups_created_count += 1
          end
        end
      end
      if dbgroup
        #
        #  How do the memberships compare?  The key identifier is the id
        #  of the pupil record as provided by SB.
        #
        db_member_ids = dbgroup.members(@start_date).collect {|s| s.source_id}
        sb_member_ids = group.records.collect {|r| r.pupil_ident}
        missing_from_db = sb_member_ids - db_member_ids
        missing_from_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            puts "Adding #{pupil.dbrecord.name} to #{dbgroup.name}" unless @full_load
            dbgroup.add_member(pupil.dbrecord, @start_date)
            pupils_added_count += 1
          end
        end
        extra_in_db = db_member_ids - sb_member_ids
        extra_in_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            puts "Removing #{pupil.dbrecord.name} from #{dbgroup.name}" unless @full_load
            dbgroup.remove_member(pupil.dbrecord, @start_date)
            pupils_removed_count += 1
          end
        end
        pupils_left_alone_count += (db_member_ids.size - extra_in_db.size)
      end
    end
    #
    #  It's possible that a teaching group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    groups_deleted_count = 0
    Teachinggroup.current.each do |dbgroup|
      group = @group_hash[dbgroup.source_id]
      unless group
        puts "Teaching group #{dbgroup.name} exists in the d/b but not in the files." if @verbose
        #
        #  Need to terminate any remaining memberships, then terminate the
        #  group.  Note that nothing gets deleted, just marked as over.
        #
        dbgroup.ceases_existence(@start_date)
        groups_deleted_count += 1
      end
    end
    groups_at_end = Teachinggroup.current.count
    if @verbose || groups_created_count > 0
      puts "Created #{groups_created_count} teaching groups."
    end
    if @verbose || groups_amended_count > 0
      puts "Amended #{groups_amended_count} teaching groups."
    end
    if @verbose || groups_deleted_count > 0
      puts "Deactivated #{groups_deleted_count} teaching groups."
    end
    if @verbose
      puts "#{groups_unchanged_count} teaching groups left untouched."
      puts "#{empty_tg_count} empty teaching groups ignored."
    end
    if @verbose || pupils_added_count > 0
      puts "Added #{pupils_added_count} to teaching groups."
    end
    if @verbose || pupils_removed_count > 0
      puts "Removed #{pupils_removed_count} from teaching groups."
    end
    if @verbose
      puts "Left #{pupils_left_alone_count} where they were."
      if groups_at_start != groups_at_end
        puts "Started with #{groups_at_start} teaching groups and ended with #{groups_at_end}."
      end
    end
  end

  def get_week_letter(date)
    events = @week_letter_category.events_on(date)
    if events.size == 1
      if events[0].body == "WEEK A"
        "A"
      elsif events[0].body == "WEEK B"
        "B"
      else
        nil
      end
    else
      nil
    end
  end

  def do_timetable
    puts "Loading events from #{@start_date} to #{@era.ends_on}" if @verbose
    atomic_event_created_count         = 0
    atomic_event_deleted_count         = 0
    atomic_event_retimed_count         = 0
    atomic_event_recategorized_count   = 0
    compound_event_created_count       = 0
    compound_event_deleted_count       = 0
    compound_event_retimed_count       = 0
    compound_event_recategorized_count = 0
    resources_added_count              = 0
    resources_removed_count            = 0
    set_to_naming_count                = 0
    set_to_not_naming_count            = 0
    @start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      week_letter = get_week_letter(date)
      if week_letter
        lessons = @periods_by_week[week_letter][date.strftime("%A")]
        if lessons
          lessons = lessons.select {|lesson| lesson.exists_on?(date)}
          #
          #  We have to process compound and non-compound events separately.
          #
          dbevents = Event.events_on(date,                # Start date
                                     nil,                 # End date
                                     [@lesson_category,   # Categories
                                      @meeting_category,
                                      @supervised_study_category,
                                      @assembly_category,
                                      @chapel_category,
                                      @registration_category,
                                      @tutor_category],
                                     @event_source,       # Event source
                                     nil,                 # Resource
                                     nil,                 # Owner
                                     true)                # And non-existent
          dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
          dbids = dbatomic.collect {|dba| dba.source_id}.uniq
          dbhashes = dbcompound.collect {|dbc| dbc.source_hash}.uniq
          #
          #  A little bit of correction code.  Earlier I managed to reach
          #  the situation where two instances of the same event (from SB's
          #  point of view) were occuring on the same day.  If this happens,
          #  arbitrarily delete one of them before continuing.
          #
          deleted_something = false
          if dbids.size < dbatomic.size
            puts "Deleting #{dbatomic.size - dbids.size} duplicate events." if @verbose
            deleted_something = true
            dbids.each do |dbid|
              idsevents = dbatomic.select {|dba| dba.source_id == dbid}
              if idsevents.size > 1
                #
                #  We have one or more duplicates.
                #
                idsevents.each_with_index do |dbevent, i|
                  if i > 0
                    dbevent.destroy
                  end
                end
              end
            end
          end
          if dbhashes.size < dbcompound.size
            puts "Deleting #{dbcompound.size - dbhashes.size} duplicate events." if @verbose
            deleted_something = true
            dbhashes.each do |dbhash|
              hashesevents = dbcompound.select {|dbc| dbc.source_hash == dbhash}
              if hashesevents.size > 1
                #
                #  We have one or more duplicates.
                #
                hashesevents.each_with_index do |dbevent, i|
                  if i > 0
                    dbevent.destroy
                  end
                end
              end
            end
          end
          if deleted_something
            #
            #  And read again from the database.
            #
            dbevents = Event.events_on(date,
                                       nil,
                                       [@lesson_category,
                                        @meeting_category,
                                        @supervised_study_category,
                                        @assembly_category,
                                        @chapel_category,
                                        @registration_category,
                                        @tutor_category],
                                       @event_source,
                                       nil,
                                       nil,
                                       true)
            dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
            dbids = dbatomic.collect {|dba| dba.source_id}.uniq
            dbhashes = dbcompound.collect {|dbc| dbc.source_hash}.uniq
          end
          sbcompound, sbatomic = lessons.partition {|sbe| sbe.compound}
          sbids = sbatomic.collect {|sba| sba.timetable_ident}
          sbhashes = sbcompound.collect {|sbc| sbc.source_hash}
#          puts "#{sbatomic.size} atomic events in SB and #{dbatomic.size} in the d/b."
#          puts "#{sbcompound.size} compound events in SB and #{dbcompound.size} in the d/b."
          #
          #  First we'll do the atomic ones.
          #
          #  Anything in the database, but not in the SB files?
          #
          dbonly = dbids - sbids
          if dbonly.size > 0
            puts "Deleting #{dbonly.size} atomic events." if @verbose
            #
            #  These I'm afraid have to go.  Given only the source
            #  id we don't have enough to find the record in the d/b
            #  (because they repeat every fortnight) but happily we
            #  already have the relevant d/b record in memory.
            #
            dbonly.each do |dbo|
#              puts "Deleting record with id #{dbo}"
              dbrecord = dbatomic.find {|dba| dba.source_id == dbo}
              if dbrecord
#                puts "d/b record id is #{dbrecord.id}"
                dbrecord.destroy
              end
              atomic_event_deleted_count += 1
#              Event.find_by(source_id:        dbo,
#                            eventcategory_id: @lesson_category.id,
#                            eventsource_id:   @event_source.id).destroy
            end
          end
          #
          #  And now anything in the SB files which isn't in the d/b?
          #
          sbonly = sbids - dbids
          if sbonly.size > 0
            puts "Adding #{sbonly.size} atomic events." if @verbose
            sbonly.each do |sbo|
              lesson = @tte_hash[sbo]
              #
              #  For each of these, just create the event.  Resources
              #  will be handled later.
              #
              period_time = lesson.period_time
              event = Event.new
              event.body          = lesson.body_text(self)
              event.eventcategory = lesson.eventcategory(self)
              event.eventsource   = @event_source
              if lesson.lower_school
                event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
                else
                event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
              end
              event.approximate   = false
              event.non_existent  = lesson.suspended_on?(self, date)
              event.private       = false
              event.all_day       = false
              event.compound      = false
              event.source_id     = lesson.timetable_ident
              if event.save
                atomic_event_created_count += 1
                event.reload
                #
                #  Add it to our array of events which are in the d/b.
                #
                dbatomic << event
              else
                puts "Failed to save event #{event.inspect}"
              end
            end
          end
          #
          #  All the right atomic events should now be in the database.
          #  Run through them making sure they have the right time and
          #  the right resources.
          #
          sbatomic.each do |lesson|
            if event = dbatomic.detect {
              |dba| dba.source_id == lesson.timetable_ident
            }
              #
              #  Now have a d/b record (event) and a SB record (lesson).
              #
              changed = false
              period_time = lesson.period_time
              if lesson.lower_school
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
              else
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
              end
              if event.starts_at != starts_at
                event.starts_at = starts_at
                changed = true
              end
              if event.ends_at != ends_at
                event.ends_at = ends_at
                changed = true
              end
              if event.non_existent != lesson.suspended_on?(self, date)
                event.non_existent = lesson.suspended_on?(self, date)
#                puts "#{event.body} #{event.non_existent ? "suspended" : "un-suspended"} on #{date.to_s} at #{period_time.starts_at}"
                changed = true
              end
              if event.eventcategory_id != lesson.eventcategory(self).id
                event.eventcategory = lesson.eventcategory(self)
                atomic_event_recategorized_count += 1
                changed = true
              end
              if event.body != lesson.body_text(self)
                event.body = lesson.body_text(self)
                changed = true
              end
              if changed
                if event.save
                  atomic_event_retimed_count += 1
                else
                  puts "Failed to save amended event record."
                end
              end
              #
              #  And what about the resources?  We use our d/b element ids
              #  as unique identifiers.
              #
              sb_element_ids = Array.new
              sb_group_element_id = nil
              if group = @group_hash[lesson.group_ident]
                sb_element_ids << group.element_id
                #
                #  Atomic events only ever have one group, and if they have
                #  a group then they are lessons, and the group names the
                #  event.
                #
                sb_group_element_id = group.element_id
              end
              if staff = @staff_hash[lesson.staff_ident]
                sb_element_ids << staff.element_id
              end
              if location = @location_hash[lesson.room_ident]
                sb_element_ids << location.element_id
              end
              #
              #  The element_id method can return nil
              #
              sb_element_ids.compact!
              db_element_ids = event.commitments.collect {|c| c.element_id}
              db_only = db_element_ids - sb_element_ids
              sb_only = sb_element_ids - db_element_ids
              sb_only.each do |sbid|
                c = Commitment.new
                c.event       = event
                c.element_id  = sbid
                if sbid == sb_group_element_id
                  c.names_event = true
                end
                c.save
                resources_added_count += 1
              end
              event.reload
              if db_only.size > 0
                event.commitments.each do |c|
                  if db_only.include?(c.element_id) && !c.covering
                    c.destroy
                    resources_removed_count += 1
                  end
                end
              end
              #
              #  Just temporary
              #
              shared = sb_element_ids - sb_only
              if shared.size > 0
                event.commitments.each do |c|
                  if shared.include?(c.element_id)
                    if c.names_event && c.element_id != sb_group_element_id
                      puts "#{event.body} disagrees on event naming (A)" if @verbose
                      c.names_event = false
                      c.save
                      set_to_not_naming_count += 1
                    elsif !c.names_event && c.element_id == sb_group_element_id
                      puts "#{event.body} disagrees on event naming (B)" if @verbose
                      c.names_event = true
                      c.save
                      set_to_naming_count += 1
                    end
                  end
                end
              end
            else
              puts "Very odd - d/b record #{lesson.timetable_ident} has disappeared."
            end
          end
          #
          #  And now on to the compound events.
          #
          #  Anything in the database, but not in the SB files?
          #
          dbonly = dbhashes - sbhashes
          if dbonly.size > 0
            puts "Deleting #{dbonly.size} compound events." if @verbose
            #
            #  These I'm afraid have to go.  Given only the source
            #  hash we don't have enough to find the record in the d/b
            #  (because they repeat every fortnight) but happily we
            #  already have the relevant d/b record in memory.
            #
            dbonly.each do |dbo|
              dbrecord = dbcompound.find {|dbc| dbc.source_hash == dbo}
              if dbrecord
                dbrecord.destroy
              end
              compound_event_deleted_count += 1
            end
          end
          #
          #  And now anything in the SB files which isn't in the d/b?
          #
          sbonly = sbhashes - dbhashes
          if sbonly.size > 0
            puts "Adding #{sbonly.size} compound events." if @verbose
            sbonly.each do |sbo|
              lesson = @ctte_hash[sbo]
              period_time = lesson.period_time
              #
              #  Although we're not going to attach the teachinggroup
              #  at the moment, we may need to find it to use its name
              #  as the event name.
              #
              dbgroup = nil
              unless lesson.meeting?
                if group = @group_hash[lesson.group_idents[0]]
                  dbgroup = group.dbrecord
                end
              end
              if lesson.meeting? || dbgroup
                event = Event.new
                event.body          = lesson.body_text(self)
                event.eventcategory = lesson.eventcategory(self)
                event.eventsource   = @event_source
                if lesson.lower_school
                  event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
                else
                  event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
                end
                event.approximate   = false
                event.non_existent  = lesson.suspended_on?(self, date)
                event.private       = false
                event.all_day       = false
                event.compound      = true
                event.source_hash   = lesson.source_hash
                if event.save
                  compound_event_created_count += 1
                  event.reload
                  #
                  #  Add it to our array of events which are in the d/b.
                  #
                  dbcompound << event
                else
                  puts "Failed to save event #{event.inspect}"
                end
              else
                puts "Not loading - lesson = #{lesson.source_hash}"
                puts "  original id = #{lesson.timetable_ident}"
#                puts "  period = #{period}"
                puts "  lesson.meeting = #{lesson.meeting?}"
                puts "  dbgroup = #{dbgroup}"
                puts "  group_ident = #{lesson.group_idents[0]}"
    #            puts "Not loading - lesson = #{lesson.timetable_ident}, dbgroup = #{dbgroup ? dbgroup.name : "Not found"}"
              end
            end
          end
          #
          #  All the right compound events should now be in the database.
          #  Run through them making sure they have the right time and
          #  the right resources.
          #
          sbcompound.each do |lesson|
            if event = dbcompound.detect {
              |dbc| dbc.source_hash == lesson.source_hash
            }
              #
              #  Now have a d/b record (event) and a SB record (lesson).
              #
              changed = false
              period_time = lesson.period_time
              if lesson.lower_school
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period_time.ls_ends_at}")
              else
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
              end
              if event.starts_at != starts_at
                event.starts_at = starts_at
                changed = true
              end
              if event.ends_at != ends_at
                event.ends_at = ends_at
                changed = true
              end
              if event.non_existent != lesson.suspended_on?(self, date)
                event.non_existent = lesson.suspended_on?(self, date)
#                puts "#{event.body} #{event.non_existent ? "suspended" : "un-suspended"} on #{date.to_s} at #{period_time.starts_at}"
                changed = true
              end
#              if event.eventcategory_id == @registration_category.id ||
#                 event.eventcategory_id == @tutor_category.id
#                puts "Compound event #{event.id} has a surprising category."
#              end
              if event.eventcategory_id != lesson.eventcategory(self).id
                event.eventcategory = lesson.eventcategory(self)
                compound_event_recategorized_count += 1
                changed = true
              end
              if event.body != lesson.body_text(self)
                event.body = lesson.body_text(self)
                changed = true
              end
              if changed
                if event.save
                  compound_event_retimed_count += 1
                else
                  puts "Failed to save amended compound event record."
                end
              end
              #
              #  And what about the resources?  We use our d/b element ids
              #  as unique identifiers.
              #
              sb_element_ids = Array.new
              lesson.group_idents.each do |gi|
                if group = @group_hash[gi]
                  sb_element_ids << group.element_id
                end
              end
              lesson.staff_idents.each do |si|
                if staff = @staff_hash[si]
                  sb_element_ids << staff.element_id
                end
              end
              lesson.room_idents.each do |ri|
                if location = @location_hash[ri]
                  sb_element_ids << location.element_id
                end
              end
              #
              #  The element_id method can return nil
              #
              sb_element_ids.compact!
              db_element_ids = event.commitments.collect {|c| c.element_id}
              db_only = db_element_ids - sb_element_ids
              sb_only = sb_element_ids - db_element_ids
              sb_only.each do |sbid|
                c = Commitment.new
                c.event      = event
                c.element_id = sbid
                c.save
                resources_added_count += 1
              end
              event.reload
              if db_only.size > 0
                event.commitments.each do |c|
                  if db_only.include?(c.element_id) && !c.covering
                    c.destroy
                    resources_removed_count += 1
                  end
                end
              end
            else
              puts "Very odd - d/b record #{lesson.source_hash} has disappeared."
            end
          end

        else
          puts "Couldn't find lesson entries for #{date.strftime("%A")} of week #{week_letter}."
        end
      else
        puts "No week letter for #{date}" if @verbose
      end
    end
    if atomic_event_created_count > 0 || @verbose
      puts "#{atomic_event_created_count} atomic timetable events added."
    end
    if atomic_event_deleted_count > 0 || @verbose
      puts "#{atomic_event_deleted_count} atomic timetable events deleted."
    end
    if atomic_event_retimed_count > 0 || @verbose
      puts "#{atomic_event_retimed_count} atomic timetable events amended."
    end
    if atomic_event_recategorized_count > 0 || @verbose
      puts "#{atomic_event_recategorized_count} atomic timetable events re-categorized."
    end
    if compound_event_created_count > 0 || @verbose
      puts "#{compound_event_created_count} compound timetable events added."
    end
    if compound_event_deleted_count > 0 || @verbose
      puts "#{compound_event_deleted_count} compound timetable events deleted."
    end
    if compound_event_retimed_count > 0 || @verbose
      puts "#{compound_event_retimed_count} compound timetable events amended."
    end
    if compound_event_recategorized_count > 0 || @verbose
      puts "#{compound_event_recategorized_count} compound timetable events re-categorized."
    end
    if resources_added_count > 0 || @verbose
      puts "#{resources_added_count} resources added to timetable events."
    end
    if resources_removed_count > 0 || @verbose
      puts "#{resources_removed_count} resources removed from timetable events."
    end
    if set_to_naming_count > 0 || @verbose
      puts "#{set_to_naming_count} commitments set as naming events."
    end
    if set_to_not_naming_count > 0 || @verbose
      puts "#{set_to_not_naming_count} commitments set as not naming events."
    end
  end

  #
  #  Turn a SB date id into a real date, guarding against being given
  #  an invalid one.
  #
  def safe_date(sb_date_id)
    @date_hash[sb_date_id] ? @date_hash[sb_date_id].date : nil
  end

  #
  #  Add cover to existing lessons.
  #
  def do_cover
    covers_added = 0
    covers_amended = 0
    covers_deleted = 0
    invigilations_added = 0
    invigilations_amended = 0
    invigilations_deleted = 0
    cover_clashes = []
    cover_oddities = []
    covers_processed = 0
    invigilations_processed = 0
    #
    #  First group all the proposed covers by date, discarding any which
    #  are earlier than we are interested in.
    #
    covers_by_date = Hash.new
    invigilations_by_date = Hash.new
    max_cover_date = @start_date
    max_invigilation_date = @start_date
    @staffcovers.each do |sc|
      if sc.prepare(self, cover_oddities)
        if sc.cover_or_invigilation == :cover
          covers_processed += 1
          if covers_by_date[sc.date]
            covers_by_date[sc.date] << sc
          else
            covers_by_date[sc.date] = [sc]
            if sc.date > max_cover_date
              max_cover_date = sc.date
            end
          end
        else
          invigilations_processed += 1
          if invigilations_by_date[sc.date]
            invigilations_by_date[sc.date] << sc
          else
            invigilations_by_date[sc.date] = [sc]
            if sc.date > max_invigilation_date
              max_invigilation_date = sc.date
            end
          end
        end
      end
    end
    #
    #  Now for the actual processing.  Note that we may well not do these
    #  in date order, but that shouldn't actually matter.
    #
    #  Second thought - we do need to do them in order, because we need
    #  to process even those dates where we haven't been given any cover
    #  records.  There may be one in our d/b on that date which needs
    #  removing.
    #
    @start_date.upto(max_cover_date) do |date|
      sb_covers = covers_by_date[date] || []
      #
      #  Now need to get the existing covers for this date and check
      #  that they match.
      #
      existing_covers =
        Commitment.commitments_on(startdate: date,
                                  include_nonexistent: true).covering_commitment
      sb_ids = sb_covers.collect {|sc| sc.source_id}.uniq
      db_ids = existing_covers.collect {|ec| ec.source_id}.uniq
      db_only = db_ids - sb_ids
      db_only.each do |db_id|
        #
        #  It's possible there's more than one db record with the same
        #  id - for historical reasons this may be nil.  Need to get rid
        #  of all of them.
        #
        if @verbose
          puts "Deleting covers with source_id #{db_id ? db_id : "nil"}."
        end
        existing_covers.select {|ec| ec.source_id == db_id}.each do |ec|
          ec.destroy
          covers_deleted += 1
        end
      end
      sb_covers.each do |sbc|
        added, amended, deleted, clashes, oddities = sbc.ensure_db(self)
        covers_added += added
        covers_amended += amended
        covers_deleted += deleted
        cover_clashes += clashes
        cover_oddities += oddities
      end
    end
    #
    #  And now the invigilations.
    #
    @start_date.upto(max_invigilation_date) do |date|
      sb_invigilations = invigilations_by_date[date] || []
      existing_invigilations = Event.events_on(date,
                                               date, 
                                               @invigilation_category,
                                               @event_source)
      #
      #  With invigilations, the source id goes in the event.
      #
      sb_ids = sb_invigilations.collect {|si| si.source_id}.uniq
      db_ids = existing_invigilations.collect {|ei| ei.source_id}.uniq
      db_only = db_ids - sb_ids
      db_only.each do |db_id|
        existing_invigilations.select {|ei| ei.source_id == db_id}.each do |ei|
          ei.destroy
          invigilations_deleted += 1
        end
      end
      sb_invigilations.each do |sbi|
        added, amended, deleted, clashes,oddities = sbi.ensure_db(self)
        invigilations_added += added
        invigilations_amended += amended
        invigilations_deleted += deleted
        cover_clashes += clashes
        cover_oddities += oddities
      end
    end
    if covers_added > 0 || @verbose
      puts "Added #{covers_added} instances of cover."
    end
    if covers_amended > 0 || @verbose
      puts "Amended #{covers_amended} instances of cover."
    end
    if covers_deleted > 0 || @verbose
      puts "Deleted #{covers_deleted} instances of cover."
    end
    if invigilations_added > 0 || @verbose
      puts "Added #{invigilations_added} instances of invigilation."
    end
    if invigilations_amended > 0 || @verbose
      puts "#{invigilations_amended} amendments to instances of invigilation."
    end
    if invigilations_deleted > 0 || @verbose
      puts "Deleted #{invigilations_deleted} instances of invigilation."
    end
    puts "Processed #{covers_processed} covers and #{invigilations_processed} invigilations."
    if cover_clashes.size > 0 ||
       cover_oddities.size > 0
      puts "#{cover_clashes.size} apparent cover clashes."
      puts "#{cover_oddities.size} apparent cover oddities."
      if @send_emails
        User.arranges_cover.each do |user|
          UserMailer.cover_clash_email(user,
                                       cover_clashes,
                                       cover_oddities).deliver
        end
      end
    else
      puts "No apparent cover issues."
    end
  end

  def do_other_half
    puts "Processing Other Half" if @verbose
    puts "#{@other_half.count} events to process." if @verbose
    oh_events_added_count = 0
    oh_events_retimed_count = 0
    oh_event_commitments_added_count = 0
    oh_event_commitments_removed_count = 0
    @other_half.sort.each do |oh|
#      puts "#{oh.activity_name} from #{oh.starts_at.to_s} to #{oh.ends_at.to_s}"
#      unless oh.staff.empty?
#        puts "With #{oh.staff.collect {|s| s.name}.join(", ")}"
#      end
      if oh.starts_at >= @start_date
        event = Event.find_by(source_id: oh.oh_occurence_ident,
                              eventcategory_id: @other_half_category.id,
                              eventsource_id: @event_source.id)
        if event
          #
          #  The event seems to be there OK.  Is its timing right?
          #
          modified = false
          if event.starts_at != oh.starts_at
            event.starts_at = oh.starts_at
            modified = true
          end
          if event.ends_at != oh.ends_at
            event.ends_at = oh.ends_at
            modified = true
          end
          if modified
            oh_events_retimed_count += 1
            unless event.save
              puts "Failed to update timing for #{oh.activity_name}"
            end
            event.reload
          end
        else
          #
          #  Event does not yet exist.  Need to create it.
          #
          event = Event.new
          event.body          = oh.activity_name
          event.eventcategory = @other_half_category
          event.eventsource   = @event_source
          event.starts_at     = oh.starts_at
          event.ends_at       = oh.ends_at
          event.approximate   = false
          event.non_existent  = false
          event.private       = false
          event.all_day       = false
          event.compound      = false
          event.source_id     = oh.oh_occurence_ident
          if event.save
            oh_events_added_count += 1
            event.reload
          else
            puts "Failed to save OH event #{oh.activity_name}"
          end
        end
        #
        #  Event is now in the database.  Need to ensure it has the
        #  right staff, group and location.  Treat all resources just as
        #  resources.
        #
        #  Use the element id as a unique identifier.
        #
        sb_element_ids = Array.new
        oh.staff.each do |s|
          if s.dbrecord && s.dbrecord.active && s.dbrecord.element
            sb_element_ids << s.dbrecord.element.id
          end
        end
        if oh.group && oh.group.dbrecord
          sb_element_ids << oh.group.dbrecord.element.id
        end
        if oh.location &&
           oh.location.dbrecord &&
           oh.location.dbrecord.location &&
           oh.location.dbrecord.location.active
          sb_element_ids << oh.location.dbrecord.location.element.id
        end
        db_element_ids = event.commitments.collect {|c| c.element_id}
        db_only = db_element_ids - sb_element_ids
        sb_only = sb_element_ids - db_element_ids
        sb_only.each do |sbid|
          c = Commitment.new
          c.event      = event
          c.element_id = sbid
          c.save
          oh_event_commitments_added_count += 1
        end
        event.reload
        if db_only.size > 0
          event.commitments.each do |c|
            if db_only.include?(c.element_id)
              c.destroy
              oh_event_commitments_removed_count += 1
            end
          end
        end
      end
    end
    #
    #  How do we go about deleting OH activites which have been deleted
    #  from SB?
    #
    events = Event.eventsource_id(@event_source.id).
                   eventcategory_id(@other_half_category.id).
                   beginning(@start_date).
                   until(@era.ends_on)
    puts "Checking #{events.size} other half events for possible deletion." if @verbose
    oh_events_deleted_count = 0
    events.each do |event|
      unless @other_half_hash[event.source_id]
        event.destroy
        oh_events_deleted_count += 1
      end
    end
    if @verbose || oh_events_added_count > 0
      puts "Added #{oh_events_added_count} other half events."
    end
    if @verbose || oh_events_retimed_count > 0
      puts "Retimed #{oh_events_retimed_count} other half events."
    end
    if @verbose || oh_event_commitments_added_count > 0
      puts "Added #{oh_event_commitments_added_count} commitments to other half events."
    end
    if @verbose || oh_event_commitments_removed_count > 0
      puts "Removed #{oh_event_commitments_removed_count} commitments to other half events."
    end
    if @verbose || oh_events_deleted_count > 0
      puts "Deleted #{oh_events_deleted_count} other half events."
    end
  end

  #
  #  Pass the name of the group and array of the members that should be
  #  in it.  Note that the entity ids are used to identify the individual
  #  members, so they need to be all of the same class, or else there is
  #  scope for confusion.
  #
  #  These used to go in the current era, but now go in the perpetual
  #  era.  Any left over in the current era get moved to the perpetual
  #  era.
  #
  def ensure_membership(group_name, members, member_class)
    members_added   = 0
    members_removed = 0
    group = Group.system.vanillagroups.find_by(name: group_name,
                                               era_id: Setting.perpetual_era.id)
    unless group
      group = Group.system.vanillagroups.find_by(name: group_name,
                                                 era_id: @era.id)
      if group
        #
        #  Need to move this to the perpetual era.
        #
        group.era     = Setting.perpetual_era
        group.ends_on = nil
        group.save
        puts "Moved group #{group.name} to the perpetual era."
      end
    end
    unless group
      group = Vanillagroup.new(name:      group_name,
                               era:       Setting.perpetual_era,
                               starts_on: @start_date,
                               current:   true)
      group.save!
      group.reload
      puts "\"#{group_name}\" group created."
    end

    #
    #  We don't intend to have mixtures of types in groups, but we might.
    #  Therefore use element_ids as our unique identifiers, rather than
    #  the entity's ids.  The latter are unique for a given type of entity,
    #  but not across types.
    #
    intended_member_ids = members.collect {|m| m.element.id}
    current_member_ids = group.members(@start_date, false, false).collect {|m| m.element.id}
    to_remove = current_member_ids - intended_member_ids
    to_add = intended_member_ids - current_member_ids
    to_remove.each do |member_id|
      group.remove_member(Element.find(member_id), @start_date)
      members_removed += 1
    end
    to_add.each do |member_id|
      group.add_member(Element.find(member_id), @start_date)
      members_added += 1
    end
    if @verbose || members_removed > 0
      puts "#{members_removed} removed from \"#{group_name}\" group."
    end
    if @verbose || members_added > 0
      puts "#{members_added} added to \"#{group_name}\" group."
    end
  end

  #
  #  Create some hard-coded special groups, using information available
  #  only at this point.
  #
  def do_auto_groups
    ensure_membership("All staff",
                      Staff.active.current,
                      Staff)
    ensure_membership("Teaching staff (according to SB)",
                      Staff.active.current.teaching,
                      Staff)
    #
    #  Staff by house they are tutors in.
    #
    all_tutors = []
    tutors_by_year = {}
    tges_by_year = {}
    @house_hash.each do |house, tutorgroups|
      tutors = []
      tges = []
      house_tges_by_year = {}
      tutorgroups.each do |tg|
        s = Staff.find(tg.staff_id)
        tutors << s
        all_tutors << s
        if tutors_by_year[tg.year_group]
          tutors_by_year[tg.year_group] << s
        else
          tutors_by_year[tg.year_group] = [s]
        end
        #
        #  Unfortunately, as the sixth year tutor groups are now
        #  muddled up, we need to sort the tutorgroupentries individually.
        #
        tg.records.each do |tge|
          year_group = @year_hash[tge.year_ident].year_num - 6
          if tges_by_year[year_group]
            tges_by_year[year_group] << tge
          else
            tges_by_year[year_group] = [tge]
          end
          if house_tges_by_year[year_group]
            house_tges_by_year[year_group] << tge
          else
            house_tges_by_year[year_group] = [tge]
          end
          tges << tge
        end
      end
      pupils = tges.collect {|tge| @pupil_hash[tge.pupil_ident].dbrecord}.compact
      if house == "Lower School"
        ensure_membership("#{house} tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house} pupils",
                          pupils,
                          Pupil)
      else
        ensure_membership("#{house} House tutors",
                          tutors,
                          Staff)
        ensure_membership("#{house} House pupils",
                          pupils,
                          Pupil)
        house_tges_by_year.each do |year_group, tges|
          pupils = tges.collect {|tge| @pupil_hash[tge.pupil_ident].dbrecord}.compact
          ensure_membership("#{house} House #{year_group.ordinalize} year",
                            pupils,
                            Pupil)
        end
      end
    end
    middle_school_tutors = []
    upper_school_tutors = []
    tutors_by_year.each do |year_group, tutors|
      ensure_membership("#{year_group.ordinalize} year tutors",
                        tutors,
                        Staff)
      #
      #  Lower school tutors already have their own group from the house
      #  processing.
      #
      if year_group == 3 ||
         year_group == 4 ||
         year_group == 5
        middle_school_tutors += tutors
      elsif year_group == 6 ||
            year_group == 7
        upper_school_tutors += tutors
      end
    end
    tges_by_year.each do |year_group, tges|
      pupils = tges.collect {|tge| @pupil_hash[tge.pupil_ident].dbrecord}.compact
      ensure_membership("#{year_group.ordinalize} year",
                        pupils,
                        Pupil)
    end
    ensure_membership("Middle school tutors", middle_school_tutors, Staff)
    ensure_membership("Upper school tutors", upper_school_tutors, Staff)
    ensure_membership("All tutors", all_tutors, Staff)
    ensure_membership("All pupils",
                      Pupil.current,
                      Pupil)
    WhoTeachesWhat.teachers_by_subject do |subject, teachers|
      dbteachers = teachers.collect {|t| @staff_hash[t.staff_ident].dbrecord}.compact.select {|dbr| dbr.active}
      if dbteachers.size > 0
        ensure_membership("#{subject} teachers",
                          dbteachers,
                          Staff)
      else
        puts "Subject \"#{subject}\" has no apparent teachers."
      end
    end
    WhoTeachesWhat.teachers_by_subject_and_year do |subject, year_num, teachers|
      dbteachers = teachers.collect {|t| @staff_hash[t.staff_ident].dbrecord}.compact.select {|dbr| dbr.active}
      if dbteachers.size > 0
        ensure_membership("#{(year_num - 6).ordinalize} year #{subject} teachers",
                          dbteachers,
                          Staff)
      else
        puts "Subject \"#{subject}\" has no apparent teachers."
      end
    end
    WhoTeachesWhat.teachers_by_year do |year_num, teachers|
      dbteachers = teachers.collect {|t| @staff_hash[t.staff_ident].dbrecord}.compact.select {|dbr| dbr.active}
      if dbteachers.size > 0
        ensure_membership("#{(year_num - 6).ordinalize} year teachers",
                          dbteachers,
                          Staff)
      else
        puts "Year \"#{year_num}\" has no apparent teachers."
      end
    end
    WhoTeachesWhat.groups_by_subject do |subject, groups|
      dbgroups =
        groups.collect {|g| @group_hash[g.group_ident].dbrecord}.compact
      if dbgroups.size > 0
        ensure_membership("#{subject} pupils",
                          dbgroups,
                          Group)
      else
        puts "Subject \"#{subject}\" has no apparent groups."
      end
    end
    WhoTeachesWhat.groups_by_subject_and_year do |subject, year_num, groups|
      dbgroups = groups.collect {|g| @group_hash[g.group_ident].dbrecord}.compact
      if dbgroups.size > 0
        ensure_membership("#{(year_num - 6).ordinalize} year #{subject} pupils",
                          dbgroups,
                          Group)
      else
        puts "Subject \"#{subject}\" has no apparent groups."
      end
    end
    ps_invigilators =
      WhoTeachesWhat.ps_invigilators.collect {|t|
        t.dbrecord
#        @staff_hash[t.staff_ident].dbrecord
      }.compact.select {|dbr| dbr.active}
    if ps_invigilators.size > 0
      ensure_membership("Supervised study invigilators",
                        ps_invigilators,
                        Staff)
    else
      puts "There don't seem to be any supervised study invigilators."
    end
    actual_teachers =
      WhoTeachesWhat.all_teachers.collect {|t|
        t.dbrecord
      }.compact.select {|dbr| dbr.active}
    if actual_teachers.size > 0
      ensure_membership("Teaching staff",
                        actual_teachers,
                        Staff)
    else
      puts "Don't seem to have any teachers at all."
    end
#    WhoStudiesWhat.pupils_by_subject do |subject, pupils|
#      dbpupils = pupils.collect {|p| @pupil_hash[p.pupil_ident].dbrecord}.compact
#      if dbpupils.size > 0
#        ensure_membership("#{subject} pupils",
#                          dbpupils,
#                          Pupil)
#      else
#        puts "Subject \"#{subject}\" has no apparent pupils."
#      end
#    end
#    WhoStudiesWhat.pupils_by_subject_and_year do |subject, year_num, pupils|
#      dbpupils = pupils.collect {|p| @pupil_hash[p.pupil_ident].dbrecord}.compact
#      if dbpupils.size > 0
#        ensure_membership("#{(year_num - 6).ordinalize} year #{subject} pupils",
#                          dbpupils,
#                          Pupil)
#      else
#        puts "Subject \"#{subject}\" has no apparent pupils."
#      end
#    end
  end

  def do_extra_groups
    EXTRA_GROUP_FILES.each do |control_data|
      file_data =
        YAML.load(
          File.open(Rails.root.join(IMPORT_DIR, control_data[:file_name])))
      file_data.each do |group_name, members|
        if members
          dbrecords = members.collect {|m|
            if control_data[:dbclass].respond_to?(:active)
              dbrecord = control_data[:dbclass].active.current.find_by(name: m)
            else
              dbrecord = control_data[:dbclass].current.find_by(name: m)
            end
            unless dbrecord
              puts "Can't find #{m} for extra group #{group_name}"
            end
            dbrecord
          }.compact
        else
          dbrecords = []
        end
        ensure_membership(group_name, dbrecords, control_data[:dbclass])
      end
    end
  end

  def get_extra_suspensions
    EXTRA_SUSPENSION_FILES.each do |file_name|
      extra_suspensions =
        YAML.load(
          File.open(Rails.root.join(IMPORT_DIR, file_name)))
      extra_suspensions.each do |es|
#        puts "Got an extra suspension record."
        hiatus = SB_SuspendedLesson.create_extra(es)
        if hiatus.occurs_after?(@start_date)
          @hiatuses << hiatus
        end
      end
    end
  end

  def do_duties
    puts "Processing duties" if @verbose
    duties_added_count = 0
    duties_deleted_count = 0
    resources_added_count = 0
    resources_removed_count = 0
    file_data =
      YAML.load(
        File.open(Rails.root.join(IMPORT_DIR, "Duties.yml")))
    #raise file_data.inspect
    @start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      week_letter = get_week_letter(date)
      if week_letter
        duties = file_data[week_letter][date.strftime("%A")]
        if duties && duties.size > 0
          existing_duties = @duty_category.events_on(date, date, @yaml_source)
          #
          #  We count duties from our input file and the database as being
          #  the same one if they have the same title, the same start time
          #  and the same end time.
          #
          duties.each do |duty|
            starts_at =
              Time.zone.parse("#{date.to_s} #{duty[:starts]}")
            ends_at =
              Time.zone.parse("#{date.to_s} #{duty[:ends]}")
            existing_duty = existing_duties.detect {|ed|
              ed.body      == duty[:title] &&
              ed.starts_at == starts_at &&
              ed.ends_at   == ends_at
            }
            if existing_duty
              #
              #  Remove from the array.  We will deal with any leftovers
              #  at the end.
              #
              existing_duties = existing_duties - [existing_duty]
            else
              #
              #  Event needs creating in the database.
              #
              existing_duty = Event.new
              existing_duty.body = duty[:title]
              existing_duty.eventcategory = @duty_category
              existing_duty.eventsource   = @yaml_source
              existing_duty.starts_at     = starts_at
              existing_duty.ends_at       = ends_at
              existing_duty.save!
              existing_duty.reload
              duties_added_count += 1
            end
            #
            #  Now check that the resources match.
            #
            element_id = nil
            if duty[:staff]
              staff = Staff.find_by(initials: duty[:staff])
              if staff
                element_id = staff.element.id
              end
            elsif duty[:group]
              group = Group.find_by(name: duty[:group])
              if group
                element_id = group.element.id
              end
            end
            if element_id
              required_ids = [element_id]
              existing_ids = existing_duty.elements.collect {|e| e.id}
              db_only = existing_ids - required_ids
              input_only = required_ids - existing_ids
              if db_only.size > 0
                existing_duty.commitments.each do |c|
                  if db_only.include?(c.element_id)
                    c.destroy
                    resources_removed_count += 1
                  end
                end
              end
              input_only.each do |id|
                c = Commitment.new
                c.event_id = existing_duty.id
                c.element_id = id
                c.save!
                resources_added_count += 1
              end
            else
              puts "Couldn't find duty resource for #{duty.inspect}"
            end
          end
          #
          #  Any of the existing duties left?
          #
          existing_duties.each do |ed|
            ed.destroy
            duties_deleted_count += 1
          end
        else
          puts "Couldn't find duties for #{date.strftime("%A")} of week #{week_letter}."
        end
      end
    end
    if duties_added_count > 0 || @verbose
      puts "Added #{duties_added_count} duty events."
    end
    if duties_deleted_count > 0 || @verbose
      puts "Deleted #{duties_deleted_count} duty events."
    end
    if resources_added_count > 0 || @verbose
      puts "Added #{resources_added_count} resources to duty events."
    end
    if resources_removed_count > 0 || @verbose
      puts "Removed #{resources_removed_count} resources from duty events."
    end
  end

  def do_taggroups
    tg_loaded_count          = 0
    tg_reincarnated_count    = 0
    tg_changed_count         = 0
    tg_unchanged_count       = 0
    tg_deleted_count         = 0
    tgmember_loaded_count    = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    @taggroups.each do |tg|
      #
      #  We only bother with tag groups which belong to an identifiable
      #  member of staff, and where that member of staff has already
      #  logged on to Scheduler.  This has been checked at initialisation.
      #
      loaded,
      reincarnated,
      changed,
      unchanged,
      member_loaded,
      member_removed,
      member_unchanged = tg.ensure_db(self)
      tg_loaded_count          += loaded
      tg_reincarnated_count    += reincarnated
      tg_changed_count         += changed
      tg_unchanged_count       += unchanged
      tgmember_loaded_count    += member_loaded
      tgmember_removed_count   += member_removed
      tgmember_unchanged_count += member_unchanged
    end
    #
    #  And are there any in the database which have disappeared from
    #  SB?  This is the only way they're going to get deleted, since
    #  users can't delete them through the Scheduler web i/f.
    #
    Group.taggroups.all.each do |dbtg|
      unless taggroup_hash[dbtg.source_id]
        puts "Tag group \"#{dbtg.name}\" seems to have gone from SB."
        dbtg.ceases_existence
        tg_deleted_count += 1
      end
    end
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} tag group records deleted."
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} tag group records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} tag group records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} tag group records created."
    end
    if @verbose || tg_reincarnated_count > 0
      puts "#{tg_reincarnated_count} tag group records reincarnated."
    end
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from tag groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to tag groups."
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

  SB_Loader.new(options) do |loader|
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
      loader.do_cover
      finished(options, "cover")
      loader.do_other_half
      finished(options, "other half")
      loader.do_auto_groups
      finished(options, "automatic groups")
      loader.do_extra_groups
      finished(options, "extra groups")
      loader.do_duties
      finished(options, "duties")
      loader.do_taggroups
      finished(options, "tagggroups")
    end
  end
rescue RuntimeError => e
  puts e
end

