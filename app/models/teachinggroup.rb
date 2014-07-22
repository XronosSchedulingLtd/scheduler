# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Teachinggroup < ActiveRecord::Base

  include Grouping

  self.per_page = 15

  def active
    true
  end

  #
  #  A temporary maintenance method.
  #
  def self.set_all_current
    count = 0
    Teachinggroup.all.each do |tg|
      unless tg.current
        tg.current = true
        tg.save
        count += 1
      end
    end
    puts "Amended #{count} teaching groups."
    nil
  end

end
