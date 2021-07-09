# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  Provide a service of identifying the week letter (if any) for
#  a given date.  Cache information in order to avoid hitting the
#  database every single time the question is asked.
#
class WeekIdentifier

  attr_reader :dates

  def initialize(start_on = Date.today, end_on = Setting.current_era.ends_on)
    event_category = Eventcategory.cached_category("Week letter")
    @dates = Hash.new(" ")
    #
    #  Beware of the need to specify an *exclusive* end date to
    #  the "until" scope.  What we have is an exclusive date, so add
    #  1 to it.
    #
    event_category.events.
                   beginning(start_on).
                   until(end_on + 1.day).each do |event|
      start_date = event.starts_at.to_date
      end_date   = event.ends_at.midnight? ?
                   event.ends_at.to_date - 1.day :
                   event.ends_at.to_date
      letter = event.body[-1].upcase
      start_date.upto(end_date) do |date|
        @dates[date] = letter
      end
    end
  end

  def week_letter(date)
    @dates[date]
  end

  #
  #  You can also have a one-off query if you want, which is less
  #  efficient, but if you need only the one then go ahead.
  #
  def self.week_letter(date)
    self.new(date, date).week_letter(date)
  end
end
