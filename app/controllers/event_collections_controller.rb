# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class EventCollectionsController < ApplicationController
  
  before_action :set_event, except: [:index, :destroy, :show, :reset]

  # GET /events/1/repeats/new
  #
  # Allows the user to create a repeating record for the indicated
  # event.
  #
  def new
    if current_user.can_repeat?(@event)
      week_letter = WeekIdentifier.week_letter(@event.starts_at.to_date)
      if week_letter == " "
        #
        #  A holiday day.
        #
        weeks = ["A", "B", " "]
      else
        weeks = ["A", "B"]
      end
      @event_collection = EventCollection.new({
        era:                    Setting.current_era,
        repetition_start_date:  @event.starts_at.to_date,
        repetition_end_date:    @event.starts_at.to_date + 3.months,
        pre_select:             @event.starts_at.to_date.wday,
        weeks:                  weeks
      })
      @action_button_text = "Create"
      respond_to do |format|
        format.html do
          if request.xhr?
            @minimal = true
            render :layout => false
          else
            @minimal = false
            render
          end
        end
        format.js do
          @minimal = true
          render
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render 'not_permitted' }
      end
    end
  end

  def create
    #raise params.inspect
    try_again = false
    @event_collection = EventCollection.new(event_collection_params)
    if EventRepeater.would_have_events?(@event_collection)
      if params[:commit] == "Check"
        try_again = true
        #
        #  The user has asked not to do the actual event propagation
        #  but to check whether it would cause clashes for any resources
        #  which he or she owns.
        #
        @clashes =
          ClashDetector.new(@event_collection, @event, current_user).
                        detect_clashes
      else
        if @event_collection.save
          @event_collection.events << @event
          request_notifier = RequestNotifier.new(@event.body)
          EventRepeater.effect_repetition(current_user,
                                          @event_collection,
                                          @event) do |action, item|
            #
            #  The only action which makes any sense here is :added.
            #
            if action == :added
              case item
              when Commitment
                set_appropriate_approval_status(item)
                request_notifier.batch_commitment_added(item)
              when Request
                request_notifier.batch_request_added(item)
              end
            end
          end
          request_notifier.send_batch_notifications(current_user)
        else
          try_again = true
        end
      end
    else
      @event_collection.errors[:base] <<
        "The specified criteria would result in no events at all - not even this one."
      try_again = true
    end
    if try_again
      respond_to do |format|
        format.js do
          @minimal            = true
          @action_button_text = "Create"
          render :new
        end
      end
    end
  end

  def edit
    if current_user.can_repeat?(@event) &&
      @event.event_collection
      @event_collection = @event.event_collection
      @action_button_text = "Update"
      respond_to do |format|
        format.html do
          if request.xhr?
            @minimal = true
            render :layout => false
          else
            @minimal = false
            render
          end
        end
        format.js do
          @minimal = true
          render
        end
      end

    else
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render 'not_permitted' }
      end
    end
  end

  def update
    #raise params.inspect
    if current_user.can_repeat?(@event)
      @event_collection = EventCollection.find(params[:id])
      try_again = false
      if params[:commit] == "Check"
        try_again = true
        #
        #  The user has asked not to do the actual event propagation
        #  but to check whether it would cause clashes for any resources
        #  which he or she owns.
        #
        @clashes =
          ClashDetector.new(@event_collection, @event, current_user).
                        detect_clashes
      else
        if @event_collection.safe_update(event_collection_params)
          if EventRepeater.would_have_events?(@event_collection)
            request_notifier = RequestNotifier.new(@event.body)
            EventRepeater.effect_repetition(current_user,
                                            @event_collection,
                                            @event) do |action, item|
              #
              #  As we're updating, we may get add, adjust or remove.
              #
              case action

              when :added
                case item
                when Commitment
                  set_appropriate_approval_status(item)
                  request_notifier.batch_commitment_added(item)
                when Request
                  request_notifier.batch_request_added(item)
                end

              when :adjusted
                if item.instance_of?(Request)
                  request_notifier.batch_request_amended(item)
                end

              when :removed
                case item
                when Commitment
                  request_notifier.batch_commitment_removed(item)
                when Request
                  request_notifier.batch_request_removed(item)
                end
              end

            end
            request_notifier.send_batch_notifications(current_user)
          else
            @event_collection.errors[:base] <<
              "The specified criteria would result in no events at all - not even this one."
            try_again = true
          end
        else
          try_again = true
        end
      end
      if try_again
        respond_to do |format|
          format.js do
            @minimal            = true
            @action_button_text = "Update"
            render :edit
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render 'not_permitted' }
      end
    end
  end

  def destroy
    #
    #  Use find_by, because this is optional.
    #
    @event = Event.find_by(id: params[:event_id])
    if admin_user? || (@event && current_user.can_repeat?(@event))
      @event_collection = EventCollection.find(params[:id])
      if @event_collection
        if @event
          general_title = @event.body
        else
          event = @event_collection.events.first
          if event
            general_title = event.body
          else
            general_title = "<No events>"
          end
        end
        request_notifier = RequestNotifier.new(general_title)
        #
        #  The relationship between event_collection and events used
        #  to be :destroy, but it's now :nullify, because we want the
        #  option to journal the event's destruction, and the possibility
        #  of dissolving a collection - making each event stand on
        #  its own.
        #
        #  This does mean that we need to make the destruction of the
        #  child events explicit when we are really intending to get
        #  rid of them.
        #
        @event_collection.events.each do |event|
          event.journal_event_destroyed(current_user)
          event.commitments.each do |c|
            request_notifier.batch_commitment_removed(c)
          end
          event.requests.each do |r|
            request_notifier.batch_request_removed(r)
          end
          event.destroy
        end
        request_notifier.send_batch_notifications(current_user)
        #
        #  And now the collection itself.
        #
        @event_collection.destroy
      end
    end
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.js
    end
  end

  #
  #  Provide a listing of repeating events for the benefit of a system
  #  admin.
  #
  def index
    if admin_user?
      @event_collections =
        EventCollection.order(updated_at: :desc).page(params[:page])
    else
      redirect_to :root
    end
  end

  def show
    if admin_user?
      @event_collection = EventCollection.find(params[:id])
    else
      redirect_to :root
    end
  end

  def reset
    if admin_user?
      @event_collection = EventCollection.find(params[:id])
      @event_collection.reset
      redirect_back fallback_location: root_path
    else
      redirect_to :root
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.create_events?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:event_id])
  end

  def event_collection_params
    params.require(:event_collection).
           permit(:era_id,
                  :repetition_start_date,
                  :repetition_end_date,
                  :when_in_month,
                  :preserve_earlier,
                  :preserve_later,
                  :preserve_historical,
                  weeks: [],
                  days_of_week: [])
  end

  #
  #  Although within the class and thus with access to @event_collection
  #  and current_user, we'll pass them in as parameters so that this
  #  function could be hoiked off elsewhere at a later date.
  #
  #  Returns an array of objects, each describing collections
  def assemble_clashes(event_collection, user)
  end

end
