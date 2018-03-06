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
      @event_wrapper = EventWrapper.new({
        event: @event
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
    params.require(:wrapper).permit(:body)
  end
end
