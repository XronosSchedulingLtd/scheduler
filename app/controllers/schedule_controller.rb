class ScheduleController < ApplicationController
  layout 'schedule'

  def show
  end

  def events
#    raise params.inspect
    start_date = params[:start]
    end_date   = params[:end]
    @events = Event.beginning(Time.zone.parse(start_date)).until(Time.zone.parse(end_date))
#    @events = Event.split_multi_day_events(@events)
    begin
      respond_to do |format|
        format.json { render json: @events }
      end
    end
  end
end
