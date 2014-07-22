# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Tutorgroup < ActiveRecord::Base

  validates :house, presence: true
  validates :staff, presence: true

  belongs_to :staff

  include Grouping

  self.per_page = 15
  def active
    true
  end

end
