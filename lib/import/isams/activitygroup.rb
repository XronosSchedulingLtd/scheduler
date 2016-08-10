#
#  Class for ISAMS Activity Manager Group records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_ActivityGroup
  FILE_NAME = "TblActivityManagerGroup.csv"
  REQUIRED_COLUMNS = [
    Column["TblActivityManagerGroupId",    :ident,       :integer],
    Column["txtName",                      :name,        :string],
    Column["intActivity",                  :activity_id, :integer],
    Column["dteStartDate",                 :start_date,  :date],
    Column["dteEndDate",                   :end_date,    :date],
    Column["blnActive",                    :active,      :boolean]
  ]

  include Slurper

  attr_accessor :timeslot

  attr_reader :pupil_ids

  def adjust(accumulator)
    @complete = true
    @pupil_ids = Array.new
    #
    #  Don't want any group records which lie entirely in the past.
    #
    if end_date && end_date < accumulator.loader.start_date
      @complete = false
    end
  end

  def wanted?
    @complete
  end

  def note_pupil_id(pupil_id)
    @pupil_ids << pupil_id
  end

  #
  #  Set ourselves up and add ourselves to the accumulator.
  #
  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:groups] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end
