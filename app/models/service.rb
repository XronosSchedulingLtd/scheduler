# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Service < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  def active
    true
  end

  def current
    true
  end

  def element_name
    name
  end

end
