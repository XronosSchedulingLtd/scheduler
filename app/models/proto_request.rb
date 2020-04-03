#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class ProtoRequest < ApplicationRecord
  belongs_to :element
  belongs_to :proto_event

  has_many :requests, :dependent => :nullify

  def ensure_request(event)
    #
    #  We can find our request by either event.requests or
    #  self.requests, but we want the intersection of those
    #  two sets.  I don't think there's any way of combining like
    #  that in ActiveRecord, so resort to doing it ourselves.
    #
    existing =
      Request.find_by(
        event_id: event.id,
        proto_request_id: self.id)
    if existing
      modified = false
      unless existing.element_id == self.element_id
        existing.element_id = self.element_id
        modified = true
      end
      #
      #  Under certain circumstances we can update the quantity too.
      #
      #  Essentially we're trying to do it if the actual request
      #  has not yet started being fulfilled.  Tests are:
      #
      #  * Existing request quantity != 0
      #    (Implying the user has already said he doesn't want anyone here.)
      #  * No existing commitments fulfilling the request
      #    (Implying the user has started allocating.)
      #
      if existing.quantity != self.quantity
        if existing.quantity != 0 &&
           existing.commitments.count == 0
          existing.quantity = self.quantity
          modified = true
        end
      end
      if modified
        existing.save
      end
    else
      self.requests.create({
        event: event,
        element: self.element,
        quantity: self.quantity
      })
    end
  end
end
