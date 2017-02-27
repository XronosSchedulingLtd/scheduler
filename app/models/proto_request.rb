class ProtoRequest < ActiveRecord::Base
  belongs_to :element
  belongs_to :proto_event

  has_many :requests, :dependent => :nullify

  validates :element,     :presence => true
  validates :proto_event, :presence => true

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
      #  It's tempting at this point to update the quantity field too,
      #  but that would break the principle that re-generation is safe.
      #  The user may well have modified that value on existing events,
      #  and we don't want to lose that information.
      #
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
