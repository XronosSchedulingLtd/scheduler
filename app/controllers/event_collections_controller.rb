# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class EventCollectionsController < ApplicationController
  before_action :set_event

  # GET /events/1/repeats/new
  #
  # Allows the user to create a repeating record for the indicated
  # event.
  #
  def new
    if current_user.can_subedit?(@event)
      @event_collection = EventCollection.new({
        era:                    Setting.current_era,
        repetition_start_date:  @event.starts_at.to_date,
        repetition_end_date:    Setting.current_era.ends_on
      })
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
    else
      respond_to do |format|
        format.js do
          @minimal = true
          render :new
        end
      end
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
                  :weeks,
                  :when_in_month,
                  enabled_days: [])
  end
end
