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

  attr_reader :teacher_ids

  def adjust(accumulator)
    @complete = true
    #
    #  It seems that currently all the groups are inactive.  Load
    #  them anyway for now.
    #
    #@complete = @active
  end

  def wanted?
    @complete
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
