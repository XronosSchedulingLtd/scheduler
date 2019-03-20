# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Era < ApplicationRecord

  has_many :groups, dependent: :destroy
  has_many :event_collections, dependent: :destroy
  has_one  :setting,
           :foreign_key => :current_era_id,
           :dependent => :nullify
  has_one  :future_setting,
           :class_name => :Setting,
           :foreign_key => :next_era_id,
           :dependent => :nullify
  has_one  :previous_setting,
           :class_name => :Setting,
           :foreign_key => :previous_era_id,
           :dependent => :nullify
  has_one  :perpetual_setting,
           :class_name => :Setting,
           :foreign_key => :perpetual_era_id,
           :dependent => :nullify

  validates :starts_on, presence: true
  validates :name,      presence: true
  validate :not_backwards

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
    self.groups.size == 0 &&
      self.setting == nil &&
      self.future_setting == nil &&
      self.previous_setting == nil &&
      self.perpetual_setting == nil
  end

  #
  #  Sort by start dates.
  #
  def <=>(other)
    self.starts_on <=> other.starts_on
  end

  def formatted_starts_on
    self.starts_on ? self.starts_on.to_formatted_s(:dmy) : ''
  end

  def formatted_ends_on
    self.ends_on ? self.ends_on.to_formatted_s(:dmy) : ''
  end

  private

  def not_backwards
    if self.ends_on &&
       self.starts_on &&
       self.ends_on < self.starts_on
      errors.add(:ends_on, "(#{self.ends_on.to_s}) must be no earlier than start date (#{self.starts_on.to_s}).")
    end
  end

end
