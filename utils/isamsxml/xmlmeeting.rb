#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class XMLMeeting
  FILE_NAME = 'TblTimetableManagerStaffMeetings.csv'
  REQUIRED_COLUMNS = [
    Column['TblTimetableManagerStaffMeetingsID', :id,           :integer],
    Column['intTimetableID',                     :timetable_id, :integer],
    Column['intPeriod',                          :period_id,    :integer],
    Column['txtTeacher',                         :teacher_id,   :string],
    Column['intMeetingGroup',                    :meeting_id,   :integer],
    Column['intRoom',                            :room_id,      :integer],
    Column['txtDisplayName',                     :display_name, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    timetable = accumulator[:timetables_by_id][self.timetable_id]
    if timetable
      timetable.note_meeting(self)
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
    xml.StaffMeeting(Id: self.id) do
      xml.PeriodId       self.period_id
      xml.TeacherId      self.teacher_id
      xml.MeetingGroupId self.meeting_id
      if self.room_id
        xml.RoomId         self.room_id
      end
      xml.DisplayName    self.display_name
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
