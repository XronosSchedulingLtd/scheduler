#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  Group hiatuses to enable them to be merged.
#
#  Rectangular hiatuses cannot be merged.
#
#  Hiatuses with no year groups (thus affecting all lessons)
#  should not be merged.
#
#  It's the responsibility of the caller to make sure they're
#  all the same type (hard or soft).
#
class HiatusGrouping

  def initialize(hiatus)
    if hiatus.times_by_day
      raise "Can't group rectangular hiatuses at present"
    end
    @hiatuses  = [hiatus]
    #
    #  Hiatuses with no year groups form a group on their own.
    #
    @singular  = hiatus.yeargroups.size == 0
    @starts_at = hiatus.starts_at
    @ends_at   = hiatus.ends_at
  end

  def belongs?(hiatus)
    !@singular &&
     hiatus.yeargroups.size > 0 &&
     hiatus.starts_at < @ends_at &&
     hiatus.ends_at > @starts_at
  end

  def add(hiatus)
    if hiatus.times_by_day
      raise "Can't group rectangular hiatuses at present"
    end
    @hiatuses << hiatus
    if hiatus.starts_at < @starts_at
      @starts_at = hiatus.starts_at
    end
    if hiatus.ends_at > @ends_at
      @ends_at = hiatus.ends_at
    end
  end

  #
  #  Having finished assembling this grouping, generate a fresh lot
  #  of hiatuses representing the merged set.
  #
  def regroup
    if @hiatuses.size == 1
      return @hiatuses
    else
      #
      #  First need a list of all the start and end times.
      #
      hard_or_soft = @hiatuses[0].hard_or_soft
      boundaries = Array.new
      @hiatuses.each do |hiatus|
        boundaries << hiatus.starts_at
        boundaries << hiatus.ends_at
      end
      sorted = boundaries.uniq.sort
      #
      #  We now have N datetimes in order.  We will generate
      #  N-1 new hiatuses, each consisting of a merging of
      #  all the hiatuses current in its duration.
      #
      merged_hiatuses = Array.new
      sorted.each_cons(2).each do |pair|
        hiatus = Hiatus.new(hard_or_soft, false).
                        note_start_and_end(pair[0], pair[1])
        #
        #  Now - which yeargroups does it apply to?  Note that each
        #  of our original hiatuses has at least one yeargroup.
        #
        @hiatuses.
          select { |h| h.starts_at < pair[1] && h.ends_at > pair[0] }.
          each do |h|
            h.yeargroups.each { |yg| hiatus.note_yeargroup(yg) }
          end
        merged_hiatuses << hiatus
      end
      return merged_hiatuses
    end
  end

  def dump
    puts "Hiatus grouping"
    puts "  #{@hiatuses.size} original hiatuses."
    @hiatuses.each do |h|
      puts "    #{h.text_details}"
    end
    puts "  Resulting in:"
    self.regroup.each do |h|
      puts "    #{h.text_details}"
    end
  end
end

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

  attr_reader :times_by_day, :starts_at, :ends_at, :yeargroups, :hard_or_soft

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
    self
  end

  def note_start_and_end(starts_at, ends_at)
    @starts_at = starts_at
    @ends_at   = ends_at
    self
  end

  def note_yeargroup(year)
    @yeargroups << year unless @yeargroups.include?(year)
    self
  end

  def list_yeargroups
    @yeargroups.each do |yg|
      puts "  #{yg}"
    end
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

  def <=>(other)
    if other.instance_of?(Hiatus)
      self.starts_at <=> other.starts_at
    else
      nil
    end
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

  def applies_to_years?(years)
    @yeargroups.empty? || (years - @yeargroups).empty?
  end

  def effective_end_date
    if @times_by_day
      @end_date
    else
      @ends_at.to_date
    end
  end

  def text_details
    if @times_by_day
      "Not implemented"
    else
      "Starts: #{@starts_at.to_s(:hmdmy)}, ends: #{@ends_at.to_s(:hmdmy)}, years: #{@yeargroups.sort}"
    end
  end

  #
  #  For filtering out suspensions which are just plain old.
  #
  def occurs_after?(date)
    self.complete? &&
    self.effective_end_date >= date
  end

  def groupable?
    @yeargroups.size > 0
  end

  def self.create_from_event(hard_or_soft, event, era)
    hiatus = Hiatus.new(hard_or_soft, false)
    hiatus.note_start_and_end(event.starts_at,
                              event.ends_at)
    #
    #  Need a list of the year groups involved in this event.
    #
    event.pupil_year_groups(true, era).each do |year|
      hiatus.note_yeargroup(year)
    end
#    puts "Hiatus #{event.body} at #{event.starts_at} applies to:"
#    hiatus.list_yeargroups
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
        original_hiatuses = Array.new
#        puts "Found property: #{key}"
        property.element.events_on(loader.start_date,
                                   loader.era.ends_on).each do |event|
#          puts "Processing a #{key}"
          original_hiatuses << Hiatus.create_from_event(hs, event, loader.era)
        end
        #
        #  Now see about merging them.
        #
        current_grouping = nil
        groupings = Array.new
        original_hiatuses.sort.each do |oh|
          if oh.groupable?
            if current_grouping && current_grouping.belongs?(oh)
              current_grouping.add(oh)
            else
              current_grouping = HiatusGrouping.new(oh)
              groupings << current_grouping
            end
          else
            #
            #  This one passes through without affecting the groups.
            #
#            puts "Ungroupable: #{oh.text_details}"
            hiatuses << oh
          end
        end
        #
        #  And now extract merged hiatuses from the groupings.
        #
        groupings.each do |g|
          hiatuses += g.regroup
#          g.dump
        end
      else
        puts "Unable to find property: #{key}."
      end
    end
    hiatuses
  end

end
