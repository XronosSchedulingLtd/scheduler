require 'csv'

class MIS_ScheduleEntry
  def entry_type
    if self.instance_of?(ISAMS_TimetableEntry)
      "Timetable"
    elsif self.instance_of?(ISAMS_MeetingEntry)
      "Meeting"
    elsif self.instance_of?(ISAMS_OtherHalfEntry)
      "Other Half"
    elsif self.instance_of?(ISAMS_TutorialEntry)
      "Tutorial"
    elsif self.instance_of?(ISAMS_YeargroupEntry)
      "Year group"
    else
      "Surprising"
    end
  end

  def week_letter
    if self.period
      self.period.day.week.short_name
    else
      "UNK"
    end
  end

  def day_of_week
    if self.period
      self.period.day.name
    else
      ""
    end
  end

  def period_name
    if self.period
      self.period.short_name
    else
      ""
    end
  end

  def subject_name
    if self.respond_to?(:subject) && self.subject
      self.subject.name
    else
      ""
    end
  end

  def staff_initials
    self.staff.collect {|s| s.initials}.join(",")
  end

  def room_names
    self.rooms.collect {|r| r.short_name}.join(",")
  end

  def s_yeargroup
    yg = self.yeargroup
    if yg == 0
      ""
    else
      "S#{self.yeargroup}"
    end
  end

  #
  #  Convert this schedule entry to an array to allow it to be
  #  saved to a CSV file.
  #
  def to_a
    [self.entry_type,
     self.period_id,
     self.week_letter,
     self.day_of_week,
     self.period_name,
     self.body_text,
     self.subject_name,
     self.s_yeargroup,
     self.staff_initials,
     self.room_names]
  end

end

class MIS_Schedule

  def save_to_csv
    CSV.open(Rails.root.join(IMPORT_DIR, "forotl.csv"), "w") do |file|
      @entries.each do |e|
        file << e.to_a
      end
    end
  end

end

class MIS_Timetable
  def save_to_csv
    @schedule.save_to_csv
  end
end

