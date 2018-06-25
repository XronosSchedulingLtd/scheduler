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

  def to_s
    "#{@starts_at} - #{@ends_at}"
  end
end

class PASS_ScheduleEntry < MIS_ScheduleEntry

  attr_reader :subject,
              :day_name,
              :period_time,
              :staff_id,
              :set_code,
              :lesson_id,
              :room_id

  def initialize(entry)
    super()
    @prepable    = true
    @lesson_id   = entry.lesson_id
    @lesson_desc = entry.lesson_desc
    @staff_id    = entry.staff_id
    @room_id     = entry.room
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
    #
    #  If we end up merging this lesson, then we will want to keep
    #  track of all the individual original MIS data.
    #
    #  For consistency, even non-merged lessons will have an array
    #  of size 1.
    #
    @lesson_ids = [@lesson_id]
    @staff_ids  = [@staff_id]
    @room_ids   = [@room_id]
    #
    #  So that later, given a lesson id, we can work out who the
    #  teacher of that particular instance is.
    #
    @lesson_teacher_hash = Hash.new
    @lesson_teacher_hash[@lesson_id] = @staff_id
  end

  def find_resources(loader, mis_data)
    @staff_ids.each do |staff_id|
      staff = loader.staff_hash[staff_id]
      if staff
        @staff << staff
      end
    end
    @room_ids.each do |room_id|
      room = loader.location_hash[room_id.to_i(36)]
      if room
        @rooms << room
      end
    end
    if @set_code
      groups = mis_data[:tgs_hash][@set_code]
      if groups
        groups.each do |nc_year, group|
          @groups << group
          @subject = group.subject
          if @subject
            @subjects << @subject unless @subjects.include?(@subject)
          end
        end
      end
    end
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

  def body_text=(new_text)
    @lesson_desc = new_text
  end

  def eventcategory
    Eventcategory.cached_category("Lesson")
  end

  #
  #  What year groups (in Scheduler's terms) are involved in this event.
  #  Return an array containing 0 if we don't know.
  #
  def yeargroups
    yeargroups = Array.new
    @groups.each do |group|
      yeargroups << group.yeargroup
    end
    yeargroups.compact!
    if yeargroups.empty?
      yeargroups << 0
    end
    yeargroups
  end

  #
  #  Merging lessons with same name and time.
  #
  def hash_key
    "#{@lesson_desc}/#{@period_time.to_s}/#{@day_name}/#{@week_letter}"
  end

  #
  #  Merge another lesson into this one, keeping note of crucial data.
  #
  def merge(other)
    #
    #  Merge another of the same into this one.
    #
    @staff_ids  << other.staff_id
    @lesson_ids << other.lesson_id
    @room_ids   << other.room_id
    #
    #  Since in reality lessons may well have more than one teacher,
    #  we need to keep track of which teacher belongs to which
    #  original lesson record.
    #
    @lesson_teacher_hash[other.lesson_id] = other.staff_id
  end

  def taught_by?(staff_id)
    @staff_ids.include?(staff_id)
  end

  def short_day_of_week
    self.day_name[0,3]
  end
end


class MIS_Schedule

  attr_reader :entries

  def initialize(loader, mis_data)
    @lessons_by_id = Hash.new
    #
    #  The Pass data file contains one record per student in a lesson.
    #  We want to consolidate this into unique lessons.
    #
    mis_data[:timetable_records].each do |record|
      @lessons_by_id[record.lesson_id] ||= PASS_ScheduleEntry.new(record)
    end
    #
    #  At this point, we see whether we can merge duplicate lessons.
    #  These happen where two different teachers are taking the same
    #  lesson (e.g. sport).
    #
    lesson_hash = Hash.new
    @lessons_by_id.values.each do |lesson|
      existing = lesson_hash[lesson.hash_key]
      if existing
        existing.merge(lesson)
      else
        lesson_hash[lesson.hash_key] = lesson
      end
    end
    @entries = lesson_hash.values
    #
    #  And now find the resources.
    #
    @entries.each do |entry|
      entry.find_resources(loader, mis_data)
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


