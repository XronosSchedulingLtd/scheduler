# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Era < ActiveRecord::Base

  has_many :groups,         dependent: :destroy

  def teachinggroups
    self.groups.select {|g| g.visible_group_type == "Teachinggroup"}
  end

  def tutorgroups
    self.groups.select {|g| g.visible_group_type == "Tutorgroup"}
  end

  def fix_all_groups
    self.groups.each do |g|
      g.set_start_date(self.starts_on)
    end
    nil
  end
end
