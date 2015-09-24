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
    "Updated #{updated_count} events from category #{self.name} with #{property.name} property. #{not_updated_count} already there."
  end

  #
  #  Maintenance method to upgrade the system to using properties.
  #
  def self.add_properties
    #
    #  First make sure the necessary properties exist.
    #
    calendar_property  = Property.ensure("Calendar", "green")
    key_date_property  = Property.ensure("Key date")
    key_event_property = Property.ensure("Twilight meetings etc.")
    gap_property       = Property.ensure("Gap")
    drama_property     = Property.ensure("Drama calendar", "#b40404")
    theatre_property   = Property.ensure("Music calendar", "#5f04b4")
    results = []
    #
    #  Anything in the existing calendar category gets the Calendar property.
    #
    calendar_category = Eventcategory.find_by(name: "Calendar")
    if calendar_category
      results << calendar_category.add_property(calendar_property)
    else
      results << "Can't find calendar event category."
    end
    #
    #  Anything in Key date (external) does too.
    #
    kde_category = Eventcategory.find_by(name: "Key date (external)")
    if kde_category
      results << kde_category.add_property(calendar_property)
    else
      results << "Can't find key date (external) event category."
    end
    #
    #  As do week letters
    #
    wl_category = Eventcategory.find_by(name: "Week letter")
    if wl_category
      results << wl_category.add_property(calendar_property)
    else
      results << "Can't find week letter event category."
    end
    #
    #  Gaps get the gap property.
    #
    gapi_category = Eventcategory.find_by(name: "Gap (invisible)")
    if gapi_category
      results << gapi_category.add_property(gap_property)
    else
      results << "Can't find Gap (invisible) property."
    end
    gapv_category = Eventcategory.find_by(name: "Gap (visible)")
    if gapv_category
      results << gapv_category.add_property(gap_property)
    else
      results << "Can't find Gap (visible) property."
    end
    #
    #  Deprecate categories which we don't intend to use any more.
    #
    TO_DEPRECATE.each do |name|
      category = Eventcategory.find_by(name: name)
      if category
        if category.deprecated
          results << "Category #{name} already deprecated."
        else
          category.deprecated = true
          category.save!
          results << "Deprecated category #{name}."
        end
      else
        results << "Can't find category #{name} to deprecate it."
      end
    end
    TO_MAKE_PRIVILEGED.each do |name|
      category = Eventcategory.find_by(name: name)
      if category
        if category.privileged
          results << "Category #{name} is already privileged."
        else
          category.privileged = true
          category.save!
          results << "Category #{name} set as privileged."
        end
      else
        results << "Can't find category #{name} to make it privileged."
      end
    end
    TO_CREATE.each do |new_category|
      category = Eventcategory.find_by(name: new_category.name)
      if category
        results << "Category #{new_category.name} is already there."
      else
        category = Eventcategory.new
        category.name          = new_category.name
        category.schoolwide    = new_category.schoolwide
        category.publish       = true
        category.privileged    = new_category.privileged
        category.save!
        results << "Created category #{new_category.name}."
      end
    end
    #
    #  Anyone who used to have a preferred event category of "Calendar"
    #  now gets an auto-add concern for the new property.
    #
    calendar_element = calendar_property.element
    User.all.each do |user|
      if user.preferred_event_category == calendar_category
        results << "Removing calendar category from #{user.name}"
        user.preferred_event_category = nil
        user.save!
        results << user.to_control(calendar_element, true)
      else
        #
        #  Make sure everyone else has the calendar, at least as something
        #  which they can view.
        #
        if user.known?
          result = user.to_view(calendar_element)
          unless result.empty?
            results << result
          end
        end
      end
    end
    #
    #  Now some special individuals.
    #
    user_name = "Nick Lloyd"
    elements = ["A202 / Ingham Room",
                "A221 / Drama Studio",
                "A222 / Drama Classroom",
                "AT / Amey Theatre",
                "ATF / Amey Theatre Foyer",
                "CMR / Charles Maude Room",
                "Drama calendar",
                "Music calendar"]
    user = User.find_by(name: user_name)
    if user
      elements.each do |element|
        results << user.to_control(element)
      end
      user.admin = false
      user.save!
    else
      results << "Unable to find user #{user_name} to adjust concerns."
    end
    user_name = "AS Reception"
    elements = ["Admin Hub Meeting Room",
                "Meeting room 1 (reception)",
                "Meeting room 2 (reception)"]
    user = User.find_by(name: user_name)
    if user
      elements.each do |element|
        results << user.to_control(element)
      end
      preferred_category = Eventcategory.find_by(name: "Meeting")
      if preferred_category
        user.preferred_event_category = preferred_category
        user.save!
        results << "Set preferred event category for #{user_name} to Meeting."
      else
        results << "Can't find meeting category for #{user_name}."
      end
    else
      results << "Unable to find user #{user_name} to adjust concerns."
    end
    #
    #  And report on how we did.
    #
    results.each do |string|
      puts string
    end
    nil
  end

end
