# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Era < ActiveRecord::Base

  has_many :groups, dependent: :destroy
  has_one  :setting, :foreign_key => :current_era_id
  has_one  :future_setting,
           :class_name => :Setting,
           :foreign_key => :next_era_id
  has_one  :previous_setting,
           :class_name => :Setting,
           :foreign_key => :previous_era_id
  has_one  :perpetual_setting,
           :class_name => :Setting,
           :foreign_key => :perpetual_era_id

  def teachinggroups
    self.groups.teachinggroups
  end

  def tutorgroups
    self.groups.tutorgroups
  end

  def fix_all_groups
    self.groups.each do |g|
      g.set_start_date(self.starts_on)
    end
    nil
  end

  def can_destroy?
    self.groups.size == 0
  end
end
