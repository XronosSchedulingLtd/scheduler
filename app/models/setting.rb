# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Setting < ActiveRecord::Base

  @@current_era = nil

  belongs_to :current_era, class_name: :Era

  after_save :flush_cache

  validates :current_era, :presence => true
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

  protected

  def no_more_than_one
    existing = Setting.first
    if (existing) && (existing.id != self.id)
      errors.add(:overall, "No more than one settings record allowed.")
    end
  end
end
