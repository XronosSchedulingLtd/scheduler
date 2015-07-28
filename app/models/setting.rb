# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Setting < ActiveRecord::Base

  @@current_era = nil
  @@next_era = nil
  @@checked_next_era = false
  @@previous_era = nil
  @@checked_previous_era = false
  @@perpetual_era = nil
  @@checked_perpetual_era = false

  belongs_to :current_era, class_name: :Era
  belongs_to :next_era, class_name: :Era
  belongs_to :previous_era, class_name: :Era
  belongs_to :perpetual_era, class_name: :Era

  after_save :flush_cache

  validates :current_era, :presence => true
  validates :perpetual_era, :presence => true
  validate :no_more_than_one

  # We never want this record to be deleted.
  def destroy
    raise "Can't delete the system settings"
  end

  #
  #  Each time our record is saved, we need to dispose of any cached
  #  values.
  #
  def flush_cache
    @@current_era = nil
    @@next_era = nil
    @@checked_next_era = false
    @@previous_era = nil
    @@checked_previous_era = false
    @@perpetual_era = nil
    @@checked_perpetual_era = false
  end

  def self.current_era
    unless @@current_era
      setting = Setting.first
      if setting
        @@current_era = setting.current_era
      else
        @@current_era = nil
      end
    end
    @@current_era
  end

  def self.next_era
    unless @@checked_next_era
      setting = Setting.first
      if setting
        @@next_era = setting.next_era
      else
        @@next_era = nil
      end
      @@checked_next_era = true
    end
    @@next_era
  end

  def self.previous_era
    unless @@checked_previous_era
      setting = Setting.first
      if setting
        @@previous_era = setting.previous_era
      else
        @@previous_era = nil
      end
      @@checked_previous_era = true
    end
    @@previous_era
  end

  def self.perpetual_era
    unless @@checked_perpetual_era
      setting = Setting.first
      if setting
        @@perpetual_era = setting.perpetual_era
      else
        @@perpetual_era = nil
      end
      @@checked_perpetual_era = true
    end
    @@perpetual_era
  end

  #
  #  End-of-year processing.  Move us on into the next era.
  #
  def end_of_era
    #
    #  Close out any groups in the current era.
    #
    if self.current_era &&
       self.next_era
      group_count = 0
      self.current_era.groups.each do |group|
        group.ceases_existence(self.current_era.ends_on)
      end
      puts "#{group_count} groups terminated."
      self.previous_era = self.current_era
      self.current_era  = self.next_era
      self.next_era     = nil
      self.save!
      puts "Rolled over."
    end
    nil
  end

  protected

  def no_more_than_one
    existing = Setting.first
    if (existing) && (existing.id != self.id)
      errors.add(:overall, "No more than one settings record allowed.")
    end
  end
end
