#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Eventcategory < ApplicationRecord

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :pecking_order, presence: true
  validates :pecking_order, numericality: { only_integer: true }

  has_many :events, dependent: :destroy
  has_many :proto_events, dependent: :destroy

  has_one :setting, foreign_key: :wrapping_eventcategory_id, dependent: :nullify

  has_many :users, foreign_key: :preferred_event_category_id, :dependent => :nullify
  after_save :flush_cache
  after_save :update_dependent_events, if: :saved_change_to_confidential?

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

  scope :timetable, -> { where(timetable: true) }
  scope :exclude, lambda { |ids| where.not(id: ids) }

  @@category_cache = {}
  @@non_busy_categories = nil
  @@busy_categories = nil

  FIELD_TITLE_TEXTS = {
      pecking_order:
        "Controls the order in which events will appear in the Days controller.  Smaller values first.",
      schoolwide:
        "Appears on the schedule for all logged-in users.",
      publish:
        "Included in ical exports - e.g. to Google Calendar.",
      visible:
        "Shown on the web display in association with attached resources. Events which are not visible will be seen only by their owners.",
      unimportant:
        "Not important enough to prevent use for cover - e.g. assemblies.",
      can_merge:
        "Two events of the same category can be merged for cover purposes.",
      can_borrow:
        "If the event boasts more than one resource of the same type, then individuals can be borrowed for cover.",
      compactable:
        "When exporting calendar data, can multi-day events be compacted to reduce their number of appearances?  For timed events, can the end time be suppressed?",
      privileged:
        "This event category can be selected only by users who have the corresponding bit set in their user records.",
      clashcheck:
        "Events in this category are to be checked for clashes and annotated.  All events are included in the check, but only these will be annotated.",
      busy:
        "The opposite side of the previous flag.  Should events in this category be regarded as rendering their resources busy?  If this flag is unset, then the corresponding events will not be regarded as clashing with events which are being checked for clashes.",
      deprecated:
        "This event category no longer appears in the pull-down and events cannot be saved with this category.  Old events may still exist.",
      timetable:
        "Should events in this category appear on printed timetables?",
      confidential:
        "Events in this category are confidential.  The body text is visible only to those with a need to know - those involved in the event."
  }
  FIELD_TITLE_TEXTS.default = "Unknown"

  self.per_page = 20

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
    @@non_busy_categories = nil
    @@busy_categories = nil
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
  #  Provide a potentially cached list of non-busy
  #  categories.  Only cached very briefly, but
  #  potentially useful if we are doing multiple lookups.
  #
  def self.non_busy_categories
    @@non_busy_categories ||= Eventcategory.where(busy: false).to_a
  end

  def self.busy_categories
    @@busy_categories ||= Eventcategory.where(busy: true).to_a
  end

  def can_destroy?
    self.events.count == 0
  end

  def self.title_of(key)
    FIELD_TITLE_TEXTS[key]
  end

  protected

  def update_dependent_events
    #
    #  Do a bulk update.  This will not trigger the callback in the
    #  event record.  It is also phenomenally faster than doing
    #  individual updates.
    #
    self.events.where(confidential: !self.confidential?).
                update_all(confidential: self.confidential?)
  end

end
