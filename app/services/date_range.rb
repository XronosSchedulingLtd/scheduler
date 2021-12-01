#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  A DateRange is very much like a TodShift, but for dates rather than
#  times.
#

class DateRange

  attr_reader :start_date, :exclusive_end_date

  def initialize(start_date, exclusive_end_date_or_duration)
    #
    #  We will allow Date, Time, DateTime, TimeWithZone or text.
    #
    @start_date = start_date.to_date
    if exclusive_end_date_or_duration.respond_to?(:to_date)
      @exclusive_end_date = exclusive_end_date_or_duration.to_date
    else
      @exclusive_end_date = @start_date + exclusive_end_date_or_duration
    end
    freeze
  end

  def duration
    (@exclusive_end_date - @start_date).to_int
  end

  def hash
    "#{@start_date}:#{@exclusive_end_date}".hash
  end

  def include?(date)
    #
    #  Allow for the parameter to be of various types.
    #
    as_date = date.to_date
    @start_date <= as_date && as_date < @exclusive_end_date
  end

  #
  #  One starts as the other ends.
  #
  def abuts?(other)
    self.start_date == other.exclusive_end_date ||
      self.exclusive_end_date == other.start_date
  end

  #
  #  Starts or ends at precisely the same time.
  #
  def coterminates?(other)
    self.start_date == other.start_date ||
      self.exclusive_end_date == other.exclusive_end_date
  end

  #
  #  Shares at least one common date.  This may be only an instant,
  #  but must be internal as all Shifts have an exclusive end.  If two
  #  shifts abut, they do not overlap.
  #
  #  The logic here comes from thinking about when they don't overlap.
  #
  #  (a.start >= b.end) || (b.start >= a.end)
  #
  #  Negate that and reduce and we get:
  #
  #  a.start < b.end && b.start < a.end
  #
  def overlaps?(other)
    self.start_date < other.exclusive_end_date &&
      other.start_date < self.exclusive_end_date
  end

  #
  #  Sort of the inverse of overlaps?  They occupy completely distinct
  #  dates, but may just touch.
  #
  def avoids?(other)
    self.start_date >= other.exclusive_end_date ||
      other.start_date >= self.exclusive_end_date
  end

  #
  #  All the dates of other are our dates too.
  #
  def contains?(other)
    self.start_date <= other.start_date &&
      self.exclusive_end_date >= other.exclusive_end_date
  end

  def slide(days)
    self.class.new(@start_date + days, @exclusive_end_date + days)
  end

  def ==(other)
    self.start_date == other.start_date &&
      self.exclusive_end_date == other.exclusive_end_date
  end

  def eql?(other)
    self.start_date == other.start_date &&
      self.exclusive_end_date == other.exclusive_end_date
  end

  def &(other)
    if self.overlaps?(other)
      self.class.new([self.start_date, other.start_date].max,
                     [self.exclusive_end_date, other.exclusive_end_date].min)
    else
      nil
    end
  end

  def to_s
    "#{self.start_date} - #{self.exclusive_end_date - 1.day}"
  end

  def each
    date = self.start_date
    while date < self.exclusive_end_date do
      yield date
      date += 1.day
    end
  end

end

