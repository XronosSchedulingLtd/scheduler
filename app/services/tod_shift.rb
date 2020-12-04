#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  This is a re-implementation of Tod::Shift made simpler by getting
#  the internals right.
#
require 'tod'

class TodShift

  attr_reader :beginning, :ending, :exclude_end

  def initialize(beginning, ending, exclude_end=true)

    unless beginning.is_a?(Tod::TimeOfDay)
      raise ArgumentError.new("beginning must be a time of day")
    end
    unless ending.is_a?(Tod::TimeOfDay)
      raise ArgumentError.new("ending must be a time of day")
    end
    unless exclude_end
      raise ArgumentError.new("don't currently support inclusive endings")
    end

    @beginning = beginning
    @ending = ending
    @exclude_end = exclude_end
    #
    #  Internally we work with seconds since midnight.
    #
    beg_sec = beginning.to_i
    if beg_sec == Tod::TimeOfDay::NUM_SECONDS_IN_DAY
      #
      #  Someone is playing at silly buggers and making it look like
      #  we have a Shift traversing midnight when we don't really.
      #
      beg_sec = 0
    end
    end_sec = ending.to_i
    if end_sec >= beg_sec
      #
      #  A normal, forwards range.  Doesn't traverse midnight.
      #
      @beg_sec = beg_sec
      @end_sec = end_sec
      @inverse = false
    else
      #
      #  Our requested range traverses midnight.  This means it is actually
      #  two ranges - start to midnight, midnight to end.  In order to express
      #  it as a single range internally we actually store the bit of the
      #  day which is *not* within it.
      #
      @beg_sec = end_sec
      @end_sec = beg_sec
      @inverse = true
    end
    freeze
  end

  def slide(seconds)
    self.class.new(@beginning + seconds, @ending + seconds, @exclude_end)
  end

  def exclude_end?
    @exclude_end
  end

  def hash
    "#{@beg_sec}:#{@end_sec}:#{@inverse}:#{@exclude_end}".hash
  end

  def duration
    if @inverse
      Tod::TimeOfDay::NUM_SECONDS_IN_DAY - internal_duration
    else
      internal_duration
    end
  end

  def ==(other)
    self.beginning == other.beginning &&
      self.ending == other.ending &&
      self.exclude_end? == other.exclude_end?
  end

  def eql?(other)
    self.beginning == other.beginning &&
      self.ending == other.ending &&
      self.exclude_end? == other.exclude_end?
  end

  def abuts?(other)
    unless other.is_a?(TodShift)
      raise ArgumentError.new("can only abut other TodShifts")
    end
    if self.inverse == other.inverse
      internal_abuts?(other)
    else
      internal_coterminates?(other)
    end
  end

  def include?(tod)
    second = tod.to_i
    if @inverse
      second >= @end_sec || second < @beg_sec
    else
      @beg_sec <= second && second < @end_sec
    end
  end

  def contains?(other)
    unless other.is_a?(TodShift)
      raise ArgumentError.new("can only contain other TodShifts")
    end
    if self.inverse
      if other.inverse
        other.internal_contains?(self)
      else
        self.internal_avoids?(other)
      end
    else
      if other.inverse
        #
        #  If the other one is inverted - that is, it passes through
        #  midnight - and yet we don't, then we can't possibly contain
        #  it.
        #
        false
      else
        self.internal_contains?(other)
      end
    end
  end

  #
  #  Must have at least some shared time.  This may be of zero duration
  #  but not at the ends.
  #
  def overlaps?(other)
    unless other.is_a?(TodShift)
      raise ArgumentError.new("can only contain other TodShifts")
    end
    if self.inverse
      if other.inverse
        true
      else
        !self.internal_contains?(other)
      end
    else
      if other.inverse
        !other.internal_contains?(self)
      else
        internal_overlaps?(other)
      end
    end
  end

  protected

  attr_reader :beg_sec, :end_sec, :inverse

  def internal_duration
    @end_sec - @beg_sec
  end

  #
  #  One starts as the other ends.
  #
  def internal_abuts?(other)
    self.beg_sec == other.end_sec || self.end_sec == other.beg_sec
  end

  #
  #  Starts or ends at precisely the same time.
  #
  def internal_coterminates?(other)
    self.beg_sec == other.beg_sec || self.end_sec == other.end_sec
  end

  #
  #  Shares at least one common time.  This may be only an instant,
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
  def internal_overlaps?(other)
    self.beg_sec < other.end_sec && other.beg_sec < self.end_sec
  end

  #
  #  Sort of the inverse of overlaps?  They occupy completely distinct
  #  times, but may just touch.
  #
  def internal_avoids?(other)
    self.beg_sec >= other.end_sec || other.beg_sec >= self.end_sec
  end

  #
  #  All the times of other our our times too.
  #
  def internal_contains?(other)
    self.beg_sec <= other.beg_sec && self.end_sec >= other.end_sec
  end

end
