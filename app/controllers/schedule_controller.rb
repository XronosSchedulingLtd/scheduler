class ScheduleController < ApplicationController
  layout 'schedule'

  def show
  end

  def events
    @events = Event.all
    respond_to do |format|
      format.json { render json: @events }
    end
  end
end
