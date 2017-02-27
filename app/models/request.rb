class Request < ActiveRecord::Base
  belongs_to :element
  belongs_to :event
  belongs_to :proto_request

  validates :element, :presence => true
  validates :event,   :presence => true
end
