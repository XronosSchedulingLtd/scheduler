# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'tod'

module Timetable

  #
  #  A class for a single period within the timetable.
  #
  class Period

    attr_reader :start_time_tod,
                :end_time_tod,
                :body_text,
                :prep_text,
                :has_prep

    def initialize(item)
      @has_prep = false
      @background_slot = false
      if item.instance_of?(Event)
        prep_suffix = Setting.prep_suffix
        unless prep_suffix.blank?
          #
          #  Get rid of prep suffix if it is there.
          #
          regex = / #{Regexp.escape(prep_suffix)}\z/
          @body_text = item.body
          if @body_text =~ regex
            @body_text = @body_text.sub(regex, '')
            @has_prep = true
          end
        end
        @filled    = true
        @start_time_tod = Tod::TimeOfDay(item.starts_at)
        @end_time_tod   = Tod::TimeOfDay(item.ends_at)
        if duration > 35
          if staff_initials = item.staff_initials
            @body_text += "<br/>#{staff_initials}"
          end
          if duration > 45
            @body_text += "<br/>#{item.short_location_name}"
          end
        elsif duration < 30
          #
          #  Maximum of 12 characters.
          #
          @body_text = @body_text[0,12]
        end
        @body_text = body_text.html_safe
      elsif item.instance_of?(RotaSlot)
        @background_slot = true
        @body_text = nil
        @filled    = false
        @start_time_tod = item.starts_at_tod
        @end_time_tod   = item.ends_at_tod
      else
        raise "Invalid item type to create timetable period - #{item.class}"
      end
    end

    #
    #  Start time and end time as 5 character strings.
    #
    def start_time
      @start_time_tod.strftime("%H:%M")
    end

    def end_time
      @end_time_tod.strftime("%H:%M")
    end

    def show_times?
      @filled && duration >= 20
    end

    def identical_times?(other)
      @start_time_tod == other.start_time_tod &&
        @end_time_tod == other.end_time_tod
    end

    def background_slot?
      @background_slot
    end

    #
    #  Duration in minutes
    #
    def duration
      Tod::Shift.new(@start_time_tod, @end_time_tod).duration / 60
    end

    def to_partial_path
      "period"
    end

    def timing_class
      "h#{start_time.tr(':', '')}d#{duration}"
    end

    def periodtext_class
      if duration > 30
        "periodtext"
      elsif duration < 20
        "periodtextreallysmall"
      else
        "periodtextsmall"
      end
    end

    def end_time_class
      "endtime#{duration}"
    end

    def preptext_class
      "preptext#{duration}"
    end

    def css_classes
      contents = Array.new
      contents << "period"
      #
      #  Now want to add something giving the start time and duration.
      #  of the form "h1015d55".  That one would mean it starts at 1015
      #  and runs for 55 minutes.  This is used to achieve vertical
      #  positioning and height.
      #
      contents << timing_class
      if @filled
        contents << "filled"
      else
        contents << "empty"
      end
      contents.join(" ")
    end

  end

  #
  #  A class for a whole day within the timetable.
  #
  class Day

    attr_reader :periods, :day_name

    def initialize(parent, day_no)
      @periods = Array.new
      @parent = parent
      @day_no = day_no
      @day_name = Date::ABBR_DAYNAMES[day_no]
    end

    def clashes?(period)
      !!@periods.detect {|p| p.identical_times?(period) && !p.background_slot?}
    end

    def <<(item)
      period = Period.new(item)
      @parent.note_period(period)
      #
      #  Don't put in two periods with precisely the same timing.
      #  This shouldn't happen, but it does and then the timetable
      #  looks a mess.
      #
      unless clashes?(period)
        @periods << period
      end
    end

    def to_partial_path
      "timetable_day"
    end

    def active?
      Setting.timetable_day?(@day_no)
    end

  end

  class WeekGap

    def to_partial_path
      "week_gap"
    end

  end

  #
  #  A class to store basic timing information and generate CSS classes
  #  to match.
  #
  class Timing

    @@midnight = Tod::TimeOfDay(0)

    def initialize(period)
      @start_mins =
        Tod::Shift.new(@@midnight, period.start_time_tod).duration / 60
      @duration   = period.duration
    end

    #
    #  We use a fixed positioning system of 6px per 5 minutes, with
    #  offsets calculated from a start time of 08:30 (510 mins after
    #  midnight).
    #
    def top
      "#{((@start_mins - 510) / 5) * 6}px"
    end

    def height
      "#{((@duration / 5) * 6)}px"
    end

  end

  #
  #  An object which does the actual work of assembling a set of an
  #  elements events for a timetable.
  #
  class EventAssembler
    attr_reader :startdate

    def initialize(element, date = Date.today, preload_all = false)
      #
      #  Need all the events for this element (including via groups
      #  as on the indicated date) from the configured timetable
      #  interval.
      #
      effective_groups = element.groups(date)
      #
      #  Note that effective_groups is a selector of groups (not their
      #  elements) and element is an element.  Happily the commitment
      #  finding code can handle an array containing a mixture.
      #
      together = [element] + effective_groups.includes(:element).to_a
      #
      #  Dates come from the system settings.
      #
      @startdate = Setting.tt_store_start
      enddate   = @startdate + Setting.tt_cycle_weeks.weeks - 1.day
      eventcategories = Eventcategory.timetable.to_a
      if eventcategories.empty?
        @commitments = []
      else
        #
        #  What we get here is not yet an array but a constructed
        #  database query.  It gets executed only when the events()
        #  method is called.
        #
        if preload_all
          @commitments =
            Commitment.commitments_on(
              startdate:     @startdate,
              enddate:       enddate,
              eventcategory: eventcategories,
              resource:      together).includes(event: {commitments: :element})
        else
          @commitments =
            Commitment.commitments_on(
              startdate:     @startdate,
              enddate:       enddate,
              eventcategory: eventcategories,
              resource:      together).includes(:event)
        end
      end
    end

    def events
      @events ||= @commitments.collect(&:event)
    end

    def events_by_day
      #
      #  Expect a block to be passed, to which we will yield all the
      #  events in chronological order, specifying for each the week
      #  and day number.
      #
      #  A, 1, event
      #  A, 1, event
      #  A, 1, event
      #  A, 2, event
      #  ...
      #  B, 1, event
      #  etc.
      #
      self.events.sort.each do |event|
        offset = (event.starts_at.to_date - @startdate).to_i
        if offset < 7
          week_letter = 'A'
        else
          week_letter = 'B'
        end
        day_no = offset % 7
        yield week_letter, day_no, event
      end
    end
  end

  #
  #  A class to hold the whole of one element's timetable.
  #
  class Contents

    attr_reader :days, :weeks, :week_headers, :element_name, :timings, :durations, :preps

    def initialize(element, date, background_periods = nil)
      @element_name = element.name
      @days = Array.new
      #
      #  Need some way of specifying the length of a timetable cycle.
      #
      @timings = Hash.new
      @durations = Hash.new
      @preps = Hash.new
      @weeks = Setting.tt_cycle_weeks
      if @weeks == 2
        num_days = 14
      else
        num_days = 7
      end
      num_days.times do |index|
        @days << Day.new(self, index % 7)
      end
      @week_headers = ["Week A", "Week B"]
      #
      #  Do we have a set of background periods specified?
      #
      if background_periods
        #
        #  background_periods should be a Rota Template, which itself
        #  refers to a lot of Rota Slots.
        #
        background_periods.rota_slots.each do |rs|
          #
          #  Again, we need to make the shape of the timetable configurable.
          #
          rs.periods do |index, starts_at, ends_at|
            @days[index] << rs
            if @weeks == 2
              @days[index + 7] << rs
            end
          end
        end
      end
      ea = EventAssembler.new(element, date)
      events = ea.events.sort
      #
      #  Now sort them into days.
      #
      events.each do |event|
        offset = (event.starts_at.to_date - ea.startdate).to_i
        if offset >= 0 && offset < 14
          @days[offset] << event
        end
      end
      @days.insert(7, WeekGap.new)
    end

    def to_partial_path
      "timetable_contents"
    end

    def note_period(period)
      @timings[period.timing_class] ||= Timing.new(period)
      @durations[period.duration] ||= true
      if period.has_prep
        @preps[period.duration] ||= true
      end
    end

    def periods_css
      self.class.periods_css(@timings, @durations, @preps)
    end

    #
    #  Generate chunk of CSS for embedding in the page which will position
    #  the periods correctly.
    #
    def self.text_at_bottom(duration)
      "#{((duration - 15) / 5) * 6}px;"
    end

    def self.week_width
      ((Setting.last_tt_day - Setting.first_tt_day) + 1) * 95
    end

    def self.timetable_width
      weeks = Setting.tt_cycle_weeks
      #
      #  We currently cope with only 1 or 2 weeks.
      #
      if weeks == 1
        week_width
      else
        (week_width * 2) + 20
      end
    end

    def self.periods_css(timings, durations, preps)
      contents = []
      timings.each do |key, timing|
        contents << ".period.#{key} {"
        contents << "  position: absolute;"
        contents << "  top: #{timing.top};"
        contents << "  height: #{timing.height};"
        contents << "}"
      end
      durations.each do |duration, flag|
        #
        #  Periods shorter than 20 minutes don't have room for timings.
        #
        if duration >= 20
          contents << ".period .endtime#{duration} {"
          contents << "  position: absolute;"
          contents << "  font-size: 0.8em;"
          contents << "  left: 55px;"
          if duration <= 30
            contents << "  top: -4px;"
          else
            contents << "  top: #{text_at_bottom(duration)}"
          end
          contents << "}"
        end
      end
      preps.each do |duration, flag|
        contents << ".period .preptext#{duration} {"
        contents << "  position: absolute;"
        contents << "  top: #{text_at_bottom(duration)}"
        contents << "  left: 2px;"
        contents << "  font-weight: bold;"
        contents << "}"
      end
      #
      #  Calculate the full width of the timetable.
      #
      contents << ".timetable {"
      contents << "  width: #{timetable_width}px;"
      contents << "}"
      #
      #  And something to allow us to put week headings over each
      #  week.
      #
      contents << ".timetable .timetable-week {"
      contents << "  width: #{week_width}px;"
      contents << "}"
      contents.join("\n")
    end
  end

  #
  #  This class works just like an array, except it can generate CSS
  #  to suit the whole set of timetables.  Anything else put in it will
  #  be ignored.
  #
  class Collection < Array

    def periods_css
      #
      #  Merge the relevant items from each individual timetable.
      #
      timings = Hash.new
      durations = Hash.new
      preps = Hash.new
      self.each do |timetable|
        if timetable.instance_of? Timetable::Contents
          timings.merge!(timetable.timings)
          durations.merge!(timetable.durations)
          preps.merge!(timetable.preps)
        end
      end
      Timetable::Contents.periods_css(timings, durations, preps)
    end

  end

end
