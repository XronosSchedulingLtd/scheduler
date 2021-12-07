#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'tod'

class TimeSlot < TodShift
  #
  #  Keeps track of one time slot within a day.  E.g. 10:00 - 11:15
  #  Provides helper methods for manipulating them.
  #
  #  Built on top of Tod::TimeOfDay and TodShift
  #
  #
  #  Note that we provide one bit of additional functionality
  #  over and above Tod::TimeOfDay - we can express midnight at
  #  the end of the day separately from midnight at the beginning.
  #

  def initialize(*params)
    #
    #  To start with we will accept either one argument:
    #
    #    "10:00 - 11:15"
    #
    #  or two arguments, each of which can be either a string:
    #
    #    "10:00"
    #
    #  or a Tod::TimeOfDay
    #
    #  Internally we use Tod::TimeOfDays and TodShifts
    #
    #
    #  Allow for arguments to have been passed as an array.
    #
    params.flatten!
    #
    #  And now see what we have.
    #
    if params.size == 1
      param = params[0]
      #
      #  Must be a single string of the form shown above.  Spaces optional.
      #  We will worry about the hyphen and the optional spaces.
      #  Tod::TimeOfDay.parse can then worry about the two halves.
      #
      #  It's tempting to look for /(\d\d:\d\d)/ but Tod can cope with
      #  a lot more than just that.
      #
      splut = param.match(/(\S+)(\s*-\s*)(\S+)/)
      if splut
        time0 = Tod::TimeOfDay.parse(splut[1])
        time1 = Tod::TimeOfDay.parse(splut[3])
      else
        raise ArgumentError.new("Can't interpret \"#{param}\" as a time range.")
      end
    elsif params.size == 2
      time0 = params[0].instance_of?(Tod::TimeOfDay) ?
        params[0] :
        Tod::TimeOfDay.parse(params[0])
      time1 = params[1].instance_of?(Tod::TimeOfDay) ?
        params[1] :
        Tod::TimeOfDay.parse(params[1])
    elsif params.size == 3
      #
      #  It was a bit of a stylistic error to have this class derive
      #  from TodShift but then re-define the constructor.  As a dead
      #  minimum, we need to accept anything which the original
      #  constructor would have accepted.
      #
      #  We have to assume that they're the right params for a raw TodShift
      #
      time0 = params[0]
      time1 = params[1]
    else
      raise ArgumentError.new("Wrong number of arguments")
    end
    #
    #  If we get here, we should now have time0 and time1
    #
    if time1 < time0
      raise ArgumentError.new("Slot duration can't be negative.")
    end
    super(time0, time1, true)
  end

  def <=>(other)
    #
    #  We allow for the other being merely a TodShift
    #
    if other.is_a?(TodShift)
      #
      #  Start time is more significant.
      #
      result = self.beginning.second_of_day <=> other.beginning.second_of_day
      if result == 0
        result = self.ending.second_of_day <=> other.ending.second_of_day
      end
      result
    else
      nil
    end
  end

  def <(other)
    #
    #  One time slot is strictly less than another if it ends before
    #  the other begins.  Note that we have exclusive end times so
    #  a slot ending at 10:00 *is* strictly less than one starting at
    #  10:00 - they do not overlap.
    #
    if other.is_a?(TodShift)
      self.ending.second_of_day <= other.beginning.second_of_day
    else
      raise ArgumentError.new("Can't compare with object of type #{other.class}")
    end
  end

  def >(other)
    if other.is_a?(TodShift)
      self.beginning.second_of_day >= other.ending.second_of_day
    else
      raise ArgumentError.new("Can't compare with object of type #{other.class}")
    end
  end

  #
  #  Note that we don't have corresponding <= or >=.  Defining these gets
  #  really interesting.  All I want to be able to do is say that one
  #  slot is definitely before or after another.  We have the "overlaps?"
  #  functionality of TodShift to handle overlaps.
  #
  #  The above two functions disagree slightly with the <=> function.
  #

  def to_s
    "#{self.beginning.strftime("%H:%M")} - #{self.ending.strftime("%H:%M")}"
  end

  def merge(other)
    if other.is_a?(TodShift)
      start_tod = [self.beginning, other.beginning].min
      end_tod = [self.ending, other.ending].max
      TimeSlot.new(start_tod, end_tod)
    else
      raise ArgumentError.new("Can't merge with object of type #{other.class}")
    end
  end

  def subtract(other)
    #
    #  The result of subtraction may be 0, 1 or 2 slots, so we return
    #  them via a yield.
    #
    unless other.is_a?(TodShift)
      raise ArgumentError.new("Can't subtract object of type #{other.class}")
    end
    if self.overlaps?(other)
      unless other.contains?(self)
        #
        #  They overlap, but there should be something left.
        #
        if self.beginning < other.beginning
          #
          #  We start first.  Keep our early part.
          #
          yield TimeSlot.new(self.beginning, other.beginning)
        end
        if self.ending > other.ending
          #
          #  We end second.
          #
          yield TimeSlot.new(other.ending, self.ending)
        end
      end
    else
      self
    end
  end

  def to_partial_path
    'time_slot'
  end

  def mins
    #
    #  Return our duration in minutes.  The underlying TodShift prefers
    #  seconds.
    #
    self.duration / 60
  end
end
