class ScheduleController < ApplicationController
  layout 'schedule'

  def show
  end

  def events
#    raise params.inspect
    start_date = Time.zone.parse(params[:start])
    end_date   = Time.zone.parse(params[:end]) - 1.day
    cc = Eventcategory.find_by_name("Calendar")
    wlc = Eventcategory.find_by_name("Week letter")
    @events =
      (Staff.find_by_initials("JHW").events_on(start_date, end_date) +
       (cc ? cc.events_on(start_date, end_date) : []) +
       (wlc ? wlc.events_on(start_date, end_date) : [])).uniq
#    @events = Event.events_on(Time.zone.parse(start_date),
#                              Time.zone.parse(end_date) - 1.day)
    #@events = Event.beginning(Time.zone.parse(start_date)).until(Time.zone.parse(end_date))
#    @events = Event.split_multi_day_events(@events)
    begin
      respond_to do |format|
        format.json { render json: @events }
      end
    end
  end
end
