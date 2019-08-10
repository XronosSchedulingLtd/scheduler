#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLTutorial
  FILE_NAME = 'TblTimetableManagerTutorials.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerTutorialsId', :id,           :integer],
    Column['intTimetableId',                 :timetable_id, :integer],
    Column['txtDisplayCode',                 :display_code, :string],
    Column['txtDisplayName',                 :display_name, :string],
    Column['intRoom',                        :room_id,      :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    timetable = accumulator[:timetables_by_id][self.timetable_id]
    if timetable
      timetable.note_tutorial(self)
      @periods  = []
      @pupils   = []
      @teachers = []
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

  def note_period(period)
    @periods << period
  end

  def note_pupil(pupil)
    @pupils << pupil
  end

  def note_teacher(teacher)
    @teachers << teacher
  end

  def generate_entry(xml)
    xml.Tutorial(Id: self.id) do
      xml.DisplayCode self.display_code
      xml.DisplayName self.display_name
      xml.RoomId      self.room_id
      unless @periods.empty?
        xml.Periods do
          @periods.each do |period|
            period.generate_entry(xml)
          end
        end
      end
      unless @pupils.empty?
        xml.Pupils do
          @pupils.each do |pupil|
            pupil.generate_entry(xml)
          end
        end
      end
      unless @teachers.empty?
        xml.Teachers do
          @teachers.each do |teacher|
            teacher.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, true)
    if records
      accumulator[:tutorials_by_id] = records.collect {|r| [r.id, r]}.to_h
      true
    else
      puts message
      false
    end
  end

end
