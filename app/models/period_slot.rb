# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  Note that this is not a genuine ActiveRecord model.  It has no
#  corresponding database table.  It exists purely to store information
#  temporarily and then provide it to a view.
#
#
require 'tod'

class PeriodSlot
  attr_reader :day_no, :start_time, :end_time, :start_tod, :end_tod

  def initialize(day_no, start_time, end_time)
    @day_no     = day_no
    @start_time = start_time
    @start_tod  = Tod::TimeOfDay.try_parse(start_time)
    @end_time   = end_time
    @end_tod    = Tod::TimeOfDay.try_parse(end_time)
  end

  def <=>(other)
    #
    #  Sort first by day and then by time.
    #
    if self.day_no == other.day_no
      if self.start_tod == other.start_tod
        if self.end_tod == other.end_tod
          0
        else
          self.end_tod <=> other.end_tod
        end
      else
        self.start_tod <=> other.start_tod
      end
    else
      self.day_no <=> other.day_no
    end
  end

  DAY_NAMES = [
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat"
  ]

  def day_name
    DAY_NAMES[self.day_no] || "Unknown"
  end

  def to_partial_path
    "period_slot"
  end

end
