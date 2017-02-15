
class ProtoEventValidator < ActiveModel::Validator
  def validate(record)
    unless record[:starts_on].instance_of?(Date)
      #
      #  Don't seem to have a start date.  Has any useful attempt
      #  been made?
      #
      if record.org_starts_on.blank?
        record.errors[:starts_on] << "can't be blank"
      else
        record.errors[:starts_on] << "don't understand #{record.org_starts_on}"
      end
    end
    unless record[:ends_on].instance_of?(Date)
      #
      #  Don't seem to have an end date.  Has any useful attempt
      #  been made?
      #
      if record.org_ends_on.blank?
        record.errors[:ends_on] << "can't be blank"
      else
        record.errors[:ends_on] << "don't understand #{record.org_ends_on}"
      end
    end
    if record[:starts_on] && record[:ends_on]
      unless record[:starts_on] <= record[:ends_on]
        record.errors[:ends_on] << "can't be before start date"
      end
    end
  end
end


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

  validates :rota_template, :presence => true
  validates_with ProtoEventValidator

  attr_reader :org_starts_on, :org_ends_on

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
      l.element_name
    else
      ""
    end
  end

  def get_location_commitment
    self.proto_commitments.find {|pc| pc.element.entity_type == "Location"}
  end

  def location_id
    lc = get_location_commitment
    if lc
      lc.element_id
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

  def starts_on_text=(value)
    @org_starts_on = value
    self.starts_on = Date.safe_parse(value)
  end

  def ends_on_text=(value)
    @org_ends_on = value
    self.ends_on = Date.safe_parse(value)
  end

  def event_count
    self.events.count
  end

  #
  #  Like a normal save, but will also add a location as a proto_commitment.
  #
  def save_with_location(location_id)
    #
    #  Check first whether we have a meaningful location id
    #  and it points to a real location.  If not, then don't attempt
    #  the save, but add an error to the relevant field.
    #
    if location_id
      #
      #  This is actually the ID of the location's element.
      #
      location_element = Element.find_by(id: location_id)
      if location_element
        #
        #  Go for it.
        #
        if self.save
          self.proto_commitments.create({element: location_element})
          return true
        end
      else
        self.errors[:location] = "not found"
      end
    else
      self.errors[:location] = "can't be blank"
    end
    return false
  end

  def update_with_location(params, new_location_id)
    #
    #  The location ID as received is liable to be a string, but
    #  the ActiveRecord find methods can cope with this.
    #
    if new_location_id
      new_location_element = Element.find_by(id: new_location_id)
      if new_location_element
        #
        #  OK - we have the proposed new location (which may be
        #  the same as it was before) so we are reasonably
        #  confident we can apply that update (if indeed it is one).
        #
        if self.update(params)
          #
          #  That worked.  Just do the location too.
          #
          current_location_commitment = get_location_commitment
          if current_location_commitment
            if current_location_commitment.element_id != new_location_element.id
              current_location_commitment.element = new_location_element
              current_location_commitment.save
            end
          else
            #
            #  Slightly odd that we don't already have it, but...
            #
            self.proto_commitments.create({element: new_location_element})
          end
          return true
        end
      else
        self.errors[:location] = "not found"
      end
    else
      self.errors[:location] = "can't be blank"
    end
    return false
  end

end
