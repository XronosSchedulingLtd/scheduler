class EventCloner

  class EventInstance

    include ActiveModel::Model

    attr_accessor :body

    attr_reader :index

    def initialize(date, body, index)
      @index = index
      @date  = date
      @body  = body
    end

    def date
      @date.to_s(:dmy)
    end

    def date=(new_date)
    end

    #
    #  Produce some parameters to pass to Event#clone_and_save
    #  to suit this instance.
    #
    def cloning_params(event)
      params = {}
      starts_at, ends_at = event.timings_on(@date)
      params[:starts_at]     = starts_at
      params[:ends_at]       = ends_at
      params[:body]          = @body
      params
    end

    def self.from_event(event, index)
      EventInstance.new(event.starts_at.to_date, event.body, index)
    end

  end

  include ActiveModel::Model

  INITIAL_NUM_INSTANCES = 2

  attr_accessor :event

  attr_reader :wrap_before,
              :before_duration,
              :wrap_after,
              :after_duration,
              :resources,
              :before_title,
              :after_title

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
  def original_date
    @event.starts_at.to_s(:dmy)
  end

  def original_description
    @event.body
  end

  def instances
    @instances
  end

  def instances=(new_instances)
    raise "instances= called with #{new_instances.inspect}"
  end

  def num_instances
    @instances.count
  end

  def initialize(event, params = nil)
    #
    #  Set default values first.
    #
    @event           = event
    @instances = []
    if params && instance_params = params[:event_cloner_event_instance]
#      raise params[:event_cloner_event_instance].inspect
      instance_params.each do |key, data|
        date = data[:date].to_date
        body = data[:body]
        unless body.blank?
          @instances << EventInstance.new(date, body, key)
        end
      end
    else
      #
      #  A new, blank cloner object.
      #
      @instances = []
      INITIAL_NUM_INSTANCES.times do |i|
        @instances << EventInstance.from_event(event, i)
      end
    end
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
end
