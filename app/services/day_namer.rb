#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  It seems silly to have a file just for this, but it's used in
#  more than one place, so...
#
class DayNamer
  class DaynameWithIndex
    attr_reader :name, :index

    def initialize(name, index)
      @name = name
      @index = index
    end
  end

  @@daynames_with_index = []
  Date::ABBR_DAYNAMES.each_with_index do |dn, i|
    @@daynames_with_index << DaynameWithIndex.new(dn, i)
  end

  def self.daynames_with_index
    @@daynames_with_index
  end
end
