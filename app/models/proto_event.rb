
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

  validates :body, :presence => true
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

  #
  #  Ensure a single event, as dictated by self, a date and a rota slot.
  #
  def ensure_event(date, rota_slot, existing)
    starts_at, ends_at = rota_slot.timings_for(date)
    if existing
      Rails.logger.debug("Event already exists")
      event = existing
    else
      if event = self.events.create({
        body:          self.body,
        eventcategory: self.eventcategory,
        eventsource:   self.eventsource,
        starts_at:     starts_at,
        ends_at:       ends_at,
        source_id:     rota_slot.id})
        Rails.logger.debug("Created event")
      else
        Rails.logger.debug("Failed to create")
      end
    end
    #
    #  And now make sure it has the right commitments and requests.
    #  Note that it may well have required other commitments over
    #  and above those which we provided - we're not interested
    #  in them, and leave them alone.
    #
    #  Currently we don't delete commitments which we have created
    #  but which have now lost the corresponding proto_commitment.
    #
    self.proto_commitments.each do |pc|
      pc.ensure_commitment(event)
    end
  end

  #
  #  Quite a powerful method.  Uses our rota template as a guide
  #  and creates/deletes events attached to this proto_event as
  #  appropriate.
  #
  #  We work out what events we want, then add or delete as needed.
  #  We never delete an existing event if it still meets our new
  #  requirements.
  #
  #  We check that we are linked to a rota template because although
  #  the model contains a validation requiring one, it's possible it
  #  has subsequently been deleted and thus we can't continue.
  #
  def ensure_required_events
    if self.rota_template
      self.starts_on.upto(self.ends_on) do |date|
        puts date.to_s(:dmy)
        existing_events = self.events.events_on(date)
        puts "#{existing_events.count} existing events."
        self.rota_template.slots_for(date) do |slot|
          existing = existing_events.detect {|e| e.source_id == slot.id}
          ensure_event(date, slot, existing)
          if existing
            existing_events = existing_events - [existing]
          end
        end
        #
        #  Any events left in the existing_events array must be no
        #  longer required.
        #
        existing_events.each do |e|
          e.destroy
        end
      end
      #
      #  It's possible that our start or end date has changed and there
      #  are events in the d/b either before our new start date or
      #  after our new end date.  Those need to go too.
      #
      too_earlies = self.events.before(self.starts_on)
      too_earlies.each do |e|
        e.destroy
      end
      too_lates = self.events.after(self.ends_on)
      too_lates.each do |e|
        e.destroy
      end
    else
      #
      #  Raise an error, or just log it?
      #
    end
  end

  #
  #  Take all events on or after the given date from the donor.  Before
  #  we do that, we need to set up our own ProtoCommitments and ProtoRequests
  #  to match the donor's.
  #
  def take_events(donor, date)
    #
    #  Key is the donor's ProtoCommitment ID.
    #  Data is our corresponding ProtoCommitment.
    #
    pc_hash = Hash.new
    donor.proto_commitments.each do |pc|
      pc_hash[pc.id] = self.proto_commitments.new({
        proto_event: self,
        element:     pc.element
      })
    end
    #
    #  And now take the events.
    #
    donor.events.beginning(date).each do |e|
      e.proto_event = self
      e.save
      e.commitments.each do |c|
        if c.proto_commitment_id &&
           (our_pc = pc_hash[c.proto_commitment_id])
          c.proto_commitment = our_pc
          c.save
        end
      end
    end
  end

  #
  #  Split a ProtoEvent and all its attached events into this one and
  #  another one starting on the indicated date.  All sub-structures need
  #  to be handled too.
  #
  #  date must lie strictly between our two existing dates.
  #
  def split(date)
    if (date > self.starts_on) && (date < self.ends_on)
      other = self.dup
      other.starts_on = date
      if other.save
        self.ends_on = date - 1.day
        self.save
        #
        #  Now need to duplicate all ProtoCommitments and ProtoRequests
        #  and move over any existing events.  All Commitments and Requests
        #  attached to those events need to be moved to our new
        #  corresponding ProtoCommitments and ProtoRequests.
        #
        other.take_events(self, date)
      else
        Rails.logger.error("Failed to save other ProtoEvent.")
      end
    else
      raise "Date #{date.to_s(:dmy)} is not between #{self.starts_on_text} and #{self.ends_on_text}."
    end
  end
end
