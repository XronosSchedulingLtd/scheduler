class ProtoEvent < ActiveRecord::Base
  belongs_to :eventcategory
  belongs_to :eventsource
  has_many :proto_commitments, :dependent => :destroy
  has_many :proto_requests, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :elements, :through => :proto_commitments

  #
  #  We don't really *belong* to the rota_template, but we point at
  #  it so this is how ActiveRecord phrases it.
  #
  belongs_to :rota_template
  belongs_to :generator, :polymorphic => true

  def resources
    self.elements.collect {|e| e.entity}
  end

  def locations
    self.resources.select {|r| r.instance_of?(Location)}
  end

  #
  #  The first use of ProtoEvents is to provide exam invigilation stuff.
  #  As such, the client end wants to see room information.
  #
  def room
    l = locations[0]
    if l
      l.name
    else
      ""
    end
  end

  #
  #  And the name of the template in use.
  #
  def rota_template_name
    self.rota_template ? self.rota_template.name : ""
  end

  def starts_on_text
    self.starts_on ? self.starts_on.to_s(:dmy) : ""
  end

  def ends_on_text
    self.ends_on ? self.ends_on.to_s(:dmy) : ""
  end

  def event_count
    self.events.count
  end

end
