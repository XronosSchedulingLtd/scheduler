# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'tod'

class TimetableContents

  class TimetableDay

    class Period

      attr_reader :start_time_tod,
                  :end_time_tod,
                  :body_text,
                  :prep_text

      def initialize(item)
        if item.instance_of?(Event)
          @body_text = item.body
          @filled    = true
          @start_time_tod = Tod::TimeOfDay(item.starts_at)
          @end_time_tod   = Tod::TimeOfDay(item.ends_at)
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
        @filled
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

    attr_reader :periods

    def initialize(parent)
      @periods = Array.new
      @parent = parent
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

  attr_reader :commitments, :days

  def initialize(element, date, background_periods = nil)
    date ||= Date.today
    @days = Array.new
    #
    #  Need some way of specifying the length of a timetable cycle.
    #
    @timings = Hash.new
    14.times do
      @days << TimetableDay.new(self)
    end
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
    startdate = Date.parse("2017-09-17")
    enddate =   Date.parse("2017-09-30")

    @commitments =
      Commitment.commitments_on(
        startdate:     startdate,
        enddate:       enddate,
        eventcategory: ["Lesson", "Other Half"],
        resource:      together).includes(:event).to_a
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
  end

  def to_partial_path
    "timetable_contents"
  end

  def note_period(period)
    @timings[period.timing_class] ||= Timing.new(period)
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
    contents.join("\n")
  end
end
