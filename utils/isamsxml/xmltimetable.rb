#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLTimetable
  FILE_NAME = 'TblTimetableManagerTimetables.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerTimetablesID', :id,         :integer],
    Column['txtName',                         :name,       :string],
    Column['intPublished',                    :published,  :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @schedules = []
    @meetings = []
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    #
    #  iSAMS's user interface constrains you to having just one
    #  published timetable, but the database structures could potentially
    #  allow more than one.
    #
    self.published == 1
  end

  def note_schedule_entry(schedule)
    @schedules << schedule
  end

  def note_meeting(meeting)
    @meetings << meeting
  end

  def generate_entry(xml)
    xml.Timetable(Id: self.id) do
      xml.Name      self.name
      unless @schedules.empty?
        xml.Schedules do
          @schedules.each do |schedule|
            schedule.generate_entry(xml)
          end
        end
      end
      unless @meetings.empty?
        xml.StaffMeetings do
          @meetings.each do |meeting|
            meeting.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:timetables_by_id] = records.collect {|r| [r.id, r]}.to_h
      @@timetables = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@timetables.each do |timetable|
      timetable.generate_entry(xml)
    end
  end

end
