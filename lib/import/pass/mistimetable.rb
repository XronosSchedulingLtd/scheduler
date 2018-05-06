# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class PASS_PeriodTime < MIS_PeriodTime
  def initialize(textual_period_time)
    splut = textual_period_time.split(" ")
    starts_at = splut[0][0,5]
    ends_at = splut[2][0,5]
    super(starts_at, ends_at)
  end
end

class PASS_ScheduleEntry < MIS_ScheduleEntry

  attr_reader :subject, :week_letter, :day_name, :period_time

  def initialize(entry)
    super()
    @lesson_id   = entry.lesson_id
    @lesson_desc = entry.lesson_desc
    @staff_id    = entry.staff_id
    @room        = entry.room
    #
    #  This is a bit weird, but the Pass data which we can access has
    #  been "helpfully" massaged, making it harder to process.
    #  To match up the sets, we need to use the name of the lesson.
    #
    @set_code    = entry.lesson_desc
    #
    #  This next line is seriously non-defensive.
    #
    @day_name, @week_letter = entry.day_name.split(" ")
    @period_time = PASS_PeriodTime.new(entry.period_time)
  end

  def adjust
    #
    #  If we end up merging this lesson, then we will want to keep
    #  track of all the individual original iSAMS IDs.
    #
    #  For consistency, even non-merged lessons will have an array
    #  of size 1.
    #
    @isams_ids = [@isams_id]
    @teacher_ids = [@teacher_id]
    #
    #  So that later, given a lesson id, we can work out who the
    #  teacher of that particular instance is.
    #
    @lesson_teacher_hash = Hash.new
    @lesson_teacher_hash[@isams_id] = @teacher_id
  end

  def find_resources(loader)
    if @staff_id
      staff = loader.staff_hash[@staff_id]
      if staff
        @staff << staff
      end
    end
    if @room
      room = loader.location_hash[@room.to_i(36)]
      if room
        @rooms << room
      end
    end
    if @set_code
      group = loader.teachinggroup_hash[@set_code]
      if group
        @groups << group
        @subject = group.subject
        if @subject
          @subjects << @subject
        end
      end
    end
#    group = loader.tegs_by_name_hash[@code]
#    if group
#      @groups << group
#      @subject = group.subject
#      if @subject
#        @subjects << @subject
#      end
#    else
#      @subject = nil
#    end
#    @teacher_ids.each do |teacher_id|
#      staff = loader.secondary_staff_hash[teacher_id]
#      if staff
#        @staff << staff
#      end
#    end
#    room = loader.location_hash[@room_id]
#    if room
#      @rooms << room
#    end
  end

  def note_period(period)
    @period = period
  end

  def source_hash
    "Lesson #{@lesson_id}"
  end

  def body_text
    @lesson_desc
  end

  def eventcategory
    Eventcategory.cached_category("Lesson")
  end

  #
  #  What year group (in Scheduler's terms) are involved in this event.
  #  Return 0 if we don't know, or have a mixture.
  #
  def yeargroup
    yeargroups = Array.new
    @groups.each do |group|
      yeargroups << group.yeargroup
    end
    #
    #  Hoping for exactly one.
    #
    if yeargroups.uniq.size == 1
      yeargroups[0]
    else
      0
    end
  end

end


class MIS_Schedule

  attr_reader :entries

  def initialize(loader, miss_data)
    @lessons_by_id = Hash.new
    #
    #  The Pass data file contains one record per student in a lesson.
    #  We want to consolidate this into unique lessons.
    #
    miss_data[:timetable_records].each do |record|
      @lessons_by_id[record.lesson_id] ||= PASS_ScheduleEntry.new(record)
    end
    @entries = @lessons_by_id.values
    @entries.each do |entry|
      entry.find_resources(loader)
    end
    if loader.options.activities
      @oh_events.each do |entry|
        entry.find_resources(loader)
      end
    end
  end

  def lesson_by_id(id)
    @lessons_by_id[id]
  end

  def entry_count
    @entries.count
  end

  #
  #  Note that we are deliberately over-riding this method from its
  #  earlier definition.  We need to do more, because we have the oh_events
  #  to worry about too.
  #
  def note_hiatuses(loader, hiatuses)
    @entries.each do |entry|
      entry.note_hiatuses(loader, hiatuses)
    end
  end


end


class MIS_Timetable

  def initialize(loader, mis_data)
    #
    #  We shall want access to the week identifier later.
    #
    @week_identifier = loader.week_identifier
    @week_hash = Hash.new
  end

  #
  #  This is a separate step, which has to happen after we've found
  #  all necessary teaching groups.
  #
  def build_schedule(loader, mis_data)
    @schedule = MIS_Schedule.new(loader, mis_data)
    @schedule.entries.each do |entry|
      @week_hash[entry.week_letter] ||= Hash.new
      @week_hash[entry.week_letter][entry.day_name] ||= Array.new
      @week_hash[entry.week_letter][entry.day_name] << entry
    end
  end

  def entry_count
    @schedule.entry_count
  end

  def lessons_on(date)
    #
    #  Note that more than one week may be extant on the indicated date.
    #
    day_of_week = date.strftime("%A")
    week_letter = @week_identifier.week_letter(date)
    right_week = @week_hash[week_letter]
    lessons = []
    if right_week
      right_day = right_week[day_of_week]
      if right_day
        lessons = right_day
      end
    end
    lessons
  end

end


