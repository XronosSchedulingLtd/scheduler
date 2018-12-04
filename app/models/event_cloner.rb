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

  INITIAL_NUM_INSTANCES = 1

  attr_accessor :event

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
      instance_params.each do |key, data|
        date = data[:date]
        body = data[:body]
        unless body.blank? || date.blank?
          @instances << EventInstance.new(date.to_date, body, key)
        end
      end
    else
      #
      #  A new, blank cloner object.
      #
      INITIAL_NUM_INSTANCES.times do |i|
        @instances << EventInstance.from_event(event, i)
      end
    end
  end

end
