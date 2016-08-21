class MIS_PeriodTime
  def initialize(starts_at, ends_at)
    @starts_at    = starts_at
    @ls_starts_at = starts_at
    @ends_at      = ends_at
    @ls_ends_at   = ends_at
  end

end

class ISAMS_Period
  SELECTOR = "Periods Period"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,   :attribute, :integer],
    IsamsField["Name",      :name,       :data,      :string],
    IsamsField["ShortName", :short_name, :data,      :string],
    IsamsField["StartTime", :start_time, :data,      :string],
    IsamsField["EndTime",   :end_time,   :data,      :string]
  ]
  
  include Creator

  attr_reader :day, :period_time

  def initialize(entry)
  end

  def adjust
    @period_time = MIS_PeriodTime.new(@start_time, @end_time)
  end

  def note_day(day)
    @day = day
  end

  def self.construct(day, day_data)
    periods = self.slurp(day_data)
    periods.each do |period|
      period.note_day(day)
    end
    periods
  end
end

class ISAMS_Day
  #
  #  Note that this selector assumes we are already looking inside a
  #  week entry.
  #
  SELECTOR = "Days Day"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,   :attribute, :integer],
    IsamsField["Name",      :name,       :data,      :string],
    IsamsField["ShortName", :short_name, :data,      :string]
  ]
  
  include Creator

  attr_reader :week, :periods, :lessons

  def initialize(entry)
    @periods = ISAMS_Period.construct(self, entry)
    @lessons = Array.new
  end

  def note_lesson(lesson)
    @lessons << lesson
  end

  def note_week(week)
    @week = week
  end

  def self.construct(week, week_data)
    days = self.slurp(week_data)
    days.each do |day|
      day.note_week(week)
    end
    days
  end

end

class ISAMS_Week
  SELECTOR = "TimetableManager Structure Week"
  REQUIRED_FIELDS = [
    IsamsField["Id",    :isams_id, :attribute, :integer],
    IsamsField["Name",  :name,     :data,      :string]
  ]

  include Creator

  attr_reader :days, :day_hash

  def initialize(entry)
    @days = ISAMS_Day.construct(self, entry)
    @day_hash = Hash.new
    @days.each do |day|
      #
      #  I originally tried to do this using the Ordinal attribute
      #  of the day, but it quickly became apparent that the iSAMS
      #  programmers don't know what ordinal means.
      #
      @day_hash[day.short_name] = day
    end
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data.xml)
  end

end

class ISAMS_ScheduleEntry < MIS_ScheduleEntry
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

  def initialize(entry)
  end

  def adjust
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
    @groups = Array.new
    if @set_id == 1             # By set
      group = loader.tegs_by_name_hash[@code]
      if group
        @groups << group
      end
    elsif @set_id == 0          # By form (tutor group)
      group = loader.tugs_by_name_hash[@code.split[0]]
      if group
        @groups << group
      end
    end
    @staff = Array.new
    staff = loader.secondary_staff_hash[@teacher_id]
    if staff
      @staff << staff
    end
    @rooms = Array.new
    room = loader.location_hash[@room_id]
    if room
      @rooms << room
    end
    #
    #  There is a bug in the iSAMS API in that there is no way of
    #  linking up a lesson taught by form (tutor group in our case)
    #  to its form and subject.  We need to frig to get around it.
    #
    if self.respond_to?(:find_subject)
      self.find_subject(loader)
    end
  end

  def note_period(period)
    @period = period
  end

  def period_time
    @period.period_time
  end

  def source_hash
    "Lesson #{@isams_id}"
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
  def yeargroup(loader)
    if @groups.size > 0
      #
      #  Really we should ask them all.
      #
      @groups[0].yeargroup(loader)
    else
      0
    end
  end

  def self.construct(loader, inner_data)
    self.slurp(inner_data)
  end

end

class ISAMS_MeetingEntry < MIS_ScheduleEntry
  SELECTOR = "StaffMeetings StaffMeeting"
  REQUIRED_FIELDS = [
    IsamsField["Id",             :isams_id,   :attribute, :integer],
    IsamsField["PeriodId",       :period_id,  :data,      :integer],
    IsamsField["TeacherId",      :teacher_id, :data,      :string],
    IsamsField["MeetingGroupId", :meeting_id, :data,      :integer],
    IsamsField["DisplayName",    :name,       :data,      :string]
  ]

  include Creator

  def initialize(entry)
    @teacher_ids = Array.new
  end

  def adjust
    @teacher_ids << @teacher_id
  end

  def merge(other)
    #
    #  Merge another of the same into this one.
    #
    @teacher_ids << other.teacher_id
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
    @groups = Array.new
    @rooms = Array.new
    #
    #  The two above stay empty for now.
    #
    @staff = Array.new
    @teacher_ids.each do |teacher_id|
      staff = loader.secondary_staff_hash[teacher_id]
      if staff
        @staff << staff
      end
    end
  end

  def note_period(period)
    @period = period
  end

  def period_time
    @period.period_time
  end

  def source_hash
    #
    #  Although numeric, return as a string.
    #
    "Meeting #{@isams_id}"
  end

  def body_text
    @name
  end

  def eventcategory
    #
    #  This needs fixing very quickly.
    #
    Eventcategory.find_by(name: "Meeting")
  end

  #
  #  What year group (in Scheduler's terms) are involved in this event.
  #  Return 0 if we don't know, or have a mixture.
  #
  def yeargroup(loader)
    0
  end

  def self.construct(loader, inner_data)
    meetings = self.slurp(inner_data)
    #
    #  iSAMS provides one entry per teacher at a meeting.  Need to merge
    #  these to create on entry per meeting.
    #
    meeting_hash = Hash.new
    meetings.each do |meeting|
      existing = meeting_hash[meeting.meeting_id]
      if existing
        existing.merge(meeting)
      else
        meeting_hash[meeting.meeting_id] = meeting
      end
    end
    #
    #  And return the resulting reduced list.
    #
    meeting_hash.values
  end

end

class ISAMS_OtherHalfEntry < MIS_ScheduleEntry

  attr_reader :period_time, :date

  def initialize(db_entry)
    #
    #  Need to create a period time record to suit ourselves.
    #  It would make sense for all occurences of a particular event
    #  to make use of the same one, since the timing actually comes
    #  from the event and not from the occurence.  Or at least, some
    #  of the timing comes from the event.
    #
#    puts "Processing #{db_entry.event.subject}."
    unless db_entry.event.timeslot
      #
      #  Create an MIS_PeriodTime record and save it in the db_entry event.
      #
      db_entry.event.timeslot =
        MIS_PeriodTime.new(db_entry.event.start_time,
                           db_entry.event.end_time)
    end
    @period_time   = db_entry.event.timeslot
    @date          = db_entry.datetime.to_date
    @name          = db_entry.event.subject
    @isams_id      = db_entry.ident
    @group         = db_entry.event.group
    @location_name = db_entry.event.location.gsub(/ \([^\)]*\)$/, "")
#    if @date
#      puts "Got date - #{@date.iso8601}"
#    else
#      puts "No date"
#    end
    @teacher_ids = db_entry.event.teacher_ids
  end

  def adjust
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
    @groups = Array.new
    group = loader.oh_groups_hash[@group.ident]
    if group
      @groups << group
    end
    @staff = Array.new
    @teacher_ids.each do |teacher_id|
      staff = loader.secondary_staff_hash[teacher_id]
      if staff
        @staff << staff
      end
    end
    @rooms = Array.new
    room = loader.secondary_location_hash[@location_name]
    if room
      @rooms << room
#    else
#      puts "Failed to find \"#{@location_name}\"."
    end
  end

  def source_hash
    #
    #  Although numeric, return as a string.
    #
    "Other half #{@isams_id}"
  end

  def body_text
    @name
  end

  def eventcategory
    #
    #  This needs fixing very quickly.
    #
    Eventcategory.find_by(name: "Other Half")
  end

  #
  #  What year group (in Scheduler's terms) are involved in this event.
  #  Return 0 if we don't know, or have a mixture.
  #
  def yeargroup(loader)
    0
  end

  def self.construct(loader)
    #
    #  We need to get details of OH event occurences from the loader.
    #
    oh_events = Array.new
    occurrences = loader[:eventoccurrences]
    if occurrences
      occurrences.each do |key, record|
        oh_events << self.new(record)
      end
    else
      raise "Can't find OH event occurrences."
    end
    @events_by_date = Hash.new
    oh_events.each do |ohe|
      slot = @events_by_date[ohe.date.iso8601] ||= Array.new
      slot << ohe
    end
    oh_events
  end

  def self.events_on(date)
    result = @events_by_date[date.iso8601]
    #
    #  Don't want to set the hash's default value to an empty array
    #  because I want to be able to test for nil elsewhere.
    #
    if result
      result
    else
      []
    end
  end

end

class ISAMS_DummyGroup
  #
  #  All we actually need to provide for timetable loading to work
  #  is the right element id.
  #
  @group_hash = Hash.new

  attr_reader :element_id

  def initialize(nc_year)
    g = Group.find_by(name: "#{(nc_year - 6).ordinalize} year",
                      era: Setting.perpetual_era)
    if g
      @element_id = g.element.id
    end
  end

  def self.group_for_nc_year(nc_year)
    @group_hash[nc_year] ||= self.new(nc_year)
  end

end

class ISAMS_YeargroupEntry < MIS_ScheduleEntry
  SELECTOR = "YearSchedules YearSchedule"
  REQUIRED_FIELDS = [
    IsamsField["Id",                     :isams_id,   :attribute, :integer],
    IsamsField["Name",                   :name,       :data,      :string],
    IsamsField["NationalCurriculumYear", :nc_year,    :data,      :integer],
    IsamsField["PeriodId",               :period_id,  :data,      :integer],
    IsamsField["RoomId",                 :room_id,    :data,      :integer],
    IsamsField["TeacherId",              :teacher_id, :data,      :string]
  ]

  include Creator

  def initialize(entry)
    @nc_years = Array.new
    @isams_ids = Array.new
  end

  def adjust
    @nc_years << @nc_year
    @isams_ids << @isams_id
  end

  def merge(other)
    @nc_years << other.nc_year
    @isams_ids << other.isams_id
  end

  def find_resources(loader)
    @groups = @nc_years.collect do |ncy|
      ISAMS_DummyGroup.group_for_nc_year(ncy)
    end
    @staff = []
    @rooms = Array.new
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
    #
    #  Although numeric, return as a string.
    #
    "Year commitment #{@isams_ids.sort.join(",")}"
  end

  def body_text
    @name
  end

  def hash_key
    "#{@name} period #{@period_id} location #{@room_id}"
  end

  def eventcategory
    #
    #  This needs fixing very quickly.  Could be Chapel, Assembly or
    #  something else.
    #
    if @name == "Chapel"
      Eventcategory.find_by(name: "Religious service")
    elsif @name == "Assembly"
      Eventcategory.find_by(name: "Assembly")
    elsif /Core Sport/ =~ @name
      Eventcategory.find_by(name: "Sport")
    else
      Eventcategory.find_by(name: "Activity")
    end
  end

  #
  #  What year group (in Scheduler's terms) are involved in this event.
  #  Return 0 if we don't know, or have a mixture.
  #
  def yeargroup(loader)
    @nc_year - 6
  end

  def self.construct(loader, inner_data)
    events = self.slurp(inner_data)
    event_hash = Hash.new
    events.each do |event|
      existing = event_hash[event.hash_key]
      if existing
        existing.merge(event)
      else
        event_hash[event.hash_key] = event
      end
    end
    event_hash.values
  end

end

class MIS_Schedule

  attr_reader :week_hash, :weeks, :entries

  def initialize(loader, isams_data, timetable)
    @weeks = ISAMS_Week.construct(loader, isams_data)
    if false
      puts "Found #{@weeks.size} weeks."
      @weeks.each do |week|
        puts "#{week.name}"
        week.days.each do |day|
          puts "  #{day.name} - periods #{day.periods.collect {|p| p.short_name}.join(",")}"
        end
      end
    end
    #
    #  Now need a hash so we can look up periods by their ids.
    #  And another to look up weeks.
    #
    @period_hash = Hash.new
    @week_hash = Hash.new
    @weeks.each do |week|
      @week_hash[week.isams_id] = week
      week.days.each do |day|
        day.periods.each do |period|
          @period_hash[period.isams_id] = period
        end
      end
    end
    lessons = ISAMS_ScheduleEntry.construct(loader, timetable.entry)
    #
    #  Now get the meetings.
    #
    meetings = ISAMS_MeetingEntry.construct(loader, timetable.entry)
    #
    #  And full year events.
    #
    year_events = ISAMS_YeargroupEntry.construct(loader, timetable.entry)
    #
    #  And OH events.
    #
    oh_events = ISAMS_OtherHalfEntry.construct(isams_data)
    #
    @entries = lessons + meetings + year_events
    #
    #  Now each timetable entry needs linking to the relevant day
    #  so that we given a date subsequently, we can work out what day
    #  it is and then return all the relevant lessons.
    #
    @entries.each do |entry|
      period = @period_hash[entry.period_id]
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
    oh_events.each do |entry|
      entry.find_resources(loader)
    end
  end

  def entry_count
    @entries.count
  end

end

class ISAMS_WeekAllocation
  SELECTOR = "TimetableManager TimetableAllocations TimetableAllocation"
  REQUIRED_FIELDS = [
    IsamsField["Id",              :isams_id,         :attribute, :integer],
    IsamsField["Week",            :week,             :data,      :integer],
    IsamsField["Year",            :year,             :data,      :integer],
    IsamsField["TimetableWeekId", :timetableweek_id, :data,      :integer]
  ]

  include Creator

  def initialize(entry)
  end

  def self.construct(isams_data)
    self.slurp(isams_data.xml)
  end

end

#
#  We may well find several iSAMS timetables, one of which will be the
#  one we use to build our MIS_Timetable.
#
class ISAMS_Timetable
  REQUIRED_FIELDS = [
    IsamsField["Id",     :isams_id,  :attribute, :integer],
    IsamsField["Name",   :name,      :data,      :string]
  ]

  include Creator

  def initialize(entry)
  end

  def self.construct(isams_data)
    self.slurp(isams_data.xml, false)
  end

end

class ISAMS_DevelopmentTimetable < ISAMS_Timetable
  SELECTOR = "TimetableManager DevelopmentTimetables Timetable"
end

class ISAMS_PublishedTimetable < ISAMS_Timetable
  SELECTOR = "TimetableManager PublishedTimetables Timetable"
end

class MIS_Timetable

  def initialize(loader, isams_data)
    @week_allocations = ISAMS_WeekAllocation.construct(isams_data)
    @week_allocations_hash = Hash.new
    @week_allocations.each do |wa|
      @week_allocations_hash["#{wa.year}/#{wa.week}"] = wa
    end
#    puts "Got #{@week_allocations.size} week allocations."
    if loader.options.timetable_name
#      puts "Timetable called \"#{loader.options.timetable_name}\" specified."
      timetable_name = loader.options.timetable_name
    else
#      puts "No timetable specified."
      entries = isams_data.xml.css("TimetableManager PublishedTimetables Timetable Name")
      if entries && entries.size > 0
        timetable_name = entries[0].text
#        puts "Using #{timetable_name}."
      else
        raise "No published timetable in iSAMS data. Specify one explicitly by name."
      end
    end
    #
    #  Now we are responsible for finding the right timetable and passing
    #  it to the scheduler loader.
    #
    timetables = ISAMS_PublishedTimetable.construct(isams_data) +
                 ISAMS_DevelopmentTimetable.construct(isams_data)
#    puts "Found #{timetables.size} timetables."
#    timetables.each do |t|
#      puts t.name
#    end
    matching_timetables = timetables.select {|t| t.name == timetable_name}
    if matching_timetables.size == 1
      @schedule = MIS_Schedule.new(loader, isams_data, matching_timetables[0])
    else
      raise "#{matching_timetables.size} timetables match \"timetable_name\"."
    end
#    puts "Got #{@schedule.entry_count} schedule entries."
  end

  def entry_count
    @schedule.entry_count
  end

  def lessons_on(date)
#    puts "Asked for lessons on #{date.to_s}"
#    puts "Using hash #{date.year}/#{date.loony_isams_cweek}"
    week_allocation = @week_allocations_hash["#{date.year}/#{date.loony_isams_cweek}"]
    if week_allocation
#      puts "Found week_allocation with year #{week_allocation.year}, week #{week_allocation.week}"
      week = @schedule.week_hash[week_allocation.timetableweek_id]
      if week
#        puts "Week: #{week.name}"
        day = week.day_hash[date.strftime("%a")]
        if day
          lessons = day.lessons
        else
#          puts "Unable to find day for #{date.to_s}"
#          puts "date.strftime(\"%a\") = #{date.strftime("%a")}"
#          puts "Hash contains:"
#          week.day_hash.each do |key, record|
#            puts "  #{key} (#{key.class})"
#          end
          lessons = nil
        end
      else
#        puts "Unable to find week for #{date.to_s}"
        lessons = nil
      end
    else
#      puts "Unable to find week allocation for #{date.to_s}."
      lessons = nil
    end
    oh = ISAMS_OtherHalfEntry.events_on(date)
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


