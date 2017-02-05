class ProtoEvent < ActiveRecord::Base
  belongs_to :eventcategory
  belongs_to :eventsource
  has_many :proto_commitment, :dependent => :destroy
  has_many :proto_request, :dependent => :destroy
  #
  #  We don't really *belong* to the rota_template, but we point at
  #  it so this is how ActiveRecord phrases it.
  #
  belongs_to :rota_template
  belongs_to :generator, :polymorphic => true
end
