# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Teachinggroup < ActiveRecord::Base

  validates :name,  presence: true
  validates :era,   presence: true

  belongs_to :era

  include Elemental
  include Grouping

  self.per_page = 15

  scope :current, -> { where(current: true) }

  def active
    true
  end

  def element_name
    name
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
