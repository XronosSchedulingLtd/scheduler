#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2022 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  A preferred colour set is simply an array of colour preferences but we
#  override a few methods to ensure the array is always ordered
#  with the weightiest ones first.
#

class PCSet < Array

  class PC
    #
    # Preferred Colour, but given a very short name for efficient
    # serialization.
    #
    #  We would use:
    #    attr_accessor :sponsor, :weight, :colour
    #
    #  but our internal names are deliberately shortened.
    #

    def initialize(sponsor, weight, colour)
      #
      #  Again, very short names for serialization efficiency.
      #
      @s = sponsor
      @w = weight
      @c = colour
    end

    def <=>(other)
      if other.instance_of? PC
        #
        #  We want them sorted in order with largest first.
        #
        other.weight <=> self.weight
      else
        nil
      end
    end

    def sponsor
      @s
    end

    def weight
      @w
    end

    def colour
      @c
    end

    def weight=(value)
      @w = value
    end

    def colour=(value)
      @c = value
    end

  end

  def <<(item)
    super
    self.sort!
  end

  def add(sponsor, weight, colour)
    #
    #  Might already have an entry for this sponsor.  Don't want
    #  another one.
    #
    existing = self.find { |e| e.sponsor == sponsor }
    if existing
      existing.weight = weight
      existing.colour = colour
      self.sort!
    else
      self << PC.new(sponsor, weight, colour)
    end
  end

  def remove_from(sponsor)
    #
    #  If we currently have a preferred colour from this sponsor
    #  then remove it.
    #
    target = self.find { |e| e.sponsor == sponsor }
    if target
      self.delete(target)
    end
    return current
  end

  def current
    if self.empty?
      nil
    else
      self[0].colour
    end
  end

end
