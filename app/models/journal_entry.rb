#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class JournalEntry < ApplicationRecord
  enum entry_type: [
    :event_created,
    :event_destroyed,
    :body_text_changed,
    :timing_changed,
    :category_changed,
    :organiser_changed,
    :resource_added,
    :resource_removed,
    :commitment_approved,
    :commitment_rejected,
    :commitment_reset,
    :note_added,
    :note_updated,
    :clone_created,
    :event_relocated,
    :organiser_reference_changed,
    :form_completed,
    :commitment_noted,
    :wrapper_created,
    :repeat_created,
    :repeated_from,
    :resource_request_created,
    :resource_request_destroyed,
    :resource_request_incremented,
    :resource_request_decremented,
    :resource_request_allocated,
    :resource_request_deallocated,
    :resource_request_reconfirmed,
    :resource_request_adjusted
  ]
  NEATER_TEXTS = [
    "Event created",
    "Event deleted",
    "Description changed",
    "Timing changed",
    "Category changed",
    "Organiser changed",
    "Resource added",
    "Resource removed",
    "Commitment approved",
    "Commitment rejected",
    "Commitment reset",
    "Note added",
    "Note updated",
    "Created as clone",
    "Event re-located",
    "Reference changed",
    "Form completed",
    "Request noted",
    "Created as wrapper",
    "Created as repeat",
    "Used as model for repeating events",
    "Resource request created",
    "Resource request deleted",
    "Resource request incremented",
    "Resource request decremented",
    "Resource allocated",
    "Resource deallocated",
    "Resource request reconfirmed",
    "Resource request quantity changed"
  ]
  ELEMENT_TEXTS = {
    resource_added:      "Added",
    resource_removed:    "Removed",
    commitment_approved: "Approved",
    commitment_rejected: "Rejected",
    commitment_reset:    "Reset",
    note_updated:        "Note updated",
    form_completed:      "Form completed",
    commitment_noted:    "Request noted"
  }
  ELEMENT_TEXTS.default = "Other"

  belongs_to :journal
  belongs_to :user
  belongs_to :element, optional: true

  self.per_page = 15

  def entry_type_text
    NEATER_TEXTS[JournalEntry.entry_types[entry_type]] || ""
  end

  def element_entry_type_text
    ELEMENT_TEXTS[entry_type.to_sym]
  end

  def when
    self.created_at.strftime("%d/%m/%Y %H:%M:%S")
  end

  def what
    if self.element
      self.element.short_name
    else
      ""
    end
  end

  #
  #  When we are created we get assigned an event.  We don't actually
  #  link to it directly (since we can access it through our parent
  #  Journal record) but we do copy some information from it so we
  #  have a snapshot of how it was at the time we were created.
  #
  def event=(event)
    self.event_starts_at = event.starts_at
    self.event_ends_at   = event.ends_at
    self.event_all_day   = event.all_day
  end
end
