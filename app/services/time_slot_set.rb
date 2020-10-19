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
class TimeSlotSet

  def initialize(*params)
    @slots = Array.new
    params.each do |p|
      @slots << TimeSlot.new(p)
    end
    tidy_up!
  end

  #
  #  When dup'ed we want our own array of slots, not a pointer to
  #  the original array.
  #
  def initialize_copy(orig)
    super
    @slots = orig.slots.dup
  end

  def size
    @slots.size
  end

  def [](index)
    @slots[index]
  end

  def <<(new_slot)
    unless new_slot.is_a?(Tod::Shift)
      raise ArgumentError.new("Can't add object of type #{new_slot.class}.")
    end
    @slots << new_slot
    tidy_up!
  end

  def each
    @slots.each do |s|
      yield s
    end
  end

  def remove(going)
    #
    #  Remove either one time slot, or a set of them, from our set.
    #
    if going.is_a?(Tod::Shift)
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

  def empty?
    @slots.empty?
  end

  def &(other)
    #
    #  Here we are fussier because we need the other to be "tidy".
    #
    unless other.is_a?(TimeSlotSet)
      raise ArgumentError.new("Can't intersect with object of type #{other.class}.")
    end
    if self.empty? || other.empty?
      TimeSlotSet.new       # Empty
    else
      #
      #  We now need to identify the time periods *common* to both
      #  sets.  We could do this by identifying the maximum duration,
      #  then doing a double subtraction.  Can we do it more directly
      #  though?
      #
      working = TimeSlotSet.new([
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
    @slots.each do |s|
      puts " #{s.to_s}"
    end
  end

  def ==(other)
    self.size == other.size &&
      self.slots == other.slots
  end

  protected
  
  attr_reader :slots

  private

  def tidy_up!
    working = @slots.sort
    @slots.clear
    current = working.shift
    if current
      while (nextone = working.shift)
        if current.overlaps?(nextone) || current.abuts?(nextone)
          current = current.merge(nextone)
        else
          @slots << current
          current = nextone
        end
      end
      @slots << current
    end
  end

  def do_remove(slot)
    working = @slots.sort
    @slots.clear
    while (current = working.shift)
      if current.overlaps?(slot)
        current.subtract(slot) do |remains|
          @slots << remains
        end
      else
        @slots << current
      end
    end
  end

end
