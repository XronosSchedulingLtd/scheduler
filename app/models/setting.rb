# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Setting < ActiveRecord::Base

  @@setting = nil
  @@got_hostname = false
  @@hostname = ""
  @@rr_versions = nil

  belongs_to :current_era, class_name: :Era
  belongs_to :next_era, class_name: :Era
  belongs_to :previous_era, class_name: :Era
  belongs_to :perpetual_era, class_name: :Era
  belongs_to :room_cover_group_element, class_name: :Element
  belongs_to :wrapping_eventcategory, class_name: :Eventcategory

  belongs_to :default_display_day_shape, class_name: :RotaTemplate
  belongs_to :default_free_finder_day_shape, class_name: :RotaTemplate

  before_save :update_html
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

  def update_html
    if self.event_creation_markup
      self.event_creation_html =
        Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                fenced_code_blocks: true).
                            render(self.event_creation_markup)
    end
  end

  def room_cover_group_element_name
    room_cover_group_element ? room_cover_group_element.name : ""
  end

  def room_cover_group_element_name=(newname)
    #
    #  Do nothing with it.
    #
  end

  def wrapping_eventcategory_name
    wrapping_eventcategory ? wrapping_eventcategory.name : ""
  end

  def wrapping_eventcategory_name=(newname)
    # Ignore
  end

  def self.title_text
    @@setting ||= Setting.first
    if @@setting && !@@setting.title_text.blank?
      @@setting.title_text
    else
      "Scheduler"
    end
  end

  def self.public_title_text
    @@setting ||= Setting.first
    if @@setting && !@@setting.public_title_text.blank?
      @@setting.public_title_text
    else
      "Scheduler"
    end
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

  def self.room_cover_group_element
    @@setting ||= Setting.first
    if @@setting
      @@setting.room_cover_group_element
    else
      nil
    end
  end

  def self.event_creation_prompt
    @@setting ||= Setting.first
    if @@setting
      if @@setting.event_creation_html.blank?
        ""
      else
        @@setting.event_creation_html.html_safe
      end
    else
      nil
    end
  end

  def self.port_no
    if Rails.env == "development"
      ":3000"
    else
      ""
    end
  end

  def self.rr_versions
    unless @@rr_versions
      @@rr_versions = "Ruby #{RUBY_VERSION}, Rails #{Rails::VERSION::STRING}"
    end
    @@rr_versions
  end

  def self.wrapping_before_mins
    @@setting ||= Setting.first
    if @@setting
      @@setting.wrapping_before_mins
    else
      60
    end
  end

  def self.wrapping_after_mins
    @@setting ||= Setting.first
    if @@setting
      @@setting.wrapping_after_mins
    else
      30
    end
  end

  def self.wrapping_eventcategory
    @@setting ||= Setting.first
    if @@setting
      @@setting.wrapping_eventcategory
    else
      nil
    end
  end

  def self.default_display_day_shape
    @@setting ||= Setting.first
    if @@setting
      @@setting.default_display_day_shape
    else
      nil
    end
  end

  def self.default_free_finder_day_shape
    @@setting ||= Setting.first
    if @@setting
      @@setting.default_free_finder_day_shape
    else
      nil
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

  def self.demo_system?
    self.auth_type == "google_demo_auth"
  end

  #
  #  One off method to move existing titles from the environment.
  #
  def self.set_title_texts
    s = Setting.first
    title_text = ENV['SCHEDULER_TITLE_TEXT']
    unless title_text.blank?
      s.title_text = title_text
    end
    public_title_text = ENV['PUBLIC_TITLE_TEXT']
    unless public_title_text.blank?
      s.public_title_text = public_title_text
    end
    s.save
  end

  protected

  def no_more_than_one
    existing = Setting.first
    if (existing) && (existing.id != self.id)
      errors.add(:base, "No more than one settings record allowed.")
    end
  end
end
