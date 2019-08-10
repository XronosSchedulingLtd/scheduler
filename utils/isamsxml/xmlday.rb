#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLDay
  FILE_NAME = 'TblTimetableManagerDays.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerDaysID',  :id,         :integer],
    Column['txtName',                    :name,       :string],
    Column['txtShortName',               :short_name, :string],
    Column['intWeek',                    :week_id,    :integer],
    Column['intDay',                     :day_no,     :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @periods = []
    week = accumulator[:weeks_by_id][self.week_id]
    if week
      week.note_day(self)
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def note_period(period)
    @periods << period
  end

  def generate_entry(xml)
    xml.Day(Id: self.id) do
      xml.Name      self.name
      xml.ShortName self.short_name
      xml.Day       self.day_no
      unless @periods.empty?
        xml.Periods do
          @periods.each do |period|
            period.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:days_by_id] = records.collect {|r| [r.id, r]}.to_h
      true
    else
      puts message
      false
    end
  end

end
