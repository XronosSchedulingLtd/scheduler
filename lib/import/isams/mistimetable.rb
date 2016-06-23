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

  attr_reader :day

  def initialize(entry)
  end

  def self.construct(day, day_data)
    @day = day
    self.slurp(day_data)
  end
end

class ISAMS_Day
  #
  #  Note that this selector assumes we are already looking inside a
  #  week entry.
  #
  SELECTOR = "Days Day"
  REQUIRED_FIELDS = [
    IsamsField["Id",    :isams_id, :attribute, :integer],
    IsamsField["Name",  :name,     :data,      :string]
  ]
  
  include Creator

  attr_reader :week, :periods

  def initialize(entry)
    @periods = ISAMS_Period.construct(self, entry)
  end

  def self.construct(week, week_data)
    @week = week
    self.slurp(week_data)
  end
end

class ISAMS_Week
  SELECTOR = "TimetableManager Structure Week"
  REQUIRED_FIELDS = [
    IsamsField["Id",    :isams_id, :attribute, :integer],
    IsamsField["Name",  :name,     :data,      :string]
  ]

  include Creator

  attr_reader :days

  def initialize(entry)
    @days = ISAMS_Day.construct(self, entry)
  end

  def self.construct(loader, isams_data)
    self.slurp(isams_data)
  end

end

class ISAMS_ScheduleEntry
  SELECTOR = "TimetableManager PublishedTimetables Timetable Schedules Schedule"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id,  :attribute, :integer],
    IsamsField["Code",      :code,      :data,      :string],
    IsamsField["Teacher",   :teacher,   :data,      :string],
    IsamsField["PeriodId",  :period_id, :data,      :integer],
    IsamsField["RoomId",    :room_id,   :data,      :integer],
    IsamsField["SetId",     :set_id,    :data,      :integer]
  ]

  include Creator

  attr_reader :datasource_id

  def initialize(entry)
  end

  def adjust
  end

  def source_id
    @isams_id
  end

  def self.construct(loader, isams_data)
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
    #
    @period_hash = Hash.new
    @weeks.each do |week|
      week.days.each do |day|
        day.periods.each do |period|
          @period_hash[period.isams_id] = period
        end
      end
    end
    self.slurp(isams_data)
  end

end

def MIS_Timetable
  def self.construct(loader, isams_data)
    @schedule_entries = ISAMS_ScheduleEntry.construct(loader, isams_data)
  end
end


