# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Setting < ActiveRecord::Base

  @@setting = nil
  @@got_hostname = false
  @@hostname = ""

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
    @@setting = Setting.first
  end

  def self.current_era
    @@setting ||= Setting.first
    if @@setting
      @@setting.current_era
    else
      nil
    end
  end

  def self.next_era
    @@setting ||= Setting.first
    if @@setting
      @@setting.next_era
    else
      nil
    end
  end

  def self.previous_era
    @@setting ||= Setting.first
    if @@setting
      @@setting.previous_era
    else
      nil
    end
  end

  def self.perpetual_era
    @@setting ||= Setting.first
    if @@setting
      @@setting.perpetual_era
    else
      nil
    end
  end

  def self.enforce_permissions?
    @@setting ||= Setting.first
    if @@setting
      @@setting.enforce_permissions
    else
      true
    end
  end

  def self.current_mis
    @@setting ||= Setting.first
    if @@setting
      @@setting.current_mis
    else
      nil
    end
  end

  def self.previous_mis
    @@setting ||= Setting.first
    if @@setting
      @@setting.previous_mis
    else
      nil
    end
  end

  def self.auth_type
    @@setting ||= Setting.first
    if @@setting
      @@setting.auth_type
    else
      nil
    end
  end

  def self.dns_domain_name
    @@setting ||= Setting.first
    if @@setting
      @@setting.dns_domain_name
    else
      ""
    end
  end

  def self.from_email_address
    @@setting ||= Setting.first
    if @@setting
      @@setting.from_email_address
    else
      ""
    end
  end

  def self.require_uuid
    @@setting ||= Setting.first
    if @@setting
      @@setting.require_uuid
    else
      true
    end
  end

  def self.protocol_prefix
    @@setting ||= Setting.first
    if @@setting && !@@setting.prefer_https
      "http"
    else
      "https"
    end
  end

  def self.port_no
    if Rails.env == "development"
      ":3000"
    else
      ""
    end
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
