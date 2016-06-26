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
    self.slurp(isams_data)
  end

end

class MIS_ScheduleEntry
  SELECTOR = "TimetableManager PublishedTimetables Timetable Schedules Schedule"
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
  end

  def source_id
    @isams_id
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
    "#{@isams_id}"
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

  def lower_school
    false
  end

  def suspended_on?(date)
    false
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data)
  end

end

class MIS_Schedule

  attr_reader :week_hash

  def initialize(loader, isams_data)
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
    @entries = MIS_ScheduleEntry.construct(loader, isams_data)
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
        puts "Lesson #{entry.code} references period #{entry.period_id} which doesn't seem to exist."
      end
    end
    @entries.each do |entry|
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
    self.slurp(isams_data)
  end

end

class MIS_Timetable

  def initialize(loader, isams_data)
    @week_allocations = ISAMS_WeekAllocation.construct(isams_data)
    @week_allocations_hash = Hash.new
    @week_allocations.each do |wa|
      @week_allocations_hash["#{wa.year}/#{wa.week}"] = wa
    end
    puts "Got #{@week_allocations.size} week allocations."
    @schedule = MIS_Schedule.new(loader, isams_data)
  end

  def entry_count
    @schedule.entry_count
  end

  def lessons_on(date)
    puts "Asked for lessons on #{date.to_s}"
    puts "Using hash #{date.year}/#{date.loony_isams_cweek}"
    week_allocation = @week_allocations_hash["#{date.year}/#{date.loony_isams_cweek}"]
    if week_allocation
      puts "Found week_allocation with year #{week_allocation.year}, week #{week_allocation.week}"
      week = @schedule.week_hash[week_allocation.timetableweek_id]
      if week
        puts "Week: #{week.name}"
        day = week.day_hash[date.strftime("%a")]
        if day
          day.lessons
        else
          puts "Unable to find day for #{date.to_s}"
          puts "date.strftime(\"%a\") = #{date.strftime("%a")}"
          puts "Hash contains:"
          week.day_hash.each do |key, record|
            puts "  #{key} (#{key.class})"
          end
          nil
        end
      else
        puts "Unable to find week for #{date.to_s}"
        nil
      end
    else
      puts "Unable to find week allocation for #{date.to_s}."
      nil
    end
  end
end


