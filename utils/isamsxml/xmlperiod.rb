#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLPeriod
  FILE_NAME = 'TblTimetableManagerPeriods.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerPeriodsID', :id,         :integer],
    Column['intDay',                       :day_id,     :integer],
    Column['txtName',                      :name,       :string],
    Column['txtShortName',                 :short_name, :string],
    Column['txtStartTime',                 :start_time, :string],
    Column['txtEndTime',                   :end_time,   :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @periods = []
    day = accumulator[:days_by_id][self.day_id]
    if day
      day.note_period(self)
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def generate_entry(xml)
    xml.Period(Id: self.id) do
      xml.Name      self.name
      xml.ShortName self.short_name
      xml.StartTime self.start_time
      xml.EndTime   self.end_time
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      true
    else
      puts message
      false
    end
  end

end
