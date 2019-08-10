#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLTimetableAllocation
  FILE_NAME = 'TblTimetableManagerWeeksAllocations.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerWeeksAllocationsID',
                                   :id,                :integer],
    Column['intYearWeek',          :week,              :integer],
    Column['intYear',              :year,              :integer],
    Column['intWeek',              :timetable_week_id, :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def generate_entry(xml)
    xml.TimetableAllocation(Id: self.id) do
      xml.Week            self.week
      xml.Year            self.year
      xml.TimetableWeekId self.timetable_week_id
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@allocations = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@allocations.each do |allocation|
      allocation.generate_entry(xml)
    end
  end

end
