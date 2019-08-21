# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class ClonersController < ApplicationController
  before_action :set_event

  # GET /events/1/clones/new
  #
  # Allows the user to clone an existing event.
  #
  def new
    if current_user.can_edit?(@event)
      @event_cloner = EventCloner.new(@event)
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
    if current_user.can_edit?(@event)
      @event_cloner = EventCloner.new(@event, params)
      base_params = {
        owner:     current_user,
        eventsource: Eventsource.find_by(name: "Manual")
      }
      @event_cloner.instances.each do |instance|
        request_notifier = RequestNotifier.new
        new_event = @event.clone_and_save(
          current_user,
          base_params.merge(instance.cloning_params(@event)),
        ) do |item|
          case item
          when Commitment
            set_appropriate_approval_status(item)
            request_notifier.commitment_added(item)
          when Request
            request_notifier.request_added(item)
          end
        end
        request_notifier.send_notifications_for(current_user, new_event)
      end
      #
      #  And now like for repeating, I think we should close the dialogue.
      #
    else
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render 'not_permitted' }
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

end
