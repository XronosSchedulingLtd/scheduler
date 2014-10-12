# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Tutorgrouppersona < ActiveRecord::Base

  validates :house, presence: true
  validates :staff, presence: true

  belongs_to :staff

  include Persona

  #
  #  Returns a string like "3JHW"
  #
  def tutorgroup_name
    current_era = Setting.current_era
    if current_era
      year_group = (self.start_year - current_era.starts_on.year + 7).to_s
    else
      year_group = ""
    end
    "#{year_group}#{staff.initials}"
  end

  self.per_page = 15
  def active
    true
  end

end
