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
  has_many :proto_events, dependent: :destroy

  has_many :users, foreign_key: :preferred_event_category_id, :dependent => :nullify
  after_save :flush_cache

  scope :publish,          lambda { where(publish: true) }
  scope :name_starts_with, lambda { |prefix| where("name LIKE :prefix",
                                                   prefix: "#{prefix}%") }
  scope :schoolwide,     -> { where(schoolwide: true) }
  scope :not_schoolwide, -> { where(schoolwide: false) }
  scope :deprecated,     -> { where(deprecated: true) }
  scope :available,      -> { where(deprecated: false) }

  scope :privileged, -> { where(privileged: true) }
  scope :unprivileged, -> { where(privileged: false) }

  scope :visible, -> { where(visible: true) }
  scope :invisible, -> { where(visible: false) }

  scope :exclude, lambda { |ids| where.not(id: ids) }

  @@category_cache = {}

  TO_DEPRECATE = ["Calendar",
                  "Admissions Event",
                  "Gap (invisible)",
                  "Gap (visible)",
                  "Key date (external)",
                  "Key date (internal)",
                  "Public event"]
  TO_MAKE_PRIVILEGED = ["Assembly",
                        "Duty",
                        "Invigilation",
                        "Other Half",
                        "Registration",
                        "Reporting deadline",
                        "Study leave",
                        "Supervised study",
                        "Tutor period",
                        "Week letter"]
  NewCategory = Struct.new(:name, :schoolwide, :privileged)
  TO_CREATE = [NewCategory.new("Hospitality",      false, false),
               NewCategory.new("Parents' evening", false, true),
               NewCategory.new("Date - crucial",   true,  true),
               NewCategory.new("Date - other",     false, false)]

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

  def categories_for(user)
    if user && user.privileged
      if self.deprecated
        Eventcategory.available + [self]
      else
        Eventcategory.available
      end
    else
      if self.deprecated
        Eventcategory.available.unprivileged + [self]
      else
        Eventcategory.available.unprivileged
      end
    end
  end

  def self.categories_for(user)
    if user && user.privileged
      Eventcategory.available
    else
      Eventcategory.available.unprivileged
    end
  end

  def can_destroy?
    self.events.count == 0
  end

end
