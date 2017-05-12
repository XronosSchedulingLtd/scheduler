# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class DayShapeManager

  @@template_type = nil
  @@checked_tt = false

  #
  #  This is a class level method so it can be used without instantiating
  #  an object and the result cached.
  #
  def self.template_type
    unless @@checked_tt
      @@template_type =
        RotaTemplateType.find_by(name: "Day shape")
      @@checked_tt = true
    end
    @@template_type
  end

  def self.flush_cache
    @@template_type = nil
    @@checked_tt = false
  end
end
