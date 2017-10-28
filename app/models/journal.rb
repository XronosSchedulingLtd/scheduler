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

  self.per_page = 18

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

  def event_created(by_user, cloned)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: cloned ? :clone_created : :event_created,
      details:    "\"#{
                      self.event_body
                    }\"\n#{
                      self.format_timing
                    }#{
                      if self.event_organiser
                        "\nOrganiser: #{self.event_organiser.name}"
                      else
                        ""
                      end
                    }#{
                      if self.event_organiser_ref.blank?
                        ""
                      else
                        "\nReference: #{self.event_organiser_ref}"
                      end
                    }"
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
        event:      self.event,
        user:       by_user,
        entry_type: :body_text_changed,
        details:    "From: \"#{self.event_body}\"\nTo: \"#{self.event.body}\""
      })
      anything_changed = true
    end
    if self.event_starts_at != self.event.starts_at ||
      self.event_ends_at != self.event.ends_at ||
      self.event_all_day != self.event.all_day
      self.journal_entries.create({
        event:      self.event,
        user:       by_user,
        entry_type: :timing_changed,
        details:    "From: \"#{
          self.format_timing
        }\"\nTo: \"#{
          self.event.format_timing
        }\""
      })
      anything_changed = true
    end
    if self.event_eventcategory_id != self.event.eventcategory_id
      self.journal_entries.create({
        event:      self.event,
        user:       by_user,
        entry_type: :category_changed,
        details:    "From: #{self.event_eventcategory.name}\nTo: #{self.event.eventcategory.name}"
      })
      anything_changed = true
    end
    if self.event_organiser_id != self.event.organiser_id
      self.journal_entries.create({
        event:      self.event,
        user:       by_user,
        entry_type: :organiser_changed,
        details:    "From: #{
          self.event_organiser ?  self.event_organiser.name : "<none>"
        }\nTo: #{
          self.event.organiser ? self.event.organiser.name : "<none>"
        }"
      })
      anything_changed = true
    end
    if self.event_organiser_ref != self.event.organiser_ref
      self.journal_entries.create({
        event:      self.event,
        user:       by_user,
        entry_type: :organiser_reference_changed,
        details:    "From: #{self.event_organiser_ref}\nTo: #{self.event.organiser_ref}"
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
      event:      self.event,
      user:       by_user,
      entry_type: :event_destroyed
    })
  end

  def commitment_added(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :resource_added,
      element:    commitment.element,
      details:    commitment_description(:resource_added, commitment)
    })
  end

  def commitment_removed(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :resource_removed,
      element:    commitment.element,
      details:    commitment_description(:resource_removed, commitment)
    })
  end

  def commitment_approved(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :commitment_approved,
      element:    commitment.element,
      details:    commitment_description(:commitment_approved, commitment)
    })
  end

  def commitment_rejected(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :commitment_rejected,
      element:    commitment.element,
      details:    commitment_description(:commitment_rejected, commitment)
    })
  end

  def commitment_noted(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :commitment_noted,
      element:    commitment.element,
      details:    commitment_description(:commitment_noted, commitment)
    })
  end

  def commitment_reset(commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :commitment_reset,
      element:    commitment.element,
      details:    commitment_description(:commitment_reset, commitment)
    })
  end

  def note_added(note, commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :note_added,
      element:    commitment ? commitment.element : nil
    })
  end

  def note_updated(note, commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :note_updated,
      element:    commitment ? commitment.element : nil,
      details:    commitment ?
                  "Relating to #{commitment.element.name}" :
                  ""
    })
  end

  def form_completed(ufr, commitment, by_user)
    self.journal_entries.create({
      event:      self.event,
      user:       by_user,
      entry_type: :form_completed,
      element:    commitment ? commitment.element : nil
    })
  end

  def format_timing
    format_timings(self.event_starts_at, self.event_ends_at, self.event_all_day)
  end

  private

  def commitment_description(entry_type, commitment)
    if entry_type == :resource_added && commitment.tentative?
      "Needs approval"
    elsif entry_type == :commitment_rejected
      "Reason: #{commitment.reason}"
    else
      ""
    end
  end

end
