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
#    Rails.logger.debug("Wrapping.  Enabled IDs are: #{@event_wrapper.enabled_ids.join(", ")}")
    if @event_wrapper.single_wrapper?
        request_notifier = RequestNotifier.new
        single_event = @event_wrapper.event.clone_and_save(
          current_user,
          base_params.merge(@event_wrapper.single_params),
          @event_wrapper.enabled_ids,
          :wrapped
        ) do |item|
          if item.instance_of?(Commitment)
            set_appropriate_approval_status(item)
            request_notifier.commitment_added(item)
          end
        end
        request_notifier.send_notifications_for(current_user, single_event)
    else
      if @event_wrapper.wrap_before?
        request_notifier = RequestNotifier.new
        before_event = @event_wrapper.event.clone_and_save(
          current_user,
          base_params.merge(@event_wrapper.before_params),
          @event_wrapper.enabled_ids,
          :wrapped
        ) do |item|
          if item.instance_of?(Commitment)
            set_appropriate_approval_status(item)
            request_notifier.commitment_added(item)
          end
        end
        request_notifier.send_notifications_for(current_user, before_event)
      end
      if @event_wrapper.wrap_after?
        request_notifier = RequestNotifier.new
        after_event = @event_wrapper.event.clone_and_save(
          current_user,
          base_params.merge(@event_wrapper.after_params),
          @event_wrapper.enabled_ids,
          :wrapped
        ) do |item|
          if item.instance_of?(Commitment)
            set_appropriate_approval_status(item)
            request_notifier.commitment_added(item)
          end
        end
        request_notifier.send_notifications_for(current_user, after_event)
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
    params.require(:event_wrapper).permit(:single_wrapper,
                                          :wrap_before,
                                          :before_duration,
                                          :before_title,
                                          :wrap_after,
                                          :after_duration,
                                          :after_title,
                                          :single_title,
                                          :organiser_id,
                                          :organiser_name,
                                          enabled_ids: [])
  end
end
