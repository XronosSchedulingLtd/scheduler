# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Teachinggrouppersona < ActiveRecord::Base

  include Persona

  has_and_belongs_to_many :staffs
  before_destroy { staffs.clear }

  belongs_to :subject

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
