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
  @@hostname = nil
  @@got_hostname = false
  @@enforce_permissions = false
  @@checked_enforce_permissions = false
  @@checked_current_mis = false
  @@current_mis = nil
  @@checked_previous_mis = false
  @@previous_mis = nil
  @@auth_type = nil
  @@checked_auth_type = false
  @@dns_domain_name = nil
  @@from_email_address = nil

  belongs_to :current_era, class_name: :Era
  belongs_to :next_era, class_name: :Era
  belongs_to :previous_era, class_name: :Era
  belongs_to :perpetual_era, class_name: :Era

  after_save :flush_cache

  validates :current_era, :presence => true
  validates :perpetual_era, :presence => true
  validate :no_more_than_one

  enum auth_type: [:google_auth, :google_demo_auth]

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
    @@enforce_permissions = nil
    @@checked_enforce_permissions = false
    @@dns_domain_name = nil
    @@from_email_address = nil
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

  def self.enforce_permissions?
    unless @@checked_enforce_permissions
      setting = Setting.first
      if setting
        @@enforce_permissions = setting.enforce_permissions
      end
      @@checked_enforce_permissions = true
    end
    @@enforce_permissions
  end

  def self.current_mis
    unless @@checked_current_mis
      setting = Setting.first
      if setting
        @@current_mis = setting.current_mis
      end
      @@checked_current_mis = true
    end
    @@current_mis
  end

  def self.previous_mis
    unless @@checked_previous_mis
      setting = Setting.first
      if setting
        @@previous_mis = setting.previous_mis
      end
      @@checked_previous_mis = true
    end
    @@previous_mis
  end

  def self.auth_type
    unless @@checked_auth_type
      setting = Setting.first
      if setting
        @@auth_type = setting.auth_type
      end
      @@checked_auth_type = true
    end
    @@auth_type
  end

  def self.dns_domain_name
    unless @@dns_domain_name
      setting = Setting.first
      if setting
        @@dns_domain_name = setting.dns_domain_name
      end
    end
    @@dns_domain_name
  end

  def self.from_email_address
    unless @@from_email_address
      setting = Setting.first
      if setting
        @@from_email_address = setting.from_email_address
      end
    end
    @@from_email_address
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
        #
        #  The ceases_existence method expects the first day on which
        #  the individual is *not* a member.
        #
        group.ceases_existence(self.current_era.ends_on + 1.day)
        group_count += 1
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

  def self.hostname
    unless @@got_hostname
      @@hostname = `hostname -f`.chomp
      @@got_hostname = true
    end
    @@hostname
  end

  protected

  def no_more_than_one
    existing = Setting.first
    if (existing) && (existing.id != self.id)
      errors.add(:base, "No more than one settings record allowed.")
    end
  end
end
