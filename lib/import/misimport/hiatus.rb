#
#  A class to store information about gaps in lessons.  These can be
#  occasions when lessons are suspended for a particular year group
#  (e.g. for study leave or exams) or chunks of the year when nothing
#  is to happen at all (e.g. for athletics or the road relay).
#
#  It can be sub-classed to store information about suspensions
#  coming from the MIS.
#
#  times_by_day specifies whether the hiatus is linear or rectangular.
#
#  if times_by_day is true, then we have a rectangular hiatus (like
#  rectangular selections in a text editor).  It runs for several
#  days and suspends all lessons between those times on those days.
#  E.g. suspending between 09:00 and 12:00 on Mon, Tue, Wed.
#
#  If times_by_day is false then we have a simple interval.  Lessons
#  are suspended from, say, 09:00 on Monday to 12:00 on Wednesday.
#  That includes all lessons on Monday and Tuesday afternoon.
#
#  It's not easy to store a time without a corresponding date, so we
#  just store the times as minutes since midnight.
#
class Hiatus

  def initialize(hard_or_soft, times_by_day)
    @hard_or_soft = hard_or_soft   # :hard or :soft
    @times_by_day = times_by_day   # true or false
    @yeargroups = Array.new
    #
    #  For hiatuses specified with times_by_day = true
    #
    @start_date = nil
    @end_date   = nil
    @start_mins = nil
    @end_mins   = nil
    #
    #  For hiatuses specified with times_by_day = false
    #
    @starts_at = nil
    @ends_at   = nil
  end

  def note_dates_and_times(start_date, end_date, start_mins, end_mins)
    @start_date = start_date
    @end_date   = end_date
    @start_mins = start_mins
    @end_mins   = end_mins
  end

  def note_start_and_end(starts_at, ends_at)
    @starts_at = starts_at
    @ends_at   = ends_at
  end

  def note_yeargroup(year)
    @yeargroups << year
  end

  def complete?
    if @times_by_day
      !(@start_date == nil ||
        @end_date == nil ||
        @start_mins == nil ||
        @end_mins == nil)
    else
      !(@starts_at = nil || @ends_at == nil)
    end
  end

  def hard?
    @hard_or_soft == :hard
  end

  def soft?
    @hard_or_soft == :soft
  end

  #
  #  Does this hiatus apply for an indicated lesson time?
  #
  def applies_to_lesson?(date, period_time)
    if @times_by_day
      #
      #  First the dates have to match, then the times.  If we overlap
      #  the indicated period then we match.
      #
      date >= @start_date &&
      date <= @end_date &&
      period_time.start_mins < @end_mins &&
      period_time.end_mins > @start_mins
    else
      given_starts_at = Time.zone.parse("#{date.to_s} #{period_time.starts_at}")
      given_ends_at   = Time.zone.parse("#{date.to_s} #{period_time.ends_at}")
      given_starts_at < @ends_at && given_ends_at > @starts_at
    end
  end

  #
  #  Does this hiatus apply to the indicated year group.  This will be true
  #  if either:
  #
  #    a) The year is in our list
  #    b) Our list is empty
  #
  #  As a further case, if the year_ident we're given is 0, indicating that
  #  the lesson has a mixture of year groups in it, then we apply provided
  #  our list is empty.  This actually happens without any special code,
  #  but it is intentional.
  #
  #  Note that the years here are Scheduler's internal years, which in
  #  turn are whatever the client chooses to use.  In Abingdon's case
  #  these are 1,2,3,4,5,6,7 which correspond to NC 7,8,9,10,11,12,13.
  #
  def applies_to_year?(year)
    @yeargroups.empty? || @yeargroups.include?(year)
  end

  def effective_end_date
    if @times_by_day
      @end_date
    else
      @ends_at.to_date
    end
  end

  #
  #  For filtering out suspensions which are just plain old.
  #
  def occurs_after?(date)
    self.complete? &&
    self.effective_end_date >= date
  end

  def self.create_from_event(hard_or_soft, event)
    hiatus = Hiatus.new(hard_or_soft, false)
    hiatus.note_start_and_end(event.starts_at,
                              event.ends_at)
    #
    #  Need a list of the year groups involved in this event.
    #
    event.pupil_year_groups(true).each do |year|
      hiatus.note_yeargroup(year)
    end
    hiatus
  end

  #
  #  Find any gaps currently configured in the database.
  #
  KNOWN_HIATUS_TYPES = {
    "Gap"        => :hard,
    "Suspension" => :soft
  }
  def self.load_hiatuses(loader)
    hiatuses = Array.new
    KNOWN_HIATUS_TYPES.each do |key, hs|
      property = Property.find_by(name: key)
      if property
        puts "Found property: #{key}"
        property.element.events_on(loader.start_date,
                                   loader.era.ends_on).each do |event|
          puts "Processing a #{key}"
          hiatuses << Hiatus.create_from_event(hs, event)
        end
      else
        puts "Unable to find property: #{key}."
      end
    end
    hiatuses
  end

end
