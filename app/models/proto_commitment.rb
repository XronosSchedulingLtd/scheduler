class ProtoCommitment < ActiveRecord::Base
  belongs_to :proto_event
  belongs_to :element
end
