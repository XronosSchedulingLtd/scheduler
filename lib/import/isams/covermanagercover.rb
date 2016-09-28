#
#  Class for ISAMS Cover Manager Cover records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_Cover
  FILE_NAME = "TblCoverManagerCover.csv"
  REQUIRED_COLUMNS = [
    Column["TblCoverManagerCoverID",        :ident,             :integer],
    Column["intCycle",                      :cycle,             :integer],
    Column["TblTimetableManagerScheduleID", :schedule_id,       :integer],
    Column["blnRecurring",                  :recurring,         :boolean],
    Column["dteDate",                       :date,              :date],
    Column["txtCoverTeacher",               :teacher_school_id, :string],
    Column["blnVisible",                    :visible,           :boolean],
    Column["blnEnabled",                    :enabled,           :boolean],
    Column["blnPublished",                  :published,         :boolean]
  ]

  include Slurper

  def adjust(accumulator)
    #
    #  Don't want covers in the past.
    #
    @complete = (@date >= accumulator.loader.start_date)
  end

  def wanted?
    @complete && active
  end

  #
  #  Set ourselves up and add ourselves to the accumulator.
  #
  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      if accumulator.loader.options.verbose
        puts "Got #{records.count} active cover records."
      end
      accumulator[:covers] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end
