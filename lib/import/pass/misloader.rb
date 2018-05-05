# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

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

  class PASS_Data < Hash
    attr_reader :loader

    TO_SLURP = [
      PASS_TimetableRecord,
      PASS_SubjectSetRecord
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
    puts "OK chaps - prepare yourselves!"
    PASS_Data.new(self, options)
  end

end
