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
        repetition_end_date:    Setting.current_era.ends_on,
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
    @event_collection = EventCollection.new(event_collection_params)
    if @event_collection.save
      @event_collection.events << @event
      request_notifier = RequestNotifier.new(@event.body)
      EventRepeater.effect_repetition(current_user,
                                      @event_collection,
                                      @event) do |action, item|
        #
        #  The only action which makes any sense here is :added.
        #
        if action == :added && item.instance_of?(Commitment)
          set_appropriate_approval_status(item)
          request_notifier.batch_commitment_added(item)
        end
      end
      request_notifier.send_batch_notifications(current_user)
    else
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
    if current_user.can_repeat?(@event)
      @event_collection = EventCollection.find(params[:id])
      if @event_collection.safe_update(event_collection_params)
        request_notifier = RequestNotifier.new(@event.body)
        EventRepeater.effect_repetition(current_user,
                                        @event_collection,
                                        @event) do |action, item|
          #
          #  As we're updating, we may get both adds and removes.
          #
          case action

          when :added
            if item.instance_of?(Commitment)
              set_appropriate_approval_status(item)
              request_notifier.batch_commitment_added(item)
            end

          when :removed
            if item.instance_of?(Commitment)
              request_notifier.batch_commitment_removed(item)
            end
          end

        end
        request_notifier.send_batch_notifications(current_user)
      else
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
            general_title = @event.body
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
      format.html { redirect_to :back }
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
      redirect_to :back
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
                  :starts_on_text,
                  :ends_on_text,
                  :when_in_month,
                  weeks: [],
                  days_of_week: [])
  end
end
