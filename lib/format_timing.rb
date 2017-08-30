# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


def format_timings(starts_at, ends_at, all_day)
  if all_day
    #
    #  Single day or multi-day?
    #
    if ends_at == starts_at + 1.day
      "All day #{starts_at.strftime("%d/%m/%Y")}"
    else
      "#{starts_at.to_s(:dmy)} - #{(ends_at - 1.day).to_s(:dmy)}"
    end
  else
    if starts_at.to_date == ends_at.to_date
      #
      #  Starts and ends on the same day.
      #
      "#{starts_at.interval_str(ends_at)} #{starts_at.to_s(:dmy)}"
    else
      "#{starts_at.to_s(:hmdmy)} - #{ends_at.to_s(:hmdmy)}"
    end
  end
end


