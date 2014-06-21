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
  def active
    true
  end

  def element_name
    name
  end

end
