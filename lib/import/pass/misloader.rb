# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

DB_TABLE_PREFIX = ENV["DB_TABLE_PREFIX"]
if DB_TABLE_PREFIX.nil?
  puts "DB_TABLE_PREFIX needs to be defined in ~/etc/whichsystem."
  exit 1
end

class PASS_PupilRecord
  FILE_NAME = "#{DB_TABLE_PREFIX}_AD_CURR_BASIC_DETAILS.csv"

  REQUIRED_COLUMNS = [
    Column["PUPIL_ID",                   :pupil_id,                   :integer],
    Column["FORM",                       :form_code,                  :string],
    Column["FORM_DESCRIPTION",           :form_description,           :string],
    Column["FORM_TUTOR",                 :tutor_code,                 :string],
    Column["FORM_TUTOR_NAME",            :tutor_name,                 :string],
    Column["FORM_YEAR",                  :form_year,                  :string],
    Column["SURNAME",                    :surname,                    :string],
    Column["FIRST_NAMES",                :first_names,                :string],
    Column["PREFERRED_NAME",             :preferred_name,             :string],
    Column["ACADEMIC_HOUSE",             :academic_house,             :string],
    Column["ACADEMIC_HOUSE_DESCRIPTION", :academic_house_description, :string]
  ]

  include Slurper

  def adjust(accumulator)
  end

  def wanted?
    #
    #  Pupils with no year group are not wanted.
    #
    !self.form_year.blank?
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} pupil records."
      end
      pupils_by_id = Hash.new
      pupils_by_form = Hash.new
      records.each do |record|
        pupils_by_id[record.pupil_id] = record
        unless record.form_code.blank?
          (pupils_by_form[record.form_code] ||= Array.new) << record
        end
      end
      accumulator[:pupils_by_id] = pupils_by_id
      accumulator[:pupils_by_form] = pupils_by_form
      true
    else
      puts message
      false
    end
  end
end


class PASS_StaffRecord
  FILE_NAME = "#{DB_TABLE_PREFIX}_ST_DETAILS.csv"

  REQUIRED_COLUMNS = [
    Column["STAFF_ID",               :staff_id,       :integer],
    Column["LEAVE_DATE",             :leave_date,     :date],
    Column["CODE",                   :initials,       :string],
    Column["NAME",                   :formal_name,    :string],
    Column["SURNAME",                :surname,        :string],
    Column["FIRST_NAMES",            :first_names,    :string],
    Column["PREFERRED_NAME",         :preferred_name, :string],
    Column["TITLE",                  :title,          :string],
    Column["INTERNAL_EMAIL_ADDRESS", :email,          :string]
  ]

  include Slurper

  def adjust(accumulator)
  end

  def wanted?
    true
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} staff records."
      end
      staff_by_id = Hash.new
      records.each do |record|
        staff_by_id[record.staff_id]             = record
      end
      accumulator[:staff_by_id] = staff_by_id
      true
    else
      puts message
      false
    end
  end
end

class PASS_CoverRecord
  FILE_NAME = "#{DB_TABLE_PREFIX}_AC_PROVIDING_COVER.csv"

  #
  #  The LESSON_ID field in the Pass cover record is badly mis-named.
  #  It's not the lesson id as you might expect, instead it's an
  #  ID identifying the particular instance of cover.
  #
  REQUIRED_COLUMNS = [
    Column["COVERING_STAFF_ID",   :covering_staff_id,   :integer],
    Column["COVERER_NAME",        :coverer_name,        :string],
    Column["LESSON_ID",           :cover_id,            :integer],
    Column["TASK_START",          :task_start,          :datetime],
    Column["TASK_END",            :task_end,            :datetime],
    Column["TASK_CODE",           :task_code,           :string],
    Column["TASK_ROOM_CODE",      :room_code,           :string]
  ]

  include Slurper

  def adjust(accumulator)
    #
    #  Don't want covers in the past.
    #
    @complete = (@task_end >= accumulator.loader.start_date)
  end

  def wanted?
    @complete
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} Cover records."
      end
#      records.each do |record|
#        puts "Cover by #{record.coverer_name}, lesson id #{record.lesson_id}, at #{record.task_start}."
#      end
      accumulator[:cover_records] = records
      true
    else
      puts message
      false
    end
  end

end

class PASS_CoverNeededRecord
  FILE_NAME = "#{DB_TABLE_PREFIX}_AC_NEEDING_COVER.csv"
  REQUIRED_COLUMNS = [
    Column["REQUIRING_COVER_STAFF_ID", :covered_staff_id,   :integer],
    Column["TASK_TEACHER_NAME",        :covered_staff_name, :string],
    Column["LESSON_ID",                :cover_id,           :integer],
    Column["TASK_START",               :task_start,         :datetime],
    Column["TASK_END",                 :task_end,           :datetime],
    Column["TASK_CODE",                :task_code,          :string],
    Column["TASK_ROOM_CODE",           :room_code,          :string],
    Column["COVERED",                  :covered_flag,       :string]
  ]

  include Slurper

  attr_accessor :used

  def adjust(accumulator)
    #
    #  Don't want covers in the past.  Or those with an F in the COVERED
    #  field.
    #
    @complete = (@task_end >= accumulator.loader.start_date)
    @used = false
  end

  def wanted?
    @complete
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} Cover needed records."
      end
      #
      #  Do these as a hash for ease of lookup.
      #  There may be more than one record for a given cover id.
      #  Put them in an array under the ID, to be searched through later.
      #
      cnr_hash = Hash.new
      records.each do |record|
        (cnr_hash[record.cover_id] ||= Array.new) << record
      end
      accumulator[:cover_needed_records] = cnr_hash
      true
    else
      puts message
      false
    end
  end

end

class PASS_TimetableRecord
  #
  #  The first two characters should be configurable.
  #
  FILE_NAME = "#{DB_TABLE_PREFIX}_AC_TIMETABLE.csv"
  REQUIRED_COLUMNS = [
    Column["DAY_NAME",            :day_name,            :string],
    Column["PERIOD_TIME",         :period_time,         :string],
    Column["SET_CODE",            :set_code,            :string],
    Column["ROOM",                :room,                :string],
    Column["ROOM_DESCRIPTION",    :room_description,    :string],
    Column["PUPIL_ID",            :pupil_id,            :integer],
    Column["STAFF_ID",            :staff_id,            :integer],
    Column["TUTOR",               :tutor,               :string],
    Column["INFORMAL_SALUTATION", :informal_salutation, :string],
    Column["LABEL_SALUTATION",    :label_salutation,    :string],
    Column["LESSON_ID",           :lesson_id,           :integer],
    Column["LESSON_DESC",         :lesson_desc,         :string]
  ]

  include Slurper

  def adjust(accumulator)
  end

  def wanted?
    true
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} Pass timetable records."
      end
      accumulator[:timetable_records] = records
      true
    else
      puts message
      false
    end
  end
end

class PASS_SubjectRecord
  FILE_NAME = "#{DB_TABLE_PREFIX}_AD_CURR_SUBJECTS.csv"
  REQUIRED_COLUMNS = [
    Column["CODE",        :code,        :string],
    Column["DESCRIPTION", :description, :string],
    Column["SUBJECT_ID",  :id,          :integer],
    Column["STATUS",      :status,      :string]
  ]

  include Slurper

  def adjust(accumulator)
  end

  def wanted?
    @status == "ACTIVE"
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} Pass subject records."
      end
      accumulator[:subjects] = records
      true
    else
      puts message
      false
    end
  end
end

class PASS_SubjectSetRecord
  #
  #  The first two characters should be configurable.
  #
  FILE_NAME = "#{DB_TABLE_PREFIX}_AC_SUBJECT_SETS.csv"
  REQUIRED_COLUMNS = [
    Column["PUPIL_ID",            :pupil_id,            :integer],
    Column["SUBJECT_SET_ID",      :subject_set_id,      :string],
    Column["SUBJECT_CODE",        :subject_code,        :string],
    Column["SUBJECT_DESCRIPTION", :subject_description, :string],
    Column["CODEONLY",            :set_short_code,      :string],
    Column["DESCRIPTION",         :set_long_name,       :string],
    Column["SET_CODE",            :set_code,            :string],
    Column["TUTOR_1_NAME",        :teacher_name,        :string]
  ]

  include Slurper

  def adjust(accumulator)
  end

  def wanted?
    true
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} Pass subject set records."
      end
      accumulator[:set_records] = records
      true
    else
      puts message
      false
    end
  end
end

IMPORT_DIR = 'import'
PASS_IMPORT_DIR = 'import/pass/Current'

class MIS_Loader

  class PASS_Data < Hash
    attr_reader :loader

    TO_SLURP = [
      PASS_PupilRecord,
      PASS_StaffRecord,
      PASS_TimetableRecord,
      PASS_SubjectRecord,
      PASS_SubjectSetRecord,
      PASS_CoverRecord,
      PASS_CoverNeededRecord
    ]

    def initialize(loader, options)
      super()
      @loader = loader
      @options = options
      full_dir_path = Rails.root.join(PASS_IMPORT_DIR)
      TO_SLURP.each do |pass_type|
        unless pass_type.construct(self, full_dir_path)
          puts "Failed to load #{pass_type}"
        end
      end
    end
  end

  def prepare(options)
    PASS_Data.new(self, options)
  end

end
