# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Era < ActiveRecord::Base

  has_many :teachinggroups, dependent: :destroy
  has_many :tutorgroups, dependent: :destroy

  def fix_all_groups
    self.teachinggroups.each do |tg|
      tg.group.set_start_date(self.starts_on)
    end
    self.tutorgroups.each do |tg|
      tg.group.set_start_date(self.starts_on)
    end
    nil
  end
end
