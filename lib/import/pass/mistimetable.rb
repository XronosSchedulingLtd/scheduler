# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_ScheduleEntry
  SELECTOR = "Schedules Schedule"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,   :attribute, :integer],
    IsamsField["Code",      :code,       :data,      :string],
    IsamsField["Teacher",   :teacher_id, :data,      :string],
    IsamsField["PeriodId",  :period_id,  :data,      :integer],
    IsamsField["RoomId",    :room_id,    :data,      :integer],
    IsamsField["SetId",     :set_id,     :data,      :integer]
  ]

  include Creator

  attr_reader :subject, :isams_ids

  def initialize(entry)
    super()
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
    #
    #  iSAMS suffers from the same design flaw as SB, in that each
    #  lesson can involve at most one teacher, one group and one
    #  room.  I may need to implement a merging strategy as I did
    #  for SB.
    #
    #  This code also currently suffers from a lack of defensiveness.
    #  It assumes that the data coming from iSAMS will be correct.
    #  Needs reinforcing.
    #
    group = loader.tegs_by_name_hash[@code]
    if group
      @groups << group
      @subject = group.subject
      if @subject
        @subjects << @subject
      end
    else
      @subject = nil
    end
    @teacher_ids.each do |teacher_id|
      staff = loader.secondary_staff_hash[teacher_id]
      if staff
        @staff << staff
      end
    end
    room = loader.location_hash[@room_id]
    if room
      @rooms << room
    end
  end

  def note_period(period)
    @period = period
  end

  def period_time
    @period.period_time
  end

  def source_hash
    if @isams_ids.size == 1
      "Lesson #{@isams_id}"
    else
      #
      #  It is just possible that the order in which iSAMS provides
      #  the individual lesson records might change even though
      #  the lessons haven't.  Sort them into numerical order to
      #  cope with this.
      #
      "Lessons #{@isams_ids.sort.join(",")}"
    end
  end

  def body_text
    @code
  end

  def eventcategory
    #
    #  This needs fixing very quickly.
    #
    Eventcategory.find_by(name: "Lesson")
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

  #
  #  We merge lessons provided they have:
  #
  #    Same timing
  #    Same group of pupils
  #    Same lesson name
  #    Same room
  #
  #  We thus need a hash key which will reflects all of these.
  #
  def hash_key
    "#{self.code}/#{self.period_id}/#{self.room_id}"
  end

  #
  #  Merge another lesson into this one, keeping note of crucial data.
  #
  def merge(other)
    #
    #  Merge another of the same into this one.
    #
    @teacher_ids << other.teacher_id
    @isams_ids << other.isams_id
    #
    #  The cover records coming from iSAMS are also deficient.  They
    #  record who is doing the cover, but not which teacher they are
    #  covering.  They rely on the fact that iSAMS lessons can manage
    #  only one teacher per lesson.
    #
    #  Since in reality lessons may well have more than one teacher,
    #  we need to keep track of which teacher belongs to which
    #  original lesson record.
    #
    @lesson_teacher_hash[other.isams_id] = other.teacher_id
  end

  def original_teacher_id(isams_id)
    @lesson_teacher_hash[isams_id]
  end

  def self.construct(loader, inner_data)
    lessons = self.slurp(inner_data)
    #
    #  iSAMS can cope with only one teacher per lesson, but it's perfectly
    #  feasible to want more than one.  The only way around it within iSAMS
    #  is to create parallel lessons for each teacher.
    #
    #  To tidy things up, we merge such cases into a single lesson.
    #
    lesson_hash = Hash.new
    lessons.each do |lesson|
      existing = lesson_hash[lesson.hash_key]
      if existing
        existing.merge(lesson)
      else
        lesson_hash[lesson.hash_key] = lesson
      end
    end
    #
    #  And return the resulting reduced list.
    #
    lesson_hash.values
  end

end


class MIS_Schedule

  attr_reader :entries

  def initialize(loader, isams_data, timetable, period_hash)
    lessons = ISAMS_TimetableEntry.construct(loader, timetable.entry)
    @lessons_by_id = Hash.new
    lessons.each do |lesson|
      #
      #  Each lesson may consist of more than one original iSAMS lesson.
      #  Keep track of them all.
      #
      lesson.isams_ids.each do |isams_id|
        @lessons_by_id[isams_id] = lesson
      end
    end
    #
    #  Now get the meetings.
    #
    meetings = ISAMS_MeetingEntry.construct(loader, timetable.entry)
    #
    #  And full year events.
    #
    year_events = ISAMS_YeargroupEntry.construct(loader, timetable.entry)
    #
    #  And tutorials.
    #
    tutorial_events = ISAMS_TutorialEntry.construct(loader, timetable.entry)
    #
    #  And OH events.
    #
    if loader.options.activities
      @oh_events = ISAMS_OtherHalfEntry.construct(isams_data)
    else
      @oh_events = []
    end
    #
    @entries = lessons + meetings + year_events + tutorial_events
    #
    #  Now each timetable entry needs linking to the relevant day
    #  so that we given a date subsequently, we can work out what day
    #  it is and then return all the relevant lessons.
    #
    @entries.each do |entry|
      period = period_hash[entry.period_id]
      if period
        entry.note_period(period)
        period.day.note_lesson(entry)
      else
        unless entry.code.blank?
          puts "Lesson #{entry.code} references period #{entry.period_id} which doesn't seem to exist."
        end
      end
    end
    @entries.each do |entry|
      entry.find_resources(loader)
    end
    if loader.options.activities
      @oh_events.each do |entry|
        entry.find_resources(loader)
      end
    end
  end

  def lesson_by_id(isams_id)
    @lessons_by_id[isams_id]
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
    #
    #  This is the extra bit.
    #
    @oh_events.each do |ohe|
      ohe.note_hiatuses(loader, hiatuses)
    end
  end


end


class MIS_Timetable

  def initialize(loader, mis_data)
    #
    #  We shall want access to the week identifier later.
    #
    @week_identifier = loader.week_identifier
  end

  #
  #  This is a separate step, which has to happen after we've found
  #  all necessary teaching groups.
  #
  def build_schedule(loader, mis_data)
    @schedule = MIS_Schedule.new(loader, mis_data, @timetable_data)
  end

  def entry_count
    @schedule.entry_count
  end

  def lessons_on(date)
    #
    #  Note that more than one week may be extant on the indicated date.
    #
    weeks = []
    week_allocation =
      @week_allocations_hash["#{date.year}/#{date.loony_isams_cweek}"]
    if week_allocation
      week = @week_hash[week_allocation.timetableweek_id]
      if week
        weeks << week
      end
    elsif
      #
      #  It's possible that the week allocations haven't yet been put into
      #  iSAMS, but we can work them out ourselves.  Relies on someone
      #  having already put them into Scheduler as events, and them
      #  conforming to "WEEK A" => 1, "WEEK B" => 2
      #
      #  This code is very fragile, and intended just as a stopgap.
      #
      ec = Eventcategory.find_by(name: "Week letter")
      if ec
        candidate = Event.events_on(date, nil, ec).take
        if candidate
          char = candidate.body[-1]
          if char == 'A'
            week = @week_hash[1]
          elsif char == 'B'
            week = @week_hash[2]
          else
            week = nil
          end
          if week
            weeks << week
          end
        end
      end
    end
    #
    #  And now any weeks which are not part-timers.
    #  Note that these must be flagged as being intended to come through.
    #
    weeks += @weeks.select {|week| week.load_regardless && !week.part_time}
    lessons = []
    weeks.each do |week|
#      puts "Week: #{week.name}"
      #
      #  iSAMS day numbers are one more than is conventional.
      #
      #  Thus Sun = 1, Mon = 2, etc.
      #
      day = week.day_hash[date.wday + 1]
      if day
        lessons += day.lessons
      end
    end
    if lessons.empty?
      lessons = nil
    end
    if @activities
      oh = ISAMS_OtherHalfEntry.events_on(date)
    else
      oh = nil
    end
    if lessons
      if oh
        lessons + oh
      else
        lessons
      end
    else
      if oh
        oh
      else
        nil
      end
    end
  end

end


