# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class PASS_CoverRecord
  FILE_NAME = "CH_AC_PROVIDING_COVER.csv"

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
    Column["TASK_END",            :task_end,            :datetime]
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
  FILE_NAME = "CH_AC_NEEDING_COVER.csv"
  REQUIRED_COLUMNS = [
    Column["REQUIRING_COVER_STAFF_ID", :covered_staff_id,   :integer],
    Column["TASK_TEACHER_NAME",        :covered_staff_name, :string],
    Column["LESSON_ID",                :cover_id,           :integer],
    Column["TASK_END",                 :task_end,           :datetime]
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
        puts "Got #{records.count} Cover needed records."
      end
      #
      #  Do these as a hash for ease of lookup.
      #
      cnr_hash = Hash.new
      records.each do |record|
        cnr_hash[record.cover_id] = record
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
  FILE_NAME = "CH_AC_TIMETABLE.csv"
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
  FILE_NAME = "CH_AD_CURR_SUBJECTS.csv"
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
  FILE_NAME = "CH_AC_SUBJECT_SETS.csv"
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

  attr_reader :staff_by_name

  class PASS_Data < Hash
    attr_reader :loader

    TO_SLURP = [
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

  def mis_specific_preparation
    #
    #  Incredibly, it seems we can't rely on staff ids being consistent
    #  through the Pass data.  We therefore have to use names.
    #
    @staff_by_name = Hash.new
    @staff.each do |staff|
      @staff_by_name[staff.formal_name] = staff
    end
  end

end
