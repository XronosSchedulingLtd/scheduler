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
              :after_duration,
              :resources,
              :before_title,
              :after_title,
              :single_wrapper,
              :single_title

  #
  #  We are passed an array of strings, the last of which is empty.
  #
  def enabled_ids=(id_list)
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

  def before_title=(new_title)
    @before_title = new_title unless new_title.empty?
  end

  def after_title=(new_title)
    @after_title = new_title unless new_title.empty?
  end

  def single_title=(new_title)
    @single_title = new_title unless new_title.empty?
  end

  def wrap_before=(val)
    @wrap_before = (val == "1")
  end

  def wrap_after=(val)
    @wrap_after = (val == "1")
  end

  def single_wrapper=(val)
    @single_wrapper = (val == "1")
  end

  def wrap_before?
    @wrap_before
  end

  def wrap_after?
    @wrap_after
  end

  def single_wrapper?
    @single_wrapper
  end

  def organiser_id
    @organiser ? @organiser.id : nil
  end

  def organiser_name
    @organiser ? @organiser.name : nil
  end

  def organiser_id=(val)
    new_organiser = Element.find_by(id: val)
    if new_organiser
      @organiser = new_organiser
    end
  end

  def organiser_name=(name)
    # Ignore
  end

  def initialize(event, attributes={})
    #
    #  Set default values first.
    #
    @event           = event
    @single_wrapper  = false
    @wrap_before     = true
    @before_duration = Setting.wrapping_before_mins
    @before_title    = "Set-up for \"#{@event.body}\""
    @wrap_after      = true
    @after_title     = "Clear-up for \"#{@event.body}\""
    @single_title    = "Arrangements for \"#{@event.body}\""
    @after_duration  = Setting.wrapping_after_mins
    @eventcategory   = Setting.wrapping_eventcategory
    @organiser       = @event.organiser
    @resources = []
    #
    #  Need to see what resources the indicated event has, and
    #  set them up for a check-box listing.  Note that we are
    #  going to look at the element for each resource, not the
    #  resource itself.
    #
    @event.elements_even_tentative.sort.each do |element|
      @resources << EventResource.new(element)
    end
    super(attributes)
  end

  #
  #  Generate a hash suitable for passing to Event#clone_and_save
  #  to set the timing for the set-up event.
  #
  def before_params
    params = {}
    params[:starts_at]     = @event.starts_at - @before_duration.minutes
    params[:ends_at]       = @event.starts_at
    params[:body]          = @before_title
    params[:eventcategory] = @eventcategory if @eventcategory
    params[:organiser]     = @organiser if @organiser
    params
  end

  def after_params
    params = {}
    params[:starts_at]     = @event.ends_at
    params[:ends_at]       = @event.ends_at + @after_duration.minutes
    params[:body]          = @after_title
    params[:eventcategory] = @eventcategory if @eventcategory
    params[:organiser]     = @organiser if @organiser
    params
  end

  def single_params
    params = {}
    params[:starts_at]     = @event.starts_at - @before_duration.minutes
    params[:ends_at]       = @event.ends_at + @after_duration.minutes
    params[:body]          = @single_title
    params[:eventcategory] = @eventcategory if @eventcategory
    params[:organiser]     = @organiser if @organiser
    params
  end

end
