#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class RotaEditor

  class RE_Event

    def initialize(starts_at, ends_at, background = false)
      @starts_at = starts_at
      @ends_at = ends_at
      @background = background
      #
      #  The ID has to be numeric to suit Rails, but also needs to
      #  be unique enough for us to identify which event we're talking
      #  about.  The slot_id is no use because it may represent more
      #  than one event.
      #
      #  We generate a 9 digit number (always 9 digits) as follows:
      #
      #  1 digit - day number in week.  To avoid issues with a leading
      #  zero we use the alternative value of 7 for Sunday.
      #  4 digits - start time
      #  4 digits - end time
      #
      day_no = @starts_at.wday
      if day_no == 0
        day_no = 7
      end
      @id = "#{day_no}#{@starts_at.to_s(:hm)}#{@ends_at.to_s(:hm)}"
    end

    def as_json(options = {})
      result = {
        start:    @starts_at.iso8601,
        end:      @ends_at.iso8601,
        editable: true
      }
      if @background
        result[:rendering] = 'background'
      else
        result[:id] = @id
      end
      result
    end

    def self.split_id(id)
      #
      #  Split an id up into a day number (0 - 6) and a start and
      #  end time (both Tod::TimeOfDays).
      #
      day_no = id[0].to_i
      if day_no == 7
        day_no = 0
      end
      start_tod = Tod::TimeOfDay.parse("#{id[1,2]}:#{id[3,2]}")
      end_tod = Tod::TimeOfDay.parse("#{id[5,2]}:#{id[7,2]}")
      return day_no, start_tod, end_tod
    end

  end

  def initialize(rota, template = nil)
    @rota     = rota        # The rota we are editing
    @template = template    # Another rota which we use as a template
  end

  #
  #  Provide a set of events suitable for sending back to the
  #  front end for display by FullCalendar.
  #
  def events
    #
    #  For this we use some fixed dates.  1st Jan 2017 was a Sunday.
    #
    start_date = Date.parse("2017-01-01")
    end_date = start_date + 6.days
    #
    result = []
    #
    #  First set up all the slots from the template as background events.
    #
    if @template
      start_date.upto(end_date) do |date|
        @template.slots_for(date) do |slot|
          starts_at, ends_at = slot.timings_for(date)
          result << RE_Event.new(starts_at, ends_at, true)
        end
      end
    end
    #
    #  Now add all the real events from the rota itself.
    #
    start_date.upto(end_date) do |date|
      @rota.slots_for(date) do |slot|
        starts_at, ends_at = slot.timings_for(date)
        result << RE_Event.new(starts_at, ends_at)
      end
    end
    result
  end

  def add_event(params)
    #
    #  params is what we got from the browser.  Should contain.
    #
    #  day_no:   Integer
    #  starts_at:  "HH:MM"
    #  ends_at:    "HH:MM"
    #
    #  Ends_at is optional
    #
    day_no = params[:day_no]
    if params[:ends_at]
      #
      #  We've been given both times, so just use them.
      #
      starting = Tod::TimeOfDay.parse(params[:starts_at])
      ending = Tod::TimeOfDay.parse(params[:ends_at])
    else
      #
      #  Just got the one, so see whether we can jump to a slot.
      #  If not, default to a one hour event.
      #
      starting = Tod::TimeOfDay.parse(params[:starts_at])
      slot = @template.covering_slot(day_no, starting)
      if slot
        starting = slot.starts_at_tod
        ending   = slot.ends_at_tod
      else
        ending = starting + 3600
      end
    end
    @rota.add_slot(day_no, starting, ending)
  end

  def adjust_event(id, params)
    day_no, start_tod, end_tod = RE_Event.split_id(id)
    @rota.adjust_slot(day_no, start_tod, end_tod, params)
  end

  def delete_event(id)
    #
    #  This should be a 9 digit numeric string, which we split up.
    #
    day_no, start_tod, end_tod = RE_Event.split_id(id)
    @rota.remove_slot(day_no, start_tod, end_tod)
  end

end

