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
          @body_text += "<br/>#{item.staff_initials}"
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
      if duration >= 30
        "periodtext"
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
      @day_name = Date::ABBR_DAYNAMES[day_no]
    end

    def <<(item)
      period = Period.new(item)
      @parent.note_period(period)
      @periods << period
    end

    def to_partial_path
      "timetable_day"
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
  #  A class to hold the whole of one element's timetable.
  #
  class Contents

    attr_reader :days, :weeks, :week_headers, :element_name

    def initialize(element, date, background_periods = nil)
      @element_name = element.name
      date ||= Date.today
      @days = Array.new
      #
      #  Need some way of specifying the length of a timetable cycle.
      #
      @timings = Hash.new
      @durations = Hash.new
      @preps = Hash.new
      14.times do |index|
        @days << Day.new(self, index % 7)
      end
      @week_headers = ["Week A", "Week B"]
      @weeks = Setting.tt_cycle_weeks
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
            @days[index + 7] << rs
          end
        end
      end
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
      #  Dates hard coded for now.
      #
      startdate = Setting.tt_store_start
      enddate =   startdate + Setting.tt_cycle_weeks.weeks - 1.day
      eventcategories = Eventcategory.timetable.to_a
      if eventcategories.empty?
        @commitments = []
      else
        @commitments =
          Commitment.commitments_on(
            startdate:     startdate,
            enddate:       enddate,
            eventcategory: eventcategories,
            resource:      together).includes(:event).to_a
      end
      #puts "Found #{@commitments.size} commitments"
      #
      #  Now sort them into days.
      #
      @commitments.sort.each do |commitment|
        offset = (commitment.event.starts_at.to_date - startdate).to_i
        if offset >= 0 && offset < 14
          @days[offset] << commitment.event
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

    def text_at_bottom(duration)
      "#{((duration - 15) / 5) * 6}px;"
    end

    def week_width
      ((Setting.last_tt_day - Setting.first_tt_day) + 1) * 95
    end

    #
    #  Generate chunk of CSS for embedding in the page which will position
    #  the periods correctly.
    #
    def periods_css
      contents = []
      @timings.each do |key, timing|
        contents << ".period.#{key} {"
        contents << "  position: absolute;"
        contents << "  top: #{timing.top};"
        contents << "  height: #{timing.height};"
        contents << "}"
      end
      @durations.each do |duration, flag|
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
      @preps.each do |duration, flag|
        contents << ".period .preptext#{duration} {"
        contents << "  position: absolute;"
        contents << "  top: #{text_at_bottom(duration)}"
        contents << "  left: 2px;"
        contents << "  font-weight: bold;"
        contents << "}"
      end
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

end
