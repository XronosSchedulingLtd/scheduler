#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLWeek
  FILE_NAME = 'TblTimetableManagerWeeks.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerWeeksID', :id,         :integer],
    Column['txtName',                    :name,       :string],
    Column['txtShortName',               :short_name, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @days = []
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def note_day(day)
    @days << day
  end

  def generate_entry(xml)
    xml.Week(Id: self.id) do
      xml.Name      self.name
      xml.ShortName self.short_name
      unless @days.empty?
        xml.Days do
          @days.each do |day|
            day.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:weeks_by_id] = records.collect {|r| [r.id, r]}.to_h
      @@weeks = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@weeks.each do |week|
      week.generate_entry(xml)
    end
  end

end
