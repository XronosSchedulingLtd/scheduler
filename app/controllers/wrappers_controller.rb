# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class WrappersController < ApplicationController
  before_action :set_event

  # GET /events/1/wrappers/new
  #
  # Allows the user to create new events around an existing one.
  # Intended to be used for set-up and tear-down time.
  #
  def new
    if current_user.can_subedit?(@event)
      session[:request_notifier] = RequestNotifier.new
      @event_wrapper = EventWrapper.new(@event)
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
    @event_wrapper = EventWrapper.new(@event, wrapper_params)
    base_params = {
      owner:     current_user,
      eventsource: Eventsource.find_by(name: "Manual")
    }
    Rails.logger.debug("Wrapping.  Enabled IDs are: #{@event_wrapper.enabled_ids.join(", ")}")
    if @event_wrapper.wrap_before?
      @event_wrapper.event.clone_and_save(
        base_params.merge(@event_wrapper.before_params),
        @event_wrapper.enabled_ids
      ) do |item|
        if item.instance_of?(Commitment)
          set_appropriate_approval_status(item)
        end
      end
    end
    if @event_wrapper.wrap_after?
      @event_wrapper.event.clone_and_save(
        base_params.merge(@event_wrapper.after_params),
        @event_wrapper.enabled_ids
      ) do |item|
        if item.instance_of?(Commitment)
          set_appropriate_approval_status(item)
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def wrapper_params
    params.require(:event_wrapper).permit(:wrap_before, :before_duration, :wrap_after, :after_duration, enabled_ids: [])
  end
end
