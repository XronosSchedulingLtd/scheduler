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

  attr_accessor :event

  attr_reader :wrap_before,
              :before_duration,
              :wrap_after,
              :after_duration

  attr_reader :resources

  #
  #  We are passed an array of strings, the last of which is empty.
  #
  def enabled_ids=(id_list)
    Rails.logger.debug("enabled_ids= called with #{id_list.inspect}")
    @resources.each do |r|
      r.enabled = false
    end
    id_list.each do |id|
      unless id.empty?
        value = id.to_i
        if value != 0
          resource = @resources.detect {|r| r.element_id == value}
          if resource
            resource.enabled = true
          end
        end
      end
    end
  end

  def enabled_ids
    @resources.select {|r| r.enabled}.collect {|r| r.element_id}
  end

  #
  #  Normally, ActiveRecord would do all this work for us.
  #
  def before_duration=(val)
    @before_duration = val.to_i
  end

  def after_duration=(val)
    @after_duration = val.to_i
  end

  def wrap_before=(val)
    @wrap_before = (val == "1")
  end

  def wrap_after=(val)
    @wrap_after = (val == "1")
  end

  def wrap_before?
    @wrap_before
  end

  def wrap_after?
    @wrap_after
  end

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
      self.event.elements_even_tentative.sort.each do |element|
        @resources << EventResource.new(element)
      end
    else
      raise "Can't have an event wrapper without an event."
    end
  end

  #
  #  Generate a hash suitable for passing to Event#clone_and_save
  #  to set the timing for the set-up event.
  #
  def before_timing
    starts_at = @event.starts_at - @before_duration.minutes
    ends_at   = @event.starts_at
    return {
      starts_at: starts_at,
      ends_at: ends_at
    }
  end

  def after_timing
    starts_at = @event.ends_at
    ends_at   = @event.ends_at + @after_duration.minutes
    return {
      starts_at: starts_at,
      ends_at: ends_at
    }
  end
end
