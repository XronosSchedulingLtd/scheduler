require 'csv'

#
#  This isn't an ActiveRecord and doesn't exist in the database.  They
#  are constructed in memory when required, and then used.
#
class Day

  attr_reader :date, :all_day_events, :timed_events

  def initialize(date, add_duration, mark_end)
    @date = date
    @add_duration = add_duration
    @mark_end     = mark_end
    @all_day_events = []
    @timed_events   = []
  end

  def <<(event)
    if event.all_day
      @all_day_events << event
    else
      @timed_events << event
    end
  end

  def to_partial_path
    "day"
  end

  def date_text
    self.date.strftime("%a #{self.date.day.ordinalize} %b")
  end

  def events_text_for_table
    (self.all_day_events.collect { |e|
      if @add_duration &&
         (e.ends_at > e.starts_at + 1.day) &&
         (e.ends_at > self.date + 1.day)
        "#{e.tidied_body(false)} (to #{e.short_end_date_str})."
      else
        e.tidied_body(true)
      end
     } +
     self.timed_events.collect {
       |e| "#{e.duration_string} #{e.tidied_body(true)}"
     }
    ).join(" ")
  end

  def to_csv
    result = ["#{self.date.strftime("%A #{self.date.day.ordinalize} %B, %Y")}"].to_csv
    self.all_day_events.each do |e|
      result += e.to_csv(@add_duration, self.date)
    end
    self.timed_events.each do |e|
      result += e.to_csv(@add_duration, self.date)
    end
    result
  end

end
