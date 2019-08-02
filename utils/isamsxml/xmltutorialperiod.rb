#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLTutorialPeriod
  FILE_NAME = 'TblTimetableManagerTutorialsPeriods.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerTutorialsPeriodsId', :id,          :integer],
    Column['intTutorial',                           :tutorial_id, :integer],
    Column['intPeriod',                             :period_id,   :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    tutorial = accumulator[:tutorials_by_id][self.tutorial_id]
    if tutorial
      tutorial.note_period(self)
      @wanted = true
    else
      @wanted = false
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @wanted
  end

  def generate_entry(xml)
    xml.Period(Id: self.id) do
      xml.PeriodId self.period_id
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      true
    else
      puts message
      false
    end
  end

end
