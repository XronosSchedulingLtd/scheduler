class ProtoRequest < ActiveRecord::Base
  belongs_to :element
  belongs_to :proto_event
end
