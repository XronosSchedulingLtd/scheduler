class ProtoCommitment < ActiveRecord::Base
  belongs_to :proto_event
  belongs_to :element

  has_many :commitments, :dependent => :nullify

  validates :proto_event, :presence => true
  validates :element,     :presence => true

  def ensure_commitment(event)
    #
    #  We can find our commitment by either event.commitments or
    #  self.commitments, but we want the intersection of those
    #  two sets.  I don't think there's any way of combining like
    #  that in ActiveRecord, so resort to doing it ourselves.
    #
    existing =
      Commitment.find_by(
        event_id: event.id,
        proto_commitment_id: self.id)
    if existing
      unless existing.element_id == self.element_id
        existing.element_id = self.element_id
        existing.save
      end
    else
      self.commitments.create({
        event: event,
        element: self.element
      })
    end
  end

end
