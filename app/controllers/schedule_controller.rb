class ScheduleController < ApplicationController
  layout 'schedule'

  def show
  end

  def events
#    raise params.inspect
    start_date = params[:start]
    end_date   = params[:end]
    @events = Event.beginning(Date.parse(start_date)).until(Date.parse(end_date))
    respond_to do |format|
      format.json { render json: @events }
    end
  end
end
