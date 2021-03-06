#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'tod'

#
#  Maintains a set of time slots, in order and merging where appropriate.
#
#  A TimeSlotSet only ever represents an ordered set of non-overlapping
#  time slots.
#
class TimeSlotSet < Array

  attr_reader :date

  def initialize(*params)
    super()
    @date = nil
    params.each do |p|
      case p
      when nil
        # Do nothing
      when Date
        @date = p
      when TimeSlot
        self << p
      else
        self << TimeSlot.new(p)
      end
    end
    tidy_up!
  end

  alias_method :parent_shift, :<<

  def <<(new_slot)
    unless new_slot.is_a?(TodShift)
      raise ArgumentError.new("Can't add object of type #{new_slot.class}.")
    end
    super
    tidy_up!
  end

  def remove(going)
    #
    #  Remove either one time slot, or a set of them, from our set.
    #
    if going.is_a?(TodShift)
      do_remove(going)
    elsif going.is_a?(TimeSlotSet)
      going.each do |g|
        self.remove(g)
      end
    else
      raise ArgumentError.new("Can't subtract object of type #{going.class}.")
    end
    self
  end

  def &(other)
    #
    #  Here we are fussier because we need the other to be "tidy".
    #
    unless other.is_a?(TimeSlotSet)
      raise ArgumentError.new("Can't intersect with object of type #{other.class}.")
    end
    if self.empty? || other.empty?
      TimeSlotSet.new(self.date)       # Empty
    else
      #
      #  We now need to identify the time periods *common* to both
      #  sets.  We could do this by identifying the maximum duration,
      #  then doing a double subtraction.  Can we do it more directly
      #  though?
      #
      working = TimeSlotSet.new(self.date,
      [
        [self[0].beginning, other[0].beginning].min,
        [self[-1].ending, other[-1].ending].max
      ])
      #puts "working"
      #working.dump
      working.remove(other)
      #puts "removed other"
      #working.dump
      #
      #  Note that remove alters the object on which you call it,
      #  so use a dup.
      #
      result = self - working
      #puts "result"
      #result.dump
      result
    end
  end

  def |(other)
    #
    #  Here we are fussier because we need the other to be "tidy".
    #
    unless other.is_a?(TimeSlotSet)
      raise ArgumentError.new("Can't take union with object of type #{other.class}.")
    end
    result = self.dup
    other.each do |slot|
      result << slot
    end
    result
  end

  def -(other)
    self.dup.remove(other)
  end

  def dump
    self.each do |s|
      puts " #{s.to_s}"
    end
  end

  #
  #  Return our longest time slot, or nil if we have none.
  #
  def longest
    self.max {|a,b| a.duration <=> b.duration}
  end

  #
  #  Return all our slots which are no shorter than mins minutes.
  #  We return them as a new TimeSlotSet, not just as a new array
  #  of TimeSlots
  #
  def at_least_mins(mins)
    seconds = mins * 60
    self.class.new(self.date, *self.select {|ts| ts.duration >= seconds})
  end

  def to_partial_path
    'time_slot_set'
  end

  private

  def tidy_up!
    working = self.sort
    self.clear
    current = working.shift
    if current
      while (nextone = working.shift)
        if current.overlaps?(nextone) || current.abuts?(nextone)
          current = current.merge(nextone)
        else
          self.parent_shift current
          current = nextone
        end
      end
      self.parent_shift current
    end
  end

  def do_remove(slot)
    #
    #  An interesting question arises when we subtract a slot of zero
    #  duration.  Should that cut another slot in two?  It could, but
    #  then the next invocation of tidy_up! (not here, but any further
    #  operation might cause one) will glue them back together again.
    #
    #  Until we come up with a requirement and design for this kind of
    #  slicing (would need to store info about where the cut is), we
    #  ignore zero duration slots for subtraction.
    #
    unless slot.duration == 0
      working = self.sort
      self.clear
      while (current = working.shift)
        if current.overlaps?(slot)
          current.subtract(slot) do |remains|
            self.parent_shift remains
          end
        else
          self.parent_shift current
        end
      end
    end
  end

end
