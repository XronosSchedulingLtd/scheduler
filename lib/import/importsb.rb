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
                entry.send("#{attr_name}=", row[column_hash[attr_name]])
              end
            end
            entry.adjust
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
    @checked_dbrecord = false
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
      if @dbrecord[field_name] != self.instance_variable_get("@#{field_name}")
        puts "Field #{field_name} differs for #{self.name}"
        puts "d/b: \"#{@dbrecord[field_name]}\" SB: \"#{self.instance_variable_get("@#{field_name}")}\""
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
        if @dbrecord.send("#{key}") != value
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
      key_field = self.class.const_get(:DB_KEY_FIELD)
      find_hash = { key_field => self.send("#{key_field}") }
      @dbrecord =
        self.class.const_get(:DB_CLASS).find_by(find_hash)
#        self.class.const_get(:DB_CLASS).find_by_source_id(self.source_id)
    end
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

  def adjust
  end

  def wanted?(loader)
    true
  end

  def active
    true
  end

  def current
    true
  end
end


class SB_AcademicYear
  FILE_NAME = "academicyear.csv"
  REQUIRED_COLUMNS = [Column["AcYearIdent", :ac_year_ident, true],
                      Column["AcYearName",  :ac_year_name,  false]]

  include Slurper

  def adjust
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

  def adjust
  end

  def wanted?(loader)
    #
    #  Only want those for our academic year.
    #
    @ac_year_ident == loader.send("era").source_id
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

  def adjust
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
                      Column["CurrIdent",  :curriculum_ident, true]]

  FIELDS_TO_UPDATE = [:name]
  FIELDS_TO_CREATE = [:name, :current]
  DB_CLASS = Teachinggroup
  DB_KEY_FIELD = :source_id

  include Slurper
  include DatabaseAccess

  attr_accessor :records

  def initialize
    @records = Array.new
  end

  def add(record)
    @records << record
  end

  def num_pupils
    @records.size
  end

  def adjust
  end

  def wanted?(loader)
    #
    #  We only want groups related to our current academic year.
    #  Note that groups must be loaded from file after curriculum and
    #  academic year, or they'll all get rejected.
    #
    curriculum = loader.send("curriculum_hash")[@curriculum_ident]
    era = loader.send("era")
    !!(curriculum && curriculum.ac_year_ident == era.source_id)
  end

  def active
    true
  end

  def current
    true
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

  def adjust
    if self.name.blank? && !self.short_name.blank?
      self.name = self.short_name
    elsif self.short_name.blank? && !self.name.blank?
      self.short_name = self.name
    end
  end

  def wanted?(loader)
    !(self.name.blank? || self.short_name.blank?)
  end

  def active
    true
  end

  def current
    true
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


class SB_Period
  FILE_NAME = "period.csv"
  REQUIRED_COLUMNS = [Column["Period",         :period_ident,    true],
                      Column["DayName",        :day_name,        false],
                      Column["TeachingPeriod", :teaching_period, true],
                      Column["PeriodWeek",     :week_id,         true]]

  include Slurper

  attr_accessor :time

  def adjust
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

  def active
    true
  end

  def current
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

  def adjust
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

  def wanted?(loader)
    @period_time_set_ident == 2
  end

  def active
    true
  end

  def current
    true
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

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?(loader)
    #
    #  He must have a date of entry.
    #
    self.ptype == 60
#    !self.date_of_entry.blank?
  end

  def current
    true
  end

  def source_id
    @pupil_ident
  end

end


class SB_Staff
  FILE_NAME = "staff.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :staff_ident, true],
                      Column["UserName",     :name,        false],
                      Column["UserMnemonic", :initials,    false],
                      Column["UserSurname",  :surname,     false],
                      Column["UserTitle",    :title,       false],
                      Column["UserForename", :forename,    false],
                      Column["UserEmail",    :email,       false]]
  FIELDS_TO_UPDATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email]
  DB_CLASS = Staff
  DB_KEY_FIELD = :source_id
  FIELDS_TO_CREATE = [:name,
                      :initials,
                      :surname,
                      :title,
                      :forename,
                      :email,
                      :active,
                      :current]

  attr_accessor :active

  include Slurper
  include DatabaseAccess

  def adjust
    #
    #  We can perhaps improve the SB data a little?
    #
    if self.name.blank? && !(self.surname.blank? && self.forename.blank?)
      self.name = "#{self.forename} #{self.surname}"
    end
    #
    #  We don't really know which of the ones we get from SB are valid
    #  and which aren't.  We take an initial stab at it.
    #
    self.active = !!(self.email =~ /\@abingdon\.org\.uk$/)
  end

  def wanted?(loader)
    true
  end

  def current
    self.active
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

  def adjust
  end

  def wanted?(loader)
    true
  end

  def current
    self.active
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

  def adjust
  end

  def wanted?(loader)
    true
  end

  def current
    self.active
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

  def adjust
  end

  def wanted?(loader)
    true
  end

  def current
    self.active
  end

  def source_id
  end

end


class SB_Timetableentry
  FILE_NAME = "timetable.csv"
  REQUIRED_COLUMNS = [Column["TimetableIdent", :timetable_ident, true],
                      Column["GroupIdent",     :group_ident,     true],
                      Column["StaffIdent",     :staff_ident,     true],
                      Column["RoomIdent",      :room_ident,      true],
                      Column["Period",         :period_ident,    true],
                      Column["AcYearIdent",    :ac_year_ident,   true]]

  include Slurper

  attr_accessor :compound,
                :source_hash,
                :staff_idents,
                :group_idents,
                :room_idents

  def initialize
    @compound = false
    @source_hash = ""
    @staff_idents = []
    @group_idents = []
    @room_idents  = []
  end

  def adjust
  end

  def wanted?(loader)
    #
    #  For now we don't want any events that don't involve any kind
    #  of teaching group.
    #
    @ac_year_ident == loader.send("era").source_id &&
    @group_ident != nil
  end

  def active
    true
  end

  def current
    true
  end

  def <=>(other)
    self.timetable_ident <=> other.timetable_ident
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
  #  Passed an array of Timetableentries, we sort them and identify any
  #  that can be merged into a single event.
  #
  def self.sort_and_merge(ttes)
#    puts "Entering sort_and_merge"
    #
    #  We are looking for events which share the same period_ident, and
    #  either the same group_ident or the same room_ident (or both).  Any
    #  set of such which we find can be merged into a single event.
    #
    result = []
    rest = ttes
    while rest.size > 0
#      puts "rest.size = #{rest.size}"
      sample = rest[0]
      matching, rest = rest.partition {|tte|
        tte == sample ||
        (tte.period_ident == sample.period_ident &&
         ((tte.group_ident && (tte.group_ident == sample.group_ident)) ||
          (tte.room_ident  && (tte.room_ident  == sample.room_ident))))
      }
      if matching.size > 1
#        puts "Merging the following events."
#        matching.each do |tte|
#          puts "  #{tte.description}"
#        end
        compounded = matching[0].clone
        compounded.compound = true
        compounded.source_hash = SB_Timetableentry.generate_hash(matching)
        compounded.staff_idents = matching.collect {|tte| tte.staff_ident}.uniq
        compounded.group_idents = matching.collect {|tte| tte.group_ident}.uniq
        compounded.room_idents  = matching.collect {|tte| tte.room_ident}.uniq
#        puts "Combined #{matching.size} events with digest #{compounded.source_hash}."
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
  def self.generate_hash(ttes)
    Digest::MD5.hexdigest(
      ttes.sort.collect {|tte| tte.timetable_ident.to_s}.join("/"))
  end

end


class SB_Tutorgroupentry
  FILE_NAME = "tutorgroup.csv"
  REQUIRED_COLUMNS = [Column["UserIdent",    :user_ident,  true],
                      Column["YearIdent",    :year_ident,  true],
                      Column["PupOrigNum",   :pupil_ident, true],
                      Column["Pu_House",     :house,       false]]

  include Slurper

  def adjust
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
  FIELDS_TO_UPDATE = [:name, :house, :era_id, :start_year]
  DB_CLASS = Tutorgroup
  DB_KEY_FIELD = :staff_id
  FIELDS_TO_CREATE = [:name, :house, :era_id, :start_year, :current]

  include DatabaseAccess

  attr_accessor :name, :house, :staff_id, :era_id, :start_year, :records


  def initialize
    @records = Array.new
  end

  def add(record)
    @records << record
  end

  def num_pupils
    @records.size
  end

  def current
    true
  end

end

class SB_Year
  FILE_NAME = "years.csv"
  REQUIRED_COLUMNS = [Column["YearIdent", :year_ident, true],
                      Column["YearDesc",  :year_num,   true],
                      Column["YearName",  :year_name,  false],
                      Column["Ptype",     :ptype,      true]]

  include Slurper

  def adjust
    #
    #  Nothing for now.
    #
  end

  def wanted?(loader)
    #
    #  60 seems to be the main school, whilst 40 is the prep school.
    #
    self.ptype == 60
  end

  def start_year
    #
    #  This is a bit hard-coded for now.
    #  If this is 2013/14 then someone in year 9 started in 2011.
    #
    2020 - self.year_num
  end
end

class SB_Loader

  KNOWN_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

  InputSource = Struct.new(:array_name, :loader_class, :hash_prefix, :key_field)

  INPUT_SOURCES = [InputSource[:academicyears, SB_AcademicYear],
                   InputSource[:curriculums, SB_Curriculum, :curriculum,
                               :curriculum_ident],
                   InputSource[:tutorgroupentries, SB_Tutorgroupentry],
                   InputSource[:years, SB_Year, :year, :year_ident],
                   InputSource[:pupils, SB_Pupil, :pupil, :pupil_ident],
                   InputSource[:staff, SB_Staff, :staff, :staff_ident],
                   InputSource[:locations, SB_Location, :location, :room_ident],
                   InputSource[:groups, SB_Group, :group, :group_ident],
                   InputSource[:ars, SB_AcademicRecord],
                   InputSource[:periods, SB_Period, :period, :period_ident],
                   InputSource[:period_times, SB_PeriodTime],
                   InputSource[:timetable_entries, SB_Timetableentry, :tte,
                               :timetable_ident],
                   InputSource[:staffablines, SB_StaffAbLine, :sal,
                               :staff_ab_line_ident],
                   InputSource[:staffabsences, SB_StaffAbsence, :sa,
                               :staff_ab_ident],
                   InputSource[:staffcovers, SB_StaffCover],
                   InputSource[:dates, SB_Date, :date, :date_ident]]

  attr_reader :era, :curriculum_hash

  def initialize(options)
    @verbose   = options.verbose
    @full_load = options.full_load
    raise "An era name must be specified." unless options.era
    @era = Era.find_by_name(options.era)
    raise "Era #{options.era} not found in d/b." unless @era
    @start_date = options.start_date
    puts "Reading data files." if @verbose
    INPUT_SOURCES.each do |is|
      array, msg = is.loader_class.slurp(self)
      if msg.blank?
        #
        #  It's legitimate to use instance_variable_set because I'm fiddling
        #  with my own instance variables.
        #
        if array.size == 0
          raise "Input file for #{is.array_name} contains no data."
        end
        puts "Read #{array.size} records as #{is.array_name}." if @verbose
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
    tge_accepted_count = 0
    tge_ignored_count = 0
    @tutorgroupentries.each do |tge|
      staff = @staff_hash[tge.user_ident]
      year  = @year_hash[tge.year_ident]
      pupil = @pupil_hash[tge.pupil_ident]
      if staff && year && pupil && staff.dbrecord && staff.active
        tge_accepted_count += 1
        unless @tg_hash[tge.user_ident]
          tg = SB_Tutorgroup.new
          tg.name       = "#{year.year_num - 6}#{staff.initials}"
          tg.house      = tge.house
          tg.staff_id   = staff.dbrecord.id
          tg.era_id     = @era.id
          tg.start_year = year.start_year
          @tg_hash[tge.user_ident] = tg
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
      if pupil && pupil.dbrecord && (group = @group_hash[ar.group_ident])
        group.add(ar)
      end
    end
    puts "Finished sorting academic records." if @verbose
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
    @week_letter_category = Eventcategory.find_by_name("Week letter")
    raise "Can't find event category for week letters." unless @week_letter_category
    @lesson_category = Eventcategory.find_by_name("Lesson")
    raise "Can't find event category for lessons." unless @lesson_category
    @invigilation_category = Eventcategory.find_by_name("Exam invigilation")
    raise "Can't find event category for invigilations." unless @invigilation_category
    @event_source = Eventsource.find_by_name("SchoolBase")
    raise "Can't find event source \"SchoolBase\"." unless @event_source
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
    if @verbose || pupils_changed_count > 0
      puts "#{pupils_changed_count} pupil record(s) amended."
    end
    if @verbose || pupils_loaded_count > 0
      puts "#{pupils_loaded_count} pupil record(s) created."
    end
    if @verbose
      puts "#{pupils_unchanged_count} pupil record(s) untouched."
    end
  end

  def do_staff
    staff_changed_count   = 0
    staff_unchanged_count = 0
    staff_loaded_count    = 0
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
    if @verbose || staff_changed_count > 0
      puts "#{staff_changed_count} staff record(s) amended."
    end
    if @verbose || staff_loaded_count > 0
      puts "#{staff_loaded_count} staff record(s) created."
    end
    if @verbose
      puts "#{staff_unchanged_count} staff record(s) untouched."
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
          if tg.save_to_db(starts_on: @era.starts_on, ends_on: @era.ends_on)
            dbrecord = tg.dbrecord
            tg_loaded_count += 1
          end
        end
      end
      if dbrecord
        #
        #  And now sort out the pupils for this tutor group.
        #
        db_member_ids = dbrecord.members.collect {|s| s.source_id}
        sb_member_ids = tg.records.collect {|r| r.pupil_ident}
        missing_from_db = sb_member_ids - db_member_ids
        missing_from_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            begin
              dbrecord.add_member(pupil.dbrecord)
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
            dbrecord.remove_member(pupil.dbrecord)
            tgmember_removed_count += 1
          end
        end
        tgmember_unchanged_count += (db_member_ids.size - extra_in_db.size)
      end
    end
    if @verbose || tg_changed_count > 0
      puts "#{tg_changed_count} tutorgroup records amended."
    end
    if @verbose
      puts "#{tg_unchanged_count} tutorgroup records untouched."
    end
    if @verbose || tg_loaded_count > 0
      puts "#{tg_loaded_count} tutorgroup records created."
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
    if @start_date
      starts_on = @start_date
    elsif @full_load
      starts_on = @era.starts_on
    else
      starts_on = Date.today
    end
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
        #  like actual teaching groups.
        #
        if group.num_pupils > 0 || /\A[1234567]/ =~ group.name
          if group.save_to_db(era: @era,
                              starts_on: starts_on)
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
        db_member_ids = dbgroup.members.collect {|s| s.source_id}
        sb_member_ids = group.records.collect {|r| r.pupil_ident}
        missing_from_db = sb_member_ids - db_member_ids
        missing_from_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            puts "Adding #{pupil.dbrecord.name} to #{dbgroup.name}" unless @full_load
            dbgroup.add_member(pupil.dbrecord, starts_on)
            pupils_added_count += 1
          end
        end
        extra_in_db = db_member_ids - sb_member_ids
        extra_in_db.each do |pupil_id|
          pupil = @pupil_hash[pupil_id]
          if pupil && pupil.dbrecord
            puts "Removing #{pupil.dbrecord.name} from #{dbgroup.name}" unless @full_load
            dbgroup.remove_member(pupil.dbrecord)
            pupils_removed_count += 1
          end
        end
        pupils_left_alone_count += (db_member_ids.size - extra_in_db.size)
      end
    end
    if @verbose || groups_created_count > 0
      puts "Created #{groups_created_count} teaching groups."
    end
    if @verbose || groups_amended_count > 0
      puts "Amended #{groups_amended_count} teaching groups."
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
    if @start_date
      start_date = @start_date
    elsif @full_load
      start_date = @era.starts_on
    else
      start_date = Date.today
    end
    puts "Loading events from #{start_date} to #{@era.ends_on}" if @verbose
    start_date.upto(@era.ends_on) do |date|
      puts "Processing #{date}" if @verbose
      week_letter = get_week_letter(date)
      if week_letter
        lessons = @periods_by_week[week_letter][date.strftime("%A")]
        if lessons
          #
          #  We have to process compound and non-compound events separately.
          #
          dbevents = Event.events_on(date,
                                     nil,
                                     @lesson_category,
                                     @event_source,
                                     nil,
                                     true)
          #
          #  A little bit of correction code.  Earlier I managed to reach
          #  the situation where two instances of the same event (from SB's
          #  point of view) were occuring on the same day.  If this happens,
          #  arbitrarily delete one of them before continuing.
          #
          dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
          dbids = dbatomic.collect {|dba| dba.source_id}.uniq
          if dbids.size < dbatomic.size
            puts "Deleting #{dbatomic.size - dbids.size} duplicate events." if @verbose
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
            #
            #  And read again from the database.
            #
            dbevents = Event.events_on(date,
                                       nil,
                                       @lesson_category,
                                       @event_source,
                                       nil,
                                       true)
            dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
            dbids = dbatomic.collect {|dba| dba.source_id}.uniq
          end
          sbcompound, sbatomic = lessons.partition {|sbe| sbe.compound}
          sbids = sbatomic.collect {|sba| sba.timetable_ident}
          #
          #  First we'll do the atomic ones.
          #
          dbonly = dbids - sbids
          if dbonly.size > 0
            puts "Deleting #{dbonly.size} atomic events." if @verbose
            #
            #  These I'm afraid have to go.
            #
            dbonly.each do |dbo|
              Event.find_by_source_id(dbo).destroy
            end
          end
          sbonly = sbids - dbids
          if sbonly.size > 0
            puts "Adding #{sbonly.size} atomic events." if @verbose
            sbonly.each do |sbo|
              lesson = @tte_hash[sbo]
              #
              #  For each of these, identify the staff, teaching group and room
              #  involved.  Create an event and then attach the resources.
              #
              if group = @group_hash[lesson.group_ident]
                dbgroup = group.dbrecord
              else
                dbgroup = nil
              end
              if staff = @staff_hash[lesson.staff_ident]
                dbstaff = staff.dbrecord
              else
                dbstaff = nil
              end
              if location = @location_hash[lesson.room_ident]
                dblocation = location.dbrecord
              else
                dblocation = nil
              end
              period = @period_hash[lesson.period_ident]
              if period && dbgroup
                event = Event.new
                event.body          = dbgroup.name
                event.eventcategory = @lesson_category
                event.eventsource   = @event_source
                event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
                event.approximate   = false
                event.non_existent  = false
                event.private       = false
                event.all_day       = false
                event.source_id     = lesson.timetable_ident
                if event.save
                  event.reload
                  #
                  #  And add the resources.
                  #
                  if dbgroup
                    c = Commitment.new
                    c.event = event
                    c.element = dbgroup.element
                    c.save
                  end
                  if dbstaff
                    c = Commitment.new
                    c.event = event
                    c.element = dbstaff.element
                    c.save
                  end
                  if dblocation && dblocation.location
                    c = Commitment.new
                    c.event = event
                    c.element = dblocation.location.element
                    c.save
                  end
                else
                  puts "Failed to save event #{event.inspect}"
                end
              else
    #            puts "Not loading - lesson = #{lesson.timetable_ident}, dbgroup = #{dbgroup ? dbgroup.name : "Not found"}"
              end
            end
          end
          #
          #  And any which need adjusting?
          #
          shared = sbids - sbonly
          if shared.size > 0
            puts "#{shared.size} existing events to check." if @verbose
            shared.each do |sl|
              lesson = @tte_hash[sl]
              dbrecord = dbevents.detect {|dbevent| dbevent.source_id == sl}
              if lesson && dbrecord
                changed = false
                period = @period_hash[lesson.period_ident]
                starts_at =
                  Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                ends_at   =
                  Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
                if dbrecord.starts_at != starts_at
                  dbrecord.starts_at = starts_at
                  changed = true
                end
                if dbrecord.ends_at != ends_at
                  dbrecord.ends_at = ends_at
                  changed = true
                end
                if changed
                  unless dbrecord.save
                    puts "Failed to save amended event record."
                  end
                end
              else
                puts "Couldn't find existing lesson to check."
              end
            end
          end
if false
          #
          #  And now the compound events.
          #
          dbhashes = dbcompound.collect {|dbc| dbc.source_hash}
          sbhashes = sbcompound.collect {|sbc| sbc.source_hash}
          dbonly = dbhashes - sbhashes
          if dbonly.size > 0
            puts "Deleting #{dbonly.size} compound events."
            #
            #  These I'm afraid have to go.
            #
            dbonly.each do |dbo|
              Event.find_by_source_hash(dbo).destroy
            end
          end
          sbonly = sbhashes - dbhashes
          if sbonly.size > 0
            puts "Adding #{sbonly.size} compound events."
            sbonly.each do |sbo_hash|
              lesson = lessons.detect {|tte| tte.source_hash == sbo_hash}
              period = period_hash[lesson.period_ident]
              if lesson && period
                event = Event.new
                event.body          = "Merged event"
                event.eventcategory = ec
                event.eventsource   = es
                event.starts_at     =
                  Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
                event.ends_at       =
                  Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
                event.approximate   = false
                event.non_existent  = false
                event.private       = false
                event.all_day       = false
                event.compound      = true
                event.source_hash   = sbo_hash
                if event.save
                  event.reload
                  #
                  #  And now add the resources.
                  #
                  lesson.group_idents.each do |gi|
                    if group = group_hash[gi]
                      dbgroup = group.dbrecord
                      if dbgroup
                        c = Commitment.new
                        c.event = event
                        c.element = dbgroup.element
                        c.save
                      end
                    end
                  end
                  lesson.staff_idents.each do |si|
                    if staff = staff_hash[si]
                      dbstaff = staff.dbrecord
                      if dbstaff
                        c = Commitment.new
                        c.event = event
                        c.element = dbstaff.element
                        c.save
                      end
                    end
                  end
                  lesson.room_idents.each do |ri|
                    if location = location_hash[ri]
                      dblocation = location.dbrecord
                      if dblocation && dblocation.location
                        c = Commitment.new
                        c.event = event
                        c.element = dblocation.location.element
                        c.save
                      end
                    end
                  end
                else
                  puts "Failed to save event #{event.inspect}"
                end
              else
                puts "Not loading - lesson = #{lesson.timetable_ident}, dbgroup = #{dbgroup ? dbgroup.name : "Not found"}"
              end
            end
          end
end

        else
          puts "Couldn't find lesson entries for #{date.strftime("%A")} of week #{week_letter}."
        end
      else
        puts "No week letter for #{date}" if @verbose
      end
    end
  end

  #
  #  Add cover to existing lessons.
  #
  def do_cover
    covers_added = 0
    invigilations_added = 0
    invigilations_amended = 0
    if @start_date
      start_date = @start_date
    elsif @full_load
      start_date = @era.starts_on
    else
      start_date = Date.today
    end
    #
    #  Let's see if we can make any sense of it first.
    #
    @staffcovers.each do |sc|
      if sc.ptype == 60
        sal = @sal_hash[sc.staff_ab_line_ident]
        date = @date_hash[sc.absence_date]
        if date && date.date >= start_date
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

end

begin
  options = OpenStruct.new
  options.verbose    = false
  options.full_load  = false
  options.era        = nil
  options.start_date = nil
  OptionParser.new do |opts|
    opts.banner = "Usage: importsb.rb [options]"

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
    loader.do_pupils
    loader.do_staff
    loader.do_locations
    loader.do_tutorgroups
    loader.do_teachinggroups
    loader.do_timetable
    loader.do_cover
  end
rescue RuntimeError => e
  puts e
end


