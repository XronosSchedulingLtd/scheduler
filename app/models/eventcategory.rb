# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Eventcategory < ActiveRecord::Base

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :pecking_order, presence: true
  validates :pecking_order, numericality: { only_integer: true }

  has_many :events, dependent: :destroy

  has_many :users, foreign_key: :preferred_event_category_id, :dependent => :nullify
  after_save :flush_cache

  scope :schoolwide,       lambda { where(schoolwide: true) }
  scope :publish,          lambda { where(publish: true) }
  scope :name_starts_with, lambda { |prefix| where("name LIKE :prefix",
                                                   prefix: "#{prefix}%") }
  scope :deprecated, -> { where(deprecated: true) }
  scope :available, -> { where(deprecated: false) }

  scope :privileged, -> { where(privileged: true) }
  scope :unprivileged, -> { where(privileged: false) }

  @@category_cache = {}

  def <=>(other)
    self.name <=> other.name
  end

  def events_on(startdate     = nil,
                enddate       = nil,
                eventsource   = nil,
                resource      = nil,
                include_nonexistent = false)
    Event.events_on(startdate,
                    enddate,
                    self,
                    eventsource,
                    resource,
                    nil,
                    include_nonexistent)
  end

  #
  #  Since categories change very, very seldom, it might be worth having
  #  a memory cache.
  #
  def self.cached_category(category_name)
    @@category_cache[category_name] ||=
      Eventcategory.find_by(name: category_name)
  end

  def flush_cache
    @@category_cache = {}
  end

  #
  #  Maintenance methods to add relevant properties to existing events.
  #
  def add_property(property)
    updated_count = 0
    not_updated_count = 0
    self.events.each do |event|
      if event.involves?(property)
        not_updated_count += 1
      else
        commitment = Commitment.new
        commitment.event   = event
        commitment.element = property.element
        commitment.save!
        updated_count += 1
      end
    end
    puts "Updated #{updated_count} events with #{property.name} property. #{not_updated_count} already there."
  end

  def self.add_properties
    #
    #  First make sure the necessary properties exist.
    #
    calendar_property = Property.ensure("Calendar")
    key_date_property = Property.ensure("Key date")
    #
    #  Anything in the existing calendar category gets the Calendar property.
    #
    calendar_category = Eventcategory.find_by(name: "Calendar")
    if calendar_category
      calendar_category.add_property(calendar_property)
    else
      puts "Can't find calendar event category."
    end
    #
    #  Anything in Key date (internal) gets key date.
    #
    kdi_category = Eventcategory.find_by(name: "Key date (internal)")
    if kdi_category
      kdi_category.add_property(key_date_property)
    else
      puts "Can't find key date (internal) event category."
    end
    #
    #  Anything in Key date (external) gets both
    #
    kde_category = Eventcategory.find_by(name: "Key date (external)")
    if kde_category
      kde_category.add_property(calendar_property)
      kde_category.add_property(key_date_property)
    else
      puts "Can't find key date (external) event category."
    end
    #
    #  As do week letters
    #
    wl_category = Eventcategory.find_by(name: "Week letter")
    if wl_category
      wl_category.add_property(calendar_property)
      wl_category.add_property(key_date_property)
    else
      puts "Can't find week letter event category."
    end
    nil
  end

end
