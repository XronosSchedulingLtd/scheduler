
#
#  This module exists to hold any methods relating to a proto event
#  functioning as part of the invigilation code.  It should probably
#  be moved to a separate source file once ProtoEvents start being
#  used for other purposes as well.
#
module ProtoEventInvigilationPersona

  attr_accessor :num_staff, :location_id
  attr_reader :room

  def get_location_commitment
    self.proto_commitments.find {|pc| pc.element.entity_type == "Location"}
  end

  def prepare
    @persona = :invigilation
#    if new_record?
    unless new_record?
      #
      #  Two cases here.
      #
      #  1. A brand new record.
      #  2. A dup of an existing record.
      #
#      puts "Extended a new record."
#    else
#      puts "Extended an old record."
      #
      #  What current setting do we have for the number of invigilators
      #  required?
      #
      pr = proto_requests[0]
      if pr
        #
        #  Because we apply validation to this field before we save
        #  it, we need to hold its value as a string - the same way
        #  we would receive it if it came from the front end.
        #
        #  ActiveRecord will turn it back into an integer as part
        #  of saving the record.
        #
        @num_staff = pr.quantity.to_s
      else
        #
        #  For some weird reason, the proto request is not there yet.
        #
      end
      current_location_commitment = get_location_commitment
      if current_location_commitment
        @location_id = current_location_commitment.element_id
        @room = current_location_commitment.element.name
      end
    end
  end

  def persona_specific_validation
    if self.location_id.blank?
      self.errors[:location_id] << "can't be blank"
    else
      @location_element = Element.find_by(id: location_id)
      if @location_element
        #
        #  This isn't really the right place for this, but since we
        #  have the location element to hand.
        #
        self.body = "#{@location_element.entity.name} Invigilation"
      else
        self.errors[:location_id] << "not found"
      end
    end
    if self.num_staff.blank?
      self.errors[:num_staff] << "can't be blank"
    end
    if /\A[+-]?\d+\z/ =~ self.num_staff
      if self.num_staff.to_i < 0
        self.errors[:num_staff] << "must not be negative"
      end
    else
      self.errors[:num_staff] << "must be an integer"
    end
    if self.generator
      unless self.generator.instance_of?(ExamCycle)
        self.errors[:general] << "generator must be an exam cycle"
      end
    else
      self.errors[:general] << "must have a generator"
    end
  end

  def after_create_processing
    #
    #  Validation should already have checked to ensure we have
    #  a valid generator which is an ExamCycle.
    #
    #  Use the bang version so if this fails we get an error
    #  and the create will be rolled back.
    #
    self.proto_requests.create!({
      element: self.generator.default_group_element,
      quantity: self.num_staff
    })
    property = Property.find_by(name: "Invigilation")
    if property
      self.proto_commitments.create!({
        element: property.element
      })
    end
    #
    #  @location_element is set up during validation.
    #
    self.proto_commitments.create!({
      element: @location_element
    })
    @room = @location_element.name
  end

  def after_update_processing
    pr = proto_requests[0]
    if pr
      if pr.quantity != num_staff.to_i
        pr.quantity = num_staff.to_i
        pr.save!
      end
    end
    current_location_commitment = get_location_commitment
    if current_location_commitment &&
       current_location_commitment.element_id != @location_element.id
      current_location_commitment.element = @location_element
      current_location_commitment.save!
      @room = @location_element.name
    end
  end

  def self.extended(proto_event)
    proto_event.prepare
  end
end

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
    #
    #  Now persona-specific stuff.
    #
    if record.have_persona
      record.persona_specific_validation
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
  #  Don't allow ourselves to be destroyed if we have active events.
  #
  def can_destroy?
    self.events.count == 0
  end

  #
  #  Ensure a single event, as dictated by self, a date and a rota slot.
  #
  def ensure_event(date, rota_slot, existing)
    starts_at, ends_at = rota_slot.timings_for(date)
    if existing
      event = existing
      if event.body != self.body
        event.body = self.body
        event.save
      end
    else
      event = self.events.create({
        body:          self.body,
        eventcategory: self.eventcategory,
        eventsource:   self.eventsource,
        starts_at:     starts_at,
        ends_at:       ends_at,
        source_id:     rota_slot.id})
      unless event.valid?
        Rails.logger.error("Failed to create event")
        event.errors.each do |e|
          Rails.logger.error(e)
        end
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
    self.proto_requests.each do |pr|
      pr.ensure_request(event)
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
        existing_events = self.events.events_on(date)
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
  #  Take all events on or after the given date from the donor.
  #  In order to do that, we need a mapping between the donor's
  #  ProtoRequests and ProtoCommitments and our own.  We should
  #  have got a corresponding set when our record was saved.
  #
  def take_events(donor, date)
    #
    #  Key is the donor's ProtoCommitment ID.
    #  Data is our corresponding ProtoCommitment.
    #
    pc_hash = Hash.new
    donor.proto_commitments.each do |dpc|
      opc = self.proto_commitments.detect {|pc| pc.element_id == dpc.element_id}
      if opc
        pc_hash[dpc.id] = opc
      else
        Rails.logger.error("Can't find matching proto_commitment duplicating proto_event.")
      end
    end
    #
    #  And the same for ProtoRequests.
    #
    pr_hash = Hash.new
    donor.proto_requests.each do |dpr|
      opr = self.proto_requests.detect {|pr| pr.element_id == dpr.element_id }
      if opr
        pr_hash[dpr.id] = opr
      else
        Rails.logger.error("Can't find matching proto_request duplicating proto_event.")
      end
    end
    #
    #  And now take the events.
    #
    donor.events.beginning(date).each do |e|
      e.proto_event = self
      e.save
      #
      #  Where a request or commitment attached to the event has been
      #  generated by a corresponding proto_*, then we need to update
      #  the parental reference too.
      #
      e.commitments.each do |c|
        if c.proto_commitment_id &&
           (our_pc = pc_hash[c.proto_commitment_id])
          c.proto_commitment = our_pc
          c.save
        end
      end
      e.requests.each do |r|
        if r.proto_request_id &&
           (our_pr = pr_hash[r.proto_request_id])
          r.proto_request = our_pr
          r.save
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
  #  Ah - no.  It must be strictly after the start date, but it can
  #  be the same as the end date.  That way we'd chop just one day
  #  off the end of our interval.
  #
  def split(date)
    result = nil
    if (date > self.starts_on) && (date <= self.ends_on)
      other = self.dup
      other.add_persona
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
        result = other
      else
        Rails.logger.error("Failed to save other ProtoEvent.")
      end
    else
      Rails.logger.error "Date #{date.to_s(:dmy)} is not between #{self.starts_on_text} and #{self.ends_on_text}."
    end
    result
  end

  #
  #  Meta-programming functions
  #
  after_initialize :add_persona
  after_create :after_create_processing
  after_update :after_update_processing

  def after_create_processing
    #
    #  This method does nothing, but may well be over-ridden by
    #  a persona.
    #
  end

  def after_update_processing
    #
    #  This method does nothing, but may well be over-ridden by
    #  a persona.
    #
  end

  def have_persona
    #
    #  Want to coerce this into returning just true and false.
    #  @have_persona itself may be nil.
    #
    @have_persona ? true : false
  end

  def persona
    @persona
  end

  def introspect
    puts "Inspecting"
    puts self.inspect
    puts @persona_hash.inspect
    puts "Inspected"
  end

  PERSONAE_BY_GENERATOR = {
    "ExamCycle" => ProtoEventInvigilationPersona
  }

  PERSONAE_BY_NAME = {
    "Invigilation" => ProtoEventInvigilationPersona
  }

  #
  #  This function is called after initialisation.  It should by now be
  #  possible to tell what kind of persona we have - we must have one -
  #  and thus to pass it any additional parameters.
  #
  def add_persona
    persona = PERSONAE_BY_GENERATOR[self.generator_type]
    #
    #  It's just possible that a caller might want to create a ProtoEvent
    #  without doing it through its generator.  The usual way to create
    #  one is with something like:
    #
    #    exam_cycle.proto_events.create({ ...hash... })
    #
    #  and that will work fine with the line above.  It is however just
    #  possible that someone might want to create one and then assign
    #  it to its generator later.  Allow the persona type to be specified
    #  as a parameter.
    #
    if @persona_hash && (persona_name = @persona_hash[:persona])
      @persona_hash.except!(:persona)
      persona = PERSONAE_BY_NAME[persona_name]
    end
    if persona
      self.extend persona
      @have_persona = true
      #
      #  Now need to pass in all the assignments saved earlier.
      #  If one of them doesn't work, it should raise an error as before.
      #
      if @persona_hash
        @persona_hash.each do |key, value|
          self.send("#{key}=", value)
        end
      end
    else
      raise ArgumentError, "proto_event must have a known generator_type #{self.generator_type}"
    end
  end

  #
  #  It would appear that this function is called only if we create a
  #  new record in memory.  It is *not* called when you load one from
  #  the database.
  #
  def initialize(*args)
    puts "In initialize"
    @have_persona = false
    @persona_hash = {}
    super
  end

  alias_method :really_respond_to?, :respond_to?

  def method_missing(method_sym, *arguments, &block)
    #
    #  How we behave depends on whether or not we have already mixed
    #  in our persona module.  If we've already mixed in our persona
    #  then there's nothing more we can do.
    #
    if @have_persona
      super
    else
      #
      #  Don't yet know what our persona is, so need to be able to
      #  store assignments to be handled later.  This code exists
      #  to cope with calls on new() and create() where all the
      #  parameters are passed in one go and we don't know the
      #  order in which they'll be processed.
      #
      #  We won't know until we get our persona what assignments we
      #  can actually cope with.  We attempt to cope with assignments
      #  only.
      #
      if self.really_respond_to?(method_sym)
        super
      else
        if method_sym.to_s =~ /=$/
          @persona_hash[method_sym.to_s.chomp("=").to_sym] = arguments.first
        else
          super
        end
      end
    end
  end

  #
  #  This is slightly tricky - we don't know until we get our persona.
  #
  def respond_to?(method_sym, include_private = false)
    if @have_persona
      super
    else
      if super
        true
      else
        if method_sym.to_s =~ /=$/
          true
        else
          false
        end
      end
    end
  end

end
