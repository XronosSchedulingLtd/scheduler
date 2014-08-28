#!/usr/bin/env ruby
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
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
    def slurp(loader)
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
        if entries.size > 0
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
      newrecord.send("#{key_field}=",
                     self.send("#{key_field}"))
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
      if @belongs_to_era
        find_hash = { key_field => self.send("#{key_field}"),
                      :era_id => self.instance_variable_get("@era_id") }
      else
        find_hash = { key_field => self.send("#{key_field}") }
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

  def adjust(loader)
  end

  def wanted?(loader)
    true
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
    @era_id = loader.era.id
  end

  def wanted?(loader)
    #
    #  We only want groups related to our current academic year.
    #  Note that groups must be loaded from file after curriculum and
    #  academic year, or they'll all get rejected.
    #
    curriculum = loader.curriculum_hash[@curriculum_ident]
    !!(curriculum && curriculum.ac_year_ident == loader.era.source_id)
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

  attr_accessor :time

  def adjust(loader)
    if @teaching_period == 1
      @teaching_period = true
    else
      @teaching_period = false
    end
  end

  def week_letter
    @week_id == 1 ? "A" : "B"
  end

  def wanted?(loader)
    true
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
  TIME_CORRECTIONS = [PT_Correction[510, 540, 515, 535],  # 08:35 - 08:55
                      PT_Correction[540, 595, 540, 590],  # 09:00 - 09:50
                      PT_Correction[670, 730, 670, 725],  # 11:10 - 12:05
                      PT_Correction[730, 790, 730, 785],  # 12:10 - 13:05
                      PT_Correction[840, 900, 840, 895],  # 14:00 - 14:55
                      PT_Correction[900, 960, 900, 955],  # 15:00 - 15:55
                      PT_Correction[825, 885, 825, 880],  # 13:45 - 14:40
                      PT_Correction[730, 770, 730, 765],  # 12:10 - 12:45
                      PT_Correction[770, 810, 770, 805]]  # 12:50 - 13:25

  include Slurper

  attr_reader :starts_at, :ends_at

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
     Column["UserIdent",         :staff_ident,    true]]


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

  def adjust(loader)
  end

  def wanted?(loader)
    true
  end

  def source_id
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

  WANTED_SUBJECTS = ["Art",
                     "Biology",
                     "Chemistry",
                     "Classical Civilisation",
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
                     "Mandarin",
                     "Mathematics",
                     "Music",
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


class SB_Timetableentry
  FILE_NAME = "timetable.csv"
  REQUIRED_COLUMNS = [Column["TimetableIdent", :timetable_ident, true],
                      Column["GroupIdent",     :group_ident,     true],
                      Column["StaffIdent",     :staff_ident,     true],
                      Column["RoomIdent",      :room_ident,      true],
                      Column["Period",         :period_ident,    true],
                      Column["AcYearIdent",    :ac_year_ident,   true],
                      Column["TimeNote",       :time_note,       false]]

  include Slurper

  attr_accessor :compound,
                :source_hash,
                :staff_idents,
                :group_idents,
                :room_idents,
                :lower_school


  def initialize
    @compound = false
    @source_hash = ""
    @staff_idents = []
    @group_idents = []
    @room_idents  = []
    @body_text = nil
    @lower_school = false
  end

  def adjust(loader)
  end

  def wanted?(loader)
    #
    #  For now we require either that they involve a teaching group
    #  (a normal lesson) or they have a time_note (usually a meeting).
    #
    #  They must also involve *some* known resource - a member of
    #  staff or a group of pupils.
    #
    @ac_year_ident == loader.era.source_id &&
    (@group_ident != nil || !@time_note.blank?) &&
    (loader.staff_hash[self.staff_ident] != nil ||
     loader.group_hash[self.group_ident] != nil)
  end

  def <=>(other)
    self.timetable_ident <=> other.timetable_ident
  end

  def atomic?
    !@compound
  end

  def identify_ls(loader)
    if atomic?
      #
      #  We need to have a group associated and the year for that group
      #  needs to be 7 or 8.
      #
      group = loader.group_hash[self.group_ident]
      if group
        year = loader.year_hash[group.year_ident]
        if year && (year.year_num == 7 || year.year_num == 8)
          @lower_school = true
        end
      end
    else
      if self.group_idents.size > 0
        group = loader.group_hash[self.group_idents[0]]
        if group
          year = loader.year_hash[group.year_ident]
          if year && (year.year_num == 7 || year.year_num == 8)
            @lower_school = true
          end
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

  def eventcategory(loader)
    if self.meeting?
      loader.meeting_category
    elsif self.body_text(loader) == "Assembly"
      loader.assembly_category
    elsif self.body_text(loader) == "Chapel"
      loader.chapel_category
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
      #  Or sport/PE?  Note that for sport, the two should boast the same
      #  group, not just ones with similar names.
      #
      (!self.meeting? && !other.meeting? &&
       / (Spt|PE)\Z/ =~ own_group_name &&
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
        compounded.compound = true
        compounded.source_hash = SB_Timetableentry.generate_hash(matching)
        compounded.staff_idents =
          matching.collect {|tte| tte.staff_ident}.uniq.compact
        compounded.group_idents =
          matching.collect {|tte| tte.group_ident}.uniq.compact
        compounded.room_idents  =
          matching.collect {|tte| tte.room_ident}.uniq.compact
#        puts "Combined #{matching.size} events with digest #{compounded.source_hash}."
#        puts "Event is #{compounded.time_note} and involves #{compounded.staff_idents.size} staff."
        result << compounded
      else
        result << matching[0]
      end
    end
#    puts "Leaving sort_and_merge"
    result
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
  FIELDS_TO_UPDATE = [:name, :house, :era_id, :start_year, :current]
  DB_CLASS = Tutorgroup
  DB_KEY_FIELD = :staff_id
  FIELDS_TO_CREATE = [:name, :house, :era_id, :start_year, :current]

  include DatabaseAccess

  attr_accessor :name,
                :house,
                :staff_id,
                :era_id,
                :start_year,
                :records,
                :year_group


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

end

class SB_Loader

  KNOWN_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

  InputSource = Struct.new(:array_name, :loader_class, :hash_prefix, :key_field)

  INPUT_SOURCES = [InputSource[:academicyears, SB_AcademicYear],
                   InputSource[:years, SB_Year, :year, :year_ident],
                   InputSource[:curriculums, SB_Curriculum, :curriculum,
                               :curriculum_ident],
                   InputSource[:tutorgroupentries, SB_Tutorgroupentry],
                   InputSource[:pupils, SB_Pupil, :pupil, :pupil_ident],
                   InputSource[:staff, SB_Staff, :staff, :staff_ident],
                   InputSource[:locations, SB_Location, :location, :room_ident],
                   InputSource[:groups, SB_Group, :group, :group_ident],
                   InputSource[:ars, SB_AcademicRecord],
                   InputSource[:periods, SB_Period, :period, :period_ident],
                   InputSource[:period_times, SB_PeriodTime],
                   InputSource[:subjects, SB_Subject, :subject, :subject_ident],
                   InputSource[:timetable_entries, SB_Timetableentry, :tte,
                               :timetable_ident],
                   InputSource[:staffablines, SB_StaffAbLine, :sal,
                               :staff_ab_line_ident],
                   InputSource[:staffabsences, SB_StaffAbsence, :sa,
                               :staff_ab_ident],
                   InputSource[:staffcovers, SB_StaffCover],
                   InputSource[:dates, SB_Date, :date, :date_ident],
                   InputSource[:rtrotaweek, SB_RotaWeek,
                               :rota_week, :rota_week_ident],
                   InputSource[:other_half, SB_OtherHalfOccurence,
                               :other_half, :oh_occurence_ident]]

    EXTRA_GROUP_FILES = [
      {file_name: "extra_staff_groups.yml", dbclass: Staff},
      {file_name: "extra_pupil_groups.yml", dbclass: Pupil},
      {file_name: "extra_group_groups.yml", dbclass: Group}
    ]

  attr_reader :era,
              :curriculum_hash,
              :date_hash,
              :group_hash,
              :location_hash,
              :rota_week_hash,
              :staff_hash,
              :year_hash,
              :verbose,
              :lesson_category,
              :meeting_category,
              :assembly_category,
              :chapel_category,
              :duty_category

  def initialize(options)
    @verbose   = options.verbose
    @full_load = options.full_load
    if options.era
      @era = Era.find_by_name(options.era)
      raise "Era #{options.era} not found in d/b." unless @era
    else
      @era = Setting.current_era
      raise "Current era not set." unless @era
    end
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
      array, msg = is.loader_class.slurp(self)
      if msg.blank?
        if array.size == 0
          raise "Input file for #{is.array_name} contains no data."
        end
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
    end
    #
    #  If we get this far then all the files have been succesfully read.
    #  We can perform initial organisation on our data.
    #
    if @academicyears.size != 1
      raise "SchoolBase doesn't have an academic year #{@era.source_ident}"
    end
    puts "Performing initial organisation." if @verbose
    @period_times.each do |period_time|
      if period = @period_hash[period_time.period_ident]
        period.time ||= period_time
      end
    end
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
          tg = SB_Tutorgroup.new
          tg.year_group = year.year_num - 6
          tg.name       = "#{tg.year_group}#{staff.initials}"
          tg.house      = tge.house
          tg.staff_id   = staff.dbrecord.id
          tg.era_id     = @era.id
          tg.start_year = year.start_year
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
    #  Make a list of which teachers teach each of the subjects.
    #  Don't go for d/b records yet because we may yet need to create them.
    #
    @subject_teacher_hash = {}
    @timetable_entries.each do |te|
      staff = @staff_hash[te.staff_ident]
      if staff && staff.active && staff.current
        group = @group_hash[te.group_ident]
        if group
          subject = @subject_hash[group.subject_ident]
          if subject && subject.type == :proper_subject
            if @subject_teacher_hash[subject.subject_name]
              unless @subject_teacher_hash[subject.subject_name].include?(staff)
                @subject_teacher_hash[subject.subject_name] << staff
              end
            else
              @subject_teacher_hash[subject.subject_name] = [staff]
            end
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
    @chapel_category = Eventcategory.find_by_name("Chapel")
    raise "Can't find event category for chapel." unless @chapel_category
    @meeting_category = Eventcategory.find_by_name("Meeting")
    raise "Can't find event category for meetings." unless @meeting_category
    @invigilation_category = Eventcategory.find_by_name("Exam invigilation")
    raise "Can't find event category for invigilations." unless @invigilation_category
    @other_half_category = Eventcategory.find_by_name("Other Half")
    raise "Can't find event category for Other Half." unless @other_half_category
    @duty_category = Eventcategory.find_by_name("Duty")
    raise "Can't find event category for duties." unless @duty_category
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
    puts "Finished data initialisation." if @verbose
    yield self if block_given?
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
          puts "Deleting #{dbrecord.name}"
          dbrecord.destroy
          staff_deleted_count += 1
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
    tg_changed_count   = 0
    tg_unchanged_count = 0
    tg_loaded_count    = 0
    tgmember_removed_count   = 0
    tgmember_unchanged_count = 0
    tgmember_loaded_count    = 0
    tg_at_start = Tutorgroup.current.count
    @tg_hash.each do |key, tg|
      dbrecord = tg.dbrecord
      if dbrecord
        #
        #  Need to check the group details still match.
        #
        if tg.check_and_update
          tg_changed_count += 1
        else
          tg_unchanged_count += 1
        end
      else
        if tg.num_pupils > 0
          if tg.save_to_db(starts_on: @start_date,
                           ends_on: @era.ends_on)
            dbrecord = tg.dbrecord
            tg_loaded_count += 1
          end
        end
      end
      if dbrecord
        #
        #  And now sort out the pupils for this tutor group.
        #
        db_member_ids = dbrecord.members(@start_date).collect {|s| s.source_id}
        sb_member_ids = tg.records.collect {|r| r.pupil_ident}
        missing_from_db = sb_member_ids - db_member_ids
        missing_from_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            begin
              dbrecord.add_member(pupil.dbrecord, @start_date)
              tgmember_loaded_count += 1
            rescue ActiveRecord::RecordInvalid => e
              puts "Failed to add #{pupil.name} to tutorgroup #{tg.name}"
              puts e
            end
          end
        end
        extra_in_db = db_member_ids - sb_member_ids
        extra_in_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            dbrecord.remove_member(pupil.dbrecord, @start_date)
            tgmember_removed_count += 1
          end
        end
        tgmember_unchanged_count += (db_member_ids.size - extra_in_db.size)
      end
    end
    #
    #  It's possible that a tutor group has ceased to exist entirely,
    #  in which case we will still have a record in our d/b for it (possibly
    #  with members) but we need to record its demise.
    #
    tg_deleted_count = 0
    Tutorgroup.current.each do |dbtg|
      tg = @tg_hash[dbtg.staff.source_id]
      unless dbtg.era_id == @era.id && tg
        puts "Tutor group #{dbtg.name} exists in the d/b but not in the files." if @verbose
        #
        #  Need to terminate any remaining memberships, then terminate the
        #  group.  Note that in general, nothing gets deleted, just marked
        #  as over.  The exception is when we are deleting a group before
        #  it ever got started.
        #
        dbtg.ceases_existence(@start_date)
        tg_deleted_count += 1
      end
    end
    tg_at_end = Tutorgroup.current.count
    if @verbose || tg_deleted_count > 0
      puts "#{tg_deleted_count} tutor group records deleted."
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
    if @verbose || tgmember_removed_count > 0
      puts "Removed #{tgmember_removed_count} pupils from tutor groups."
    end
    if @verbose
      puts "Left #{tgmember_unchanged_count} pupils where they were."
    end
    if @verbose || tgmember_loaded_count > 0
      puts "Added #{tgmember_loaded_count} pupils to tutor groups."
    end
    if @verbose && tg_at_start != tg_at_end
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
          #
          #  We have to process compound and non-compound events separately.
          #
          dbevents = Event.events_on(date,                # Start date
                                     nil,                 # End date
                                     [@lesson_category,   # Categories
                                      @meeting_category,
                                      @assembly_category,
                                      @chapel_category],
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
                                        @assembly_category,
                                        @chapel_category],
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
              period = @period_hash[lesson.period_ident]
              if period
                event = Event.new
                event.body          = lesson.body_text(self)
                event.eventcategory = lesson.eventcategory(self)
                event.eventsource   = @event_source
                if lesson.lower_school
                  event.starts_at     =
                      Time.zone.parse("#{date.to_s} #{period.time.ls_starts_at}")
                    event.ends_at       =
                      Time.zone.parse("#{date.to_s} #{period.time.ls_ends_at}")
                  else
                  event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
                end
                event.approximate   = false
                event.non_existent  = false
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
              else
    #            puts "Not loading - lesson = #{lesson.timetable_ident}, dbgroup = #{dbgroup ? dbgroup.name : "Not found"}"
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
              period = @period_hash[lesson.period_ident]
              if lesson.lower_school
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period.time.ls_starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period.time.ls_ends_at}")
              else
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
              end
              if event.starts_at != starts_at
                event.starts_at = starts_at
                changed = true
              end
              if event.ends_at != ends_at
                event.ends_at = ends_at
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
                  if db_only.include?(c.element_id)
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
              #
              #  For each of these, just create the event.  Resources
              #  will be handled later.
              #
              period = @period_hash[lesson.period_ident]
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
              if period && (lesson.meeting? || dbgroup)
                event = Event.new
                event.body          = lesson.body_text(self)
                event.eventcategory = lesson.eventcategory(self)
                event.eventsource   = @event_source
                if lesson.lower_school
                  event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period.time.ls_starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period.time.ls_ends_at}")
                else
                  event.starts_at     =
                    Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                  event.ends_at       =
                    Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
                end
                event.approximate   = false
                event.non_existent  = false
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
                puts "  period = #{period}"
                puts "  lesson.meeting = #{lesson.meeting?}"
                puts "  dbgroup = #{dbgroup}"
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
              period = @period_hash[lesson.period_ident]
              if lesson.lower_school
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period.time.ls_starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period.time.ls_ends_at}")
              else
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
              end
              if event.starts_at != starts_at
                event.starts_at = starts_at
                changed = true
              end
              if event.ends_at != ends_at
                event.ends_at = ends_at
                changed = true
              end
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
                  if db_only.include?(c.element_id)
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
  #  Add cover to existing lessons.
  #
  def do_cover
    covers_added = 0
    invigilations_added = 0
    invigilations_amended = 0
    #
    #  Let's see if we can make any sense of it first.
    #
    @staffcovers.each do |sc|
      if sc.ptype == 60
        sal = @sal_hash[sc.staff_ab_line_ident]
        date = @date_hash[sc.absence_date]
        if date && date.date >= @start_date
          staff_covering = @staff_hash[sc.staff_ident]
          if sal && date && staff_covering
#            puts "#{sc.staff_name} on #{date.date} links up."
            #
            #  Now can we find the lesson he or she is meant to be covering?
            #
            sa = @sa_hash[sal.staff_ab_ident]
            if sa
              if sal.timetable_ident
                staff_covered = @staff_hash[sa.staff_ident]
                if staff_covered
                  puts "#{staff_covering.name} covering #{staff_covered.name} on #{date.date} for lesson #{sal.timetable_ident}" if @verbose
                  #
                  #  Can we actually add this to the d/b (assuming it isn't
                  #  already there)?
                  #
                  #
                  #  Specify:
                  #    Date
                  #    Eventsource
                  #    Eventcategory
                  #    source id
                  dblesson = Event.on(date.date).
                                   eventsource_id(@event_source.id).
                                   eventcategory_id(@lesson_category.id).
                                   source_id(sal.timetable_ident)[0]
                  if dblesson
#                    puts "Found the corresponding lesson."
                    #
                    #  Need to find the commitment by the covered teacher
                    #  to the indicated lesson.
                    #
                    original_commitment =
                      Commitment.by(staff_covered.dbrecord).to(dblesson)[0]
                    if original_commitment
#                      puts "Found commitment."
                      #
                      #  Now - does the cover exist already?
                      #
                      if original_commitment.covered
#                        puts "Cover is there already."
                        #
                        #  Is the right person doing it?
                        #
#                        if original_commitment.covered.element.entity.id ==
#                           staff_covering.dbrecord.id
#                          puts "And by the right person."
#                        else
#                          puts "But the wrong person."
#                        end
                      else
                        cover_commitment = Commitment.new
                        cover_commitment.event = original_commitment.event
                        cover_commitment.element = staff_covering.dbrecord.element
                        cover_commitment.covering = original_commitment
                        if cover_commitment.save
                          covers_added += 1
                        else
                          puts "Failed to save cover."
                        end
                      end
                    else
                      puts "Can't find commitment."
                    end
                  else
                    puts "Can't find the lesson."
                  end
                else
                  puts "Can't find covered staff."
                end
              else
                puts "An invigilation slot for #{staff_covering.name} on #{date.date}." if @verbose
                #
                #  Is it already in the database?
                #
                dbinvigilation =
                  Event.on(date.date).
                        eventsource_id(@event_source.id).
                        eventcategory_id(@invigilation_category.id).
                        source_id(sal.staff_ab_line_ident)[0]
                if dbinvigilation
#                  puts "Invigilation already in the d/b."
                  #
                  #  Is it the right person?
                  #
                  if dbinvigilation.commitments
                    commitment = dbinvigilation.commitments[0]
                    if commitment.element !=
                       staff_covering.dbrecord.element
                      commitment.element = staff_covering.dbrecord.element
                      commitment.save
                      invigilations_amended += 1
                    end
                  end
                else
#                  puts "Creating invigilation event."
                  period = @period_hash[sal.period]
                  if period && period.time
                    starts_at =
                      Time.zone.parse("#{date.date.to_s} #{period.time.starts_at}")
                    ends_at   =
                      Time.zone.parse("#{date.date.to_s} #{period.time.ends_at}")
                    event = Event.new
                    event.body          = "Invigilation"
                    event.eventcategory = @invigilation_category
                    event.eventsource   = @event_source
                    event.starts_at     = starts_at
                    event.ends_at       = ends_at
                    event.approximate   = false
                    event.non_existent  = false
                    event.private       = false
                    event.all_day       = false
                    event.compound      = false
                    event.source_id     = sal.staff_ab_line_ident
                    if event.save
                      event.reload
                      c = Commitment.new
                      c.event = event
                      c.element = staff_covering.dbrecord.element
                      c.save
                      invigilations_added += 1
                    end
                  end
                end
              end
            else
              puts "Can't find staff absence record."
            end
          else
            puts "#{sc.staff_name} on #{date ? date.date : "unknown date"} doesn't link up."
          end
        end
      end
    end
    if covers_added > 0 || @verbose
      puts "Added #{covers_added} instances of cover."
    end
    if invigilations_added > 0 || @verbose
      puts "Added #{invigilations_added} instances of invigilation."
    end
    if invigilations_amended > 0 || @verbose
      puts "Changed #{invigilations_amended} instances of invigilation."
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
    #
    #  How do we go about deleting OH activites which have been deleted
    #  from SB?
    #
    events = Event.eventsource_id(@event_source.id).
                   eventcategory_id(@other_half_category.id).
                   beginning(@era.starts_on).
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
  def ensure_membership(group_name, members, member_class)
    members_added   = 0
    members_removed = 0
    group = Group.system.vanillagroups.find_by(name: group_name,
                                               era_id: @era.id)
    unless group
      group = Vanillagroup.new(name:      group_name,
                               era:       @era,
                               starts_on: @start_date,
                               ends_on:   @era.ends_on,
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
    ensure_membership("Teaching staff",
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
    @subject_teacher_hash.each do |subject, teachers|
      dbteachers = teachers.collect {|t| @staff_hash[t.staff_ident].dbrecord}.compact
      if dbteachers.size > 0
        ensure_membership("#{subject} teachers",
                          dbteachers,
                          Staff)
      else
        puts "Subject \"#{subject}\" has no apparent teachers."
      end
    end
  end

  def do_extra_groups
    EXTRA_GROUP_FILES.each do |control_data|
      file_data =
        YAML.load(
          File.open(Rails.root.join(IMPORT_DIR, control_data[:file_name])))
      file_data.each do |group_name, members|
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
        ensure_membership(group_name, dbrecords, control_data[:dbclass])
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

end

begin
  options = OpenStruct.new
  options.verbose         = false
  options.full_load       = false
  options.just_initialise = false
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

    opts.on("-s", "--start [DATE]", Date,
            "Specify an over-riding start date",
            "for loading events.") do |date|
      options.start_date = date
    end

  end.parse!

  SB_Loader.new(options) do |loader|
    unless options.just_initialise
      loader.do_pupils
      loader.do_staff
      loader.do_locations
      loader.do_tutorgroups
      loader.do_teachinggroups
      loader.do_timetable
      loader.do_cover
      loader.do_other_half
      loader.do_auto_groups
      loader.do_extra_groups
      loader.do_duties
    end
  end
rescue RuntimeError => e
  puts e
end


