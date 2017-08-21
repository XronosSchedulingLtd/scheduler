# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class Journal < ActiveRecord::Base
  belongs_to :event
  belongs_to :event_eventcategory, class_name: :Eventcategory
  belongs_to :event_owner,         class_name: :User
  belongs_to :event_organiser,     class_name: :Element

  has_many   :journal_entries, :dependent => :destroy

  validates :event, presence: true

  self.per_page = 10

  def populate_from_event(event)
    #
    #  Most of this stuff we are duplicating just in case the event
    #  gets deleted and we need to know it later.
    #
    #  We also use it to detect changes.
    #
    self.event_body          = event.body
    self.event_eventcategory = event.eventcategory
    self.event_owner         = event.owner
    self.event_starts_at     = event.starts_at
    self.event_ends_at       = event.ends_at
    self.event_all_day       = event.all_day
    self.event_organiser     = event.organiser
    self.event_organiser_ref = event.organiser_ref
    #
    #  Return self to allow chaining
    #
    self
  end

  def event_created(by_user)
    self.journal_entries.create({
      user:       by_user,
      entry_type: :event_created
    })
  end

  def event_updated(by_user)
    #
    #  Here we need to establish what has changed and perhaps log
    #  more than one thing.
    #
    anything_changed = false
    if self.event_body != self.event.body
      self.journal_entries.create({
        user:       by_user,
        entry_type: :body_text_changed,
        details:    "From \"#{self.event_body}\" to \"#{self.event.body}\""
      })
      anything_changed = true
    end
    if self.event_starts_at != self.event.starts_at ||
      self.event_ends_at != self.event.ends_at ||
      self.event_all_day != self.event.all_day
      self.journal_entries.create({
        user:       by_user,
        entry_type: :timing_changed,
        details:    "From \"#{
          format_timing(self.event_starts_at,
                        self.event_ends_at,
                        self.event_all_day)
        }\" to \"#{
          format_timing(self.event.starts_at,
                        self.event.ends_at,
                        self.event.all_day)
        }\""
      })
      anything_changed = true
    end
    if self.event_eventcategory_id != self.event.eventcategory_id
      self.journal_entries.create({
        user:       by_user,
        entry_type: :category_changed,
        details:    "From #{self.event_eventcategory.name} to #{self.event.eventcategory.name}"
      })
      anything_changed = true
    end
    if self.event_organiser_id != self.event.organiser_id
      self.journal_entries.create({
        user:       by_user,
        entry_type: :organiser_changed,
        details:    "From #{
          self.event_organiser ?  self.event_organiser.name : "<none>"
        } to #{
          self.event.organiser ? self.event.organiser.name : "<none>"
        }"
      })
      anything_changed = true
    end
    if anything_changed
      self.populate_from_event(self.event)
      self.save
    end
  end

  def event_destroyed(by_user)
    self.journal_entries.create({
      user:       by_user,
      entry_type: :event_destroyed
    })
  end

  def commitment_added(commitment, by_user)
    self.journal_entries.create({
      user:       by_user,
      entry_type: :resource_added,
      details:    commitment_description(commitment)
    })
  end

  def commitment_removed(commitment, by_user)
    self.journal_entries.create({
      user:       by_user,
      entry_type: :resource_removed,
      details:    commitment_description(commitment)
    })
  end

  private

  def commitment_description(commitment)
    "#{commitment.element.entity_type}: #{commitment.element.name}"
  end

  def format_timing(starts_at, ends_at, all_day)
    if all_day
      #
      #  Single day or multi-day?
      #
      if ends_at == starts_at + 1.day
        "All day #{starts_at.strftime("%d/%m/%Y")}"
      else
        "#{starts_at.strftime("%d/%m/%Y")} - #{(ends_at - 1.day).strftime("%d/%m/%Y")}"
      end
    else
      if starts_at.to_date == ends_at.to_date
        #
        #  Starts and ends on the same day.
        #
        "#{starts_at.interval_str(ends_at)} #{starts_at.strftime("%d/%m/%Y")}"
      else
        "#{starts_at.strftime("%H:%M %d/%m/%Y")} - #{ends_at.strftime("%H:%M %d/%m/%Y")}"
      end
    end
  end

end
