class EventWrapper

  class EventResource
    attr_accessor :enabled, :name, :element_id

    def initialize(element)
      @name       = element.name
      if element.entity_type == "Staff" ||
         element.entity_type == "Location"
        @enabled = true
      else
        @enabled = false
      end
      @element_id = element.id
    end

    def to_partial_path
      "event_resource"
    end
  end

  include ActiveModel::Model

  attr_accessor :event,
                :wrap_before,
                :before_duration,
                :wrap_after,
                :after_duration

  attr_reader :resources

  def initialize(attributes={})
    #
    #  Set default values first.
    #
    self.wrap_before     = true
    self.before_duration = 60           # Minutes
    self.wrap_after      = true
    self.after_duration  = 30           # Minutes
    @resources = []
    super
    if self.event
      #
      #  Need to see what resources the indicated event has, and
      #  set them up for a check-box listing.  Note that we are
      #  going to look at the element for each resource, not the
      #  resource itself.
      #
      self.event.elements.sort.each do |element|
        self.resources << EventResource.new(element)
      end
    else
      raise "Can't have an event wrapper without an event."
    end
  end

  def enabled_ids
    @resources.select {|r| r.enabled}.collect {|r| r.element_id}
  end

end
