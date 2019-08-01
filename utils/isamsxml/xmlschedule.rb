#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  This one is a bit of a misnomer - it's not a schedule, it's a schedule
#  entry - one individual line, a whole bunch of which make a schedule.
#
class XMLSchedule
  FILE_NAME = 'TblTimetableManagerSchedule.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerScheduleID', :id,           :integer],
    Column['intTimetableID',                :timetable_id, :integer],
    Column['txtCode',                       :code,         :string],
    Column['txtTeacher',                    :teacher,      :string],
    Column['intPeriod',                     :period_id,    :integer],
    Column['intRoom',                       :room_id,      :integer],
    #
    #  And this next one is completely mis-named.  It's not a set id,
    #  it's a value indicating whether this is a Teaching Set or a
    #  Teaching Form.
    #
    #  The iSAMS XML definition however calls it "SetID" so we'll
    #  stick to that.  Nasty.
    #
    Column['intSet',                        :set_id,       :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    timetable = accumulator[:timetables_by_id][self.timetable_id]
    if timetable
      timetable.note_schedule_entry(self)
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
    xml.Schedule(Id: self.id) do
      xml.Code      self.code
      xml.Teacher   self.teacher
      xml.PeriodId  self.period_id
      xml.RoomId    self.room_id
      xml.SetId     self.set_id
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
