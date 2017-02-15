class ProtoCommitment < ActiveRecord::Base
  belongs_to :proto_event
  belongs_to :element

  validates :proto_event, :presence => true
  validates :element,     :presence => true
end
