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

  #
  #  I'd like to call this just public, but Rails already uses that name
  #  for internal purposes.
  #
  scope :public_ones,      lambda { where(public: true) }
  scope :publish,          lambda { where(publish: true) }
  scope :for_users,        lambda { where(for_users: true) }
  scope :name_starts_with, lambda { |prefix| where("name LIKE :prefix",
                                                   prefix: "#{prefix}%") }

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
  #  A maintenance method to cause all events in a given category to gain
  #  the "Calendar" property.
  #
  def add_calendar_property
    property = Property.find_by_name("Calendar")
    if property
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
      puts "Updated #{updated_count} events. #{not_updated_count} already there."
      nil
    else
      puts "Can't find Calendar property."
    end
  end

end
