require 'csv'

#
#  This isn't an ActiveRecord and doesn't exist in the database.  They
#  are constructed in memory when required, and then used.
#
class Day

  class EventDetails

    attr_reader :csv_text, :table_text

    def initialize(event, day)
      @locations_string =
        event.locations.collect {|l| l.friendly_name}.join(", ")
      if event.all_day
        #
        #  If:
        #
        #    We have been asked to add a duration, and
        #    This event last more than one day, and
        #    This event extends beyond the end of the current day
        #
        if day.add_duration &&
           (event.ends_at > event.starts_at + 1.day) &&
           (event.ends_at > day.ends_at) &&
           event.compactable?
          @table_text =
            "#{event.tidied_body(false)} (to #{event.short_end_date_str})."
        elsif day.mark_end &&
              (event.ends_at > event.starts_at + 1.day) &&
              (event.ends_at == day.ends_at) &&
              event.compactable?
          @table_text =
            "#{event.tidied_body(false)} - ends."
        else
          @table_text = event.tidied_body(true)
        end
        @csv_text = @table_text
        @duration_string = ""
      else
        @table_text =
          "#{
              event.duration_string(day.clock_format,
                                    day.end_times)
            } #{event.tidied_body(true)}"
        @csv_text = event.tidied_body(true)
        @duration_string = event.duration_string(day.clock_format,
                                                 day.end_times)
      end
      if day.add_locations && !@locations_string.empty?
        @table_text =
          @table_text.chomp(".") + " - " + @locations_string + "."
      end
    end

    def to_csv
      [@duration_string,
       @csv_text,
       @locations_string].to_csv
    end

  end

  attr_reader :date,
              :all_day_events,
              :timed_events,
              :starts_at,
              :ends_at,
              :add_duration,
              :mark_end,
              :add_locations,
              :clock_format,
              :end_times

  def initialize(date,
                 add_duration,
                 mark_end,
                 add_locations,
                 clock_format,
                 end_times)
    @date = date
    @starts_at = Time.zone.parse(date.strftime("%Y-%m-%d"))
    @ends_at   = Time.zone.parse((date + 1.day).strftime("%Y-%m-%d"))
    @add_duration  = add_duration
    @mark_end      = mark_end
    @add_locations = add_locations
    @clock_format  = clock_format
    @end_times     = end_times
    @all_day_events = []
    @timed_events   = []
  end

  def <<(event)
    if event.all_day
      @all_day_events << EventDetails.new(event, self)
    else
      @timed_events << EventDetails.new(event, self)
    end
  end

  def to_partial_path
    "day"
  end

  def date_text
    self.date.strftime("%a #{self.date.day.ordinalize} %b")
  end

  def events_text_for_table
    (self.all_day_events.collect { |e| e.table_text } +
     self.timed_events.collect { |e| e.table_text }).join(" ")
  end

  def to_csv
    result = ["#{self.date.strftime("%A #{self.date.day.ordinalize} %B, %Y")}"].to_csv
    self.all_day_events.each do |e|
      result += e.to_csv
    end
    self.timed_events.each do |e|
      result += e.to_csv
    end
    result
  end

end
