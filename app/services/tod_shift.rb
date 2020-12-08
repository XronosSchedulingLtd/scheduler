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

  class InnerShift

    attr_reader :beg_sec, :end_sec

    def initialize(beg_sec, end_sec)
      @beg_sec = beg_sec
      @end_sec = end_sec
    end

    def duration
      @end_sec - @beg_sec
    end

    def hash_str
      "#{@beg_sec}:#{@end_sec}".hash
    end

    def include?(tod)
      second = tod.to_i
      @beg_sec <= second && second < @end_sec
    end

    #
    #  One starts as the other ends.
    #
    def abuts?(other)
      self.beg_sec == other.end_sec || self.end_sec == other.beg_sec
    end

    #
    #  Starts or ends at precisely the same time.
    #
    def coterminates?(other)
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
    def overlaps?(other)
      self.beg_sec < other.end_sec && other.beg_sec < self.end_sec
    end

    #
    #  Sort of the inverse of overlaps?  They occupy completely distinct
    #  times, but may just touch.
    #
    def avoids?(other)
      self.beg_sec >= other.end_sec || other.beg_sec >= self.end_sec
    end

    #
    #  All the times of other our our times too.
    #
    def contains?(other)
      self.beg_sec <= other.beg_sec && self.end_sec >= other.end_sec
    end
  end

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
      @inner = InnerShift.new(beg_sec, end_sec)
      @inverse = false
    else
      #
      #  Our requested range traverses midnight.  This means it is actually
      #  two ranges - start to midnight, midnight to end.  In order to express
      #  it as a single range internally we actually store the bit of the
      #  day which is *not* within it.
      #
      @inner = InnerShift.new(end_sec, beg_sec)
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
    "#{@inner.hash_str}:#{@inverse}:#{@exclude_end}".hash
  end

  def duration
    if @inverse
      Tod::TimeOfDay::NUM_SECONDS_IN_DAY - @inner.duration
    else
      @inner.duration
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
      inner.abuts?(other.inner)
    else
      inner.coterminates?(other.inner)
    end
  end

  def include?(tod)
    @inverse ^ @inner.include?(tod)
  end

  def contains?(other)
    unless other.is_a?(TodShift)
      raise ArgumentError.new("can only contain other TodShifts")
    end
    if self.inverse
      if other.inverse
        other.inner.contains?(self.inner)
      else
        self.inner.avoids?(other.inner)
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
        self.inner.contains?(other.inner)
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
        !self.inner.contains?(other.inner)
      end
    else
      if other.inverse
        !other.inner.contains?(self.inner)
      else
        inner.overlaps?(other.inner)
      end
    end
  end

  protected

  attr_reader :inner, :inverse

end
