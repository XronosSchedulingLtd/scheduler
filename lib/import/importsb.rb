require 'csv'
require 'charlock_holmes'
require 'digest/md5'
#require 'ruby-prof'

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
    def slurp
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
            if entry.wanted?
              entries << entry
            end
          end
        end
        return entries, nil
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
        puts "Failed to create d/b record of type #{self.class.const_get(:DB_CLAS)} for #{self.source_id}"
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

  def wanted?
    true
  end

  def active
    true
  end

  def current
    true
  end
end


class SB_Group
  FILE_NAME = "groups.csv"
  REQUIRED_COLUMNS = [Column["GroupIdent", :group_ident, true],
                      Column["GroupName",  :name,        false]]

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

  def wanted?
    true
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
  FIELDS_TO_CREATE = [:name, :short_name]
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

  def wanted?
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

  def wanted?
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

  def wanted?
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

  def wanted?
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

  def wanted?
    true
  end

  def current
    self.active
  end

  def source_id
    @staff_ident
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

  def wanted?
    #
    #  For now we don't want any events that don't involve any kind
    #  of teaching group.
    #
    !!@group_ident
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

  def wanted?
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

  def wanted?
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

#
#  Compares selected fields in a database record and a memory record,
#  and updates any which differ.  Returns true if anything was updated
#  and false otherwise.
#
def check_and_update(dbrecord, sbrecord, fields)
  changed = false
  fields.each do |field_name|
    if dbrecord[field_name] != sbrecord.instance_variable_get("@#{field_name}")
      puts "Field #{field_name} differs for #{sbrecord.name}"
#      puts "Database: #{dbrecord[field_name]} encoding #{dbrecord[field_name].encoding}"
#      puts "Memory:   #{sbrecord.instance_variable_get("@#{field_name}")} encoding #{sbrecord.instance_variable_get("@#{field_name}").encoding}"
      dbrecord[field_name] = sbrecord.instance_variable_get("@#{field_name}")
      changed = true
    end
  end
  changed
end

tutorgroupentries, msg = SB_Tutorgroupentry.slurp
if msg.blank?
  puts "Read #{tutorgroupentries.size} tutor groups."
else
  puts "Tutorgroupentries: #{msg}"
end

years, msg = SB_Year.slurp
if msg.blank?
  puts "Read #{years.size} years."
  year_hash = {}
  years.each do |year|
    year_hash[year.year_ident] = year
  end
else
  puts "Years: #{msg}"
end

pupils, msg = SB_Pupil.slurp
if msg.blank?
  puts "Read #{pupils.size} pupils."
  pupil_hash = {}
  pupils.each do |pupil|
    pupil_hash[pupil.pupil_ident] = pupil
  end
else
  puts "Pupils: #{msg}"
end

groups, msg = SB_Group.slurp
if msg.blank?
  puts "Read #{groups.size} groups."
  group_hash = {}
  groups.each do |group|
    group_hash[group.group_ident] = group
  end
else
  puts "Groups: #{msg}"
end

ars, msg = SB_AcademicRecord.slurp
if msg.blank?
  puts "Read #{ars.size} academic records."
else
  puts "Academic records: #{msg}"
end

periods, msg = SB_Period.slurp
if msg.blank?
  puts "Read #{periods.size} period records."
  period_hash = {}
  periods.each do |period|
    period_hash[period.period_ident] = period
  end
  period_times, msg = SB_PeriodTime.slurp
  if msg.blank?
    puts "Read #{period_times.size} period time records."
    period_times.each do |period_time|
      if period = period_hash[period_time.period_ident]
        period.time ||= period_time
      end
    end
  else
    puts "Period time records: #{msg}"
  end
else
  puts "Period records: #{msg}"
end

timetable_entries, msg = SB_Timetableentry.slurp
if msg.blank?
  puts "Read #{timetable_entries.size} timetable records."
  tte_hash = {}
  timetable_entries.each do |tte|
    tte_hash[tte.timetable_ident] = tte
  end
else
  puts "Timetable entry records: #{msg}"
end

if pupils && years
  pupils_changed_count   = 0
  pupils_unchanged_count = 0
  pupils_loaded_count    = 0
  pupils.each do |pupil|
    year = year_hash[pupil.year_ident]
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
  puts "#{pupils_changed_count} pupil records amended."
  puts "#{pupils_unchanged_count} pupil records untouched."
  puts "#{pupils_loaded_count} pupil records created."
end

staff, msg = SB_Staff.slurp
if msg.blank?
  staff_hash = {}
  staff.each do |s|
    staff_hash[s.staff_ident] = s
  end
  #
  #  Should now have an array of Staff records ready to load into the
  #  database.
  #
  pre_existing_count = 0
  loaded_count = 0
  amended_count = 0
  staff.each do |s|
    dbrecord = s.dbrecord
    if dbrecord
      #
      #  Staff record already exists.  Any changes?
      #
      pre_existing_count += 1
      if s.check_and_update
        amended_count += 1
      end
    else
      #
      #  d/b record does not yet exist.
      #
      if s.save_to_db
        loaded_count += 1
      end
    end
  end
  puts "#{pre_existing_count} staff records were already there."
  puts "#{amended_count} of these were amended."
  puts "#{loaded_count} new records created."
else
  puts "Staff: #{msg}"
end

locations, msg = SB_Location.slurp
if msg.blank?
  puts "Read #{locations.size} locations."
  location_hash = {}
  locations.each do |location|
    location_hash[location.room_ident] = location
  end
  locations_changed_count   = 0
  locations_unchanged_count = 0
  locations_loaded_count    = 0
  locations.each do |location|
    dbrecord = location.dbrecord
    if dbrecord
      if location.check_and_update
        locations_changed_count += 1
      else
        locations_unchanged_count += 1
      end
    else
      if location.save_to_db
        locations_loaded_count += 1
      end
    end
  end
  puts "#{locations_changed_count} location records amended."
  puts "#{locations_unchanged_count} location records untouched."
  puts "#{locations_loaded_count} location records created."
else
  puts "Locations: #{msg}"
end

if pupils && years && tutorgroupentries
  puts "Attempting to construct tutor groups."

  tutorgroups = []
  tg_hash = {}
  tge_accepted_count = 0
  tge_ignored_count = 0
  era = Era.first
  tutorgroupentries.each do |tge|
    staff = staff_hash[tge.user_ident]
    year  = year_hash[tge.year_ident]
    pupil = pupil_hash[tge.pupil_ident]
    if staff && year && pupil && staff.dbrecord && staff.active
      tge_accepted_count += 1
      unless tg_hash[tge.user_ident]
        tg = SB_Tutorgroup.new
        tg.name       = "#{year.year_num - 6}#{staff.initials}"
        tg.house      = tge.house
        tg.staff_id   = staff.dbrecord.id
        tg.era_id     = era.id
        tg.start_year = year.start_year
        tg_hash[tge.user_ident] = tg
      end
      tg_hash[tge.user_ident].add(tge)
    else
      tge_ignored_count += 1
    end
  end
  puts "Accepted #{tge_accepted_count} tutor group entries."
  puts "Ignored #{tge_ignored_count} tutor group entries."
  puts "Constructed #{tg_hash.size} tutor groups."
  puts "Starting to load tutor groups and members."
  tg_changed_count   = 0
  tg_unchanged_count = 0
  tg_loaded_count    = 0
  tgmember_removed_count   = 0
  tgmember_unchanged_count = 0
  tgmember_loaded_count    = 0
  tg_hash.each do |key, tg|
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
        if tg.save_to_db(starts_on: era.starts_on, ends_on: era.ends_on)
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
        pupil = pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          dbrecord.add_member(pupil.dbrecord)
          tgmember_loaded_count += 1
        end
      end
      extra_in_db = db_member_ids - sb_member_ids
      extra_in_db.each do |pupil_id|
        pupil = pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          dbrecord.remove_member(pupil.dbrecord)
          tgmember_removed_count += 1
        end
      end
      tgmember_unchanged_count += (db_member_ids.size - extra_in_db.size)
    end
  end
  puts "#{tg_changed_count} tutorgroup records amended."
  puts "#{tg_unchanged_count} tutorgroup records untouched."
  puts "#{tg_loaded_count} tutorgroup records created."
  puts "Removed #{tgmember_removed_count} pupils from tutor groups."
  puts "Left #{tgmember_unchanged_count} pupils where they were."
  puts "Added #{tgmember_loaded_count} pupils to tutor groups."
end

#RubyProf.start

if ars && groups && pupils
  #
  #  So, can we load all the teaching groups as well?
  #  Drive this by the membership records - a group with no members is
  #  not terribly interesting.
  #
  #
  #  Start by attaching each of the membership records to its associated
  #  group, then work through the groups one by one checking the membership.
  #
  era = Era.first
  puts "Sorting academic records."
  ars.each do |ar|
    pupil = pupil_hash[ar.pupil_ident]
    if pupil && pupil.dbrecord && (group = group_hash[ar.group_ident])
      group.add(ar)
    end
  end
  puts "Finished sorting academic records."
  groups_created_count    = 0
  groups_amended_count    = 0
  groups_unchanged_count  = 0
  pupils_added_count      = 0
  pupils_removed_count    = 0
  pupils_left_alone_count = 0
  empty_tg_count          = 0
  dbera_hash = {}
  today = Date.today
  puts "Starting working through #{groups.size} teaching groups."
  groups.each do |group|
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
        if group.save_to_db(era: era, starts_on: era.starts_on)
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
        pupil = pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          dbgroup.add_member(pupil.dbrecord)
          pupils_added_count += 1
        end
      end
      extra_in_db = db_member_ids - sb_member_ids
      extra_in_db.each do |pupil_id|
        pupil = pupil_hash[pupil_id]
        if pupil && pupil.dbrecord
          dbgroup.remove_member(pupil.dbrecord)
          pupils_removed_count += 1
        end
      end
      pupils_left_alone_count += (db_member_ids.size - extra_in_db.size)
    end
  end
  puts "Created #{groups_created_count} teaching groups."
  puts "Amended #{groups_amended_count} teaching groups."
  puts "#{groups_unchanged_count} teaching groups left untouched."
  puts "#{empty_tg_count} empty teaching groups ignored."
  puts "Added #{pupils_added_count} to teaching groups."
  puts "Removed #{pupils_removed_count} from teaching groups."
  puts "Left #{pupils_left_alone_count} where they were."
end

if timetable_entries && periods && period_times
  #
  #  Sort by week and day of the week.
  #
  KNOWN_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  periods_by_week = {}
  periods_by_week["A"] = {}
  periods_by_week["B"] = {}
  KNOWN_DAY_NAMES.each do |day_name|
    periods_by_week["A"][day_name] = []
    periods_by_week["B"][day_name] = []
  end
  puts "Sorting timetable entries by week and day"
  timetable_entries.each do |te|
    period = period_hash[te.period_ident]
    if period.time && KNOWN_DAY_NAMES.include?(period.day_name)
      periods_by_week[period.week_letter][period.day_name] << te
    end
  end
#  ["A", "B"].each do |week_letter|
#    KNOWN_DAY_NAMES.each do |day_name|
#      periods_by_week[week_letter][day_name] = 
#        SB_Timetableentry.sort_and_merge(periods_by_week[week_letter][day_name])
#    end
#  end
  #
  #  For now I'm going to load just a specific week.
  #
  starts_on   = Date.parse("2014-06-02")
  ends_on     = Date.parse("2014-06-15")
  week_letter = "B"
  puts "Loading events from #{starts_on} to #{ends_on}"
  starts_on.upto(ends_on) do |date|
    puts "Processing #{date}"
    lessons = periods_by_week[week_letter][date.strftime("%A")]
    #
    #  This is very nasty.  Saturday will cause us to switch to week A.
    #
    if lessons == nil && week_letter == "B"
      week_letter = "A"
    end
    ec = Eventcategory.find_by_name("Lesson")
    es = Eventsource.find_by_name("SchoolBase")
    if lessons && ec && es
      #
      #  New approach which mimics the way we do it for group membership.
      #  Find all the database entries for the same day, then see what matches.
      #
      #  Things which are in the d/b only get deleted
      #  Things which are in our memory records only get added.
      #  Things which are in both get checked and if necessary are adjusted.
      #
      #
      #  We have to process compound and non-compound events separately.
      #
      dbevents = Event.events_on(date, nil, ec, es, nil, true)
      puts "Found #{dbevents.size} database events on that day."
      dbcompound, dbatomic = dbevents.partition {|dbe| dbe.compound}
      puts "#{dbcompound.size} of these are compound and #{dbatomic.size} atomic."
      sbcompound, sbatomic = lessons.partition {|sbe| sbe.compound}
      puts "Have #{lessons.size} lessons from SB."
      puts "#{sbcompound.size} of these are compound and #{sbatomic.size} atomic."
      #
      #  First we'll do the atomic ones.
      #
      dbids = dbatomic.collect {|dba| dba.source_id}
      sbids = sbatomic.collect {|sba| sba.timetable_ident}
      dbonly = dbids - sbids
      if dbonly.size > 0
        puts "Deleting #{dbonly.size} atomic events."
        #
        #  These I'm afraid have to go.
        #
        dbonly.each do |dbo|
          Event.find_by_source_id(dbo).destroy
        end
      end
      sbonly = sbids - dbids
      if sbonly.size > 0
        puts "Adding #{sbonly.size} atomic events."
        sbonly.each do |sbo|
          lesson = tte_hash[sbo]
          #
          #  For each of these, identify the staff, teaching group and room
          #  involved.  Create an event and then attach the resources.
          #
          if group = group_hash[lesson.group_ident]
            dbgroup = group.dbrecord
          else
            dbgroup = nil
          end
          if staff = staff_hash[lesson.staff_ident]
            dbstaff = staff.dbrecord
          else
            dbstaff = nil
          end
          if location = location_hash[lesson.room_ident]
            dblocation = location.dbrecord
          else
            dblocation = nil
          end
          period = period_hash[lesson.period_ident]
          if period && dbgroup
            event = Event.new
            event.body          = dbgroup.name
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
        puts "#{shared.size} existing events to check."
        shared.each do |sl|
          lesson = tte_hash[sl]
          dbrecord = Event.find_by_source_id(sl)
          if lesson && dbrecord
            changed = false
            period = period_hash[lesson.period_ident]
            starts_at = Time.zone.parse("#{date.to_s} #{period.time.starts_at}")
            ends_at   = Time.zone.parse("#{date.to_s} #{period.time.ends_at}")
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

    else
      puts "Couldn't find lesson entries for #{date.strftime("%A")} of week #{week_letter}."
    end
  end
end
#results = RubyProf.stop
#File.open("profile-graph.html", 'w') do |file|
#  RubyProf::GraphHtmlPrinter.new(results).print(file)
#end
#File.open("profile-flat.txt", 'w') do |file|
#  RubyProf::FlatPrinter.new(results).print(file)
#end
#File.open("profile-tree.prof", 'w') do |file|
#  RubyProf::CallTreePrinter.new(results).print(file)
#end

