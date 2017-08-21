# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class JournalEntry < ActiveRecord::Base
  enum entry_type: [
    :event_created,
    :event_destroyed,
    :body_text_changed,
    :timing_changed,
    :category_changed,
    :organiser_changed,
    :resource_added,
    :resource_removed,
    :resource_approved,
    :resource_denied
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
    "Resource approved",
    "Resource denied"
  ]
  belongs_to :journal
  belongs_to :user

  validates :journal, presence: true

  def entry_type_text
    NEATER_TEXTS[JournalEntry.entry_types[entry_type]] || ""
  end
end
