class ScheduleController < ApplicationController
  layout 'schedule'

  #
  #  This is much like an Event, but carries more display information.
  #
  class ScheduleEvent

    def initialize(event, entity)
      @event  = event
      if event.eventcategory_id == Event.lesson_category.id
        if event.covered_by?(entity)
          @colour = "red"
        else
          @colour = "#225599"
        end
      elsif event.eventcategory_id == Event.invigilation_category.id
        @colour = "red"
      elsif event.eventcategory_id == Event.weekletter_category.id
        @colour = "pink"
      else
        @colour = "green"
      end
    end

    def as_json(options = {})
      {
        :id        => "#{@event.id}",
        :title     => @event.body,
        :start     => @event.starts_at_for_fc,
        :end       => @event.ends_at_for_fc,
        :allDay    => @event.all_day,
        :recurring => false,
        :editable  => @event.can_edit?,
        :color     => @colour
      }
    end

  end

  def show
    if params[:initials]
      session[:initials] = params[:initials].upcase
    end
  end

  def events
#    raise params.inspect
    start_date = Time.zone.parse(params[:start])
    end_date   = Time.zone.parse(params[:end]) - 1.day
    cc = Eventcategory.find_by_name("Calendar")
    dc = Eventcategory.find_by_name("Duty")
    wlc = Eventcategory.find_by_name("Week letter")
    if session[:initials]
      resource = Staff.find_by_initials(session[:initials])
    else
      resource = Staff.find_by_initials("JHW")
    end
    if resource
      if session[:initials]
        @events =
          (resource.events_on(start_date, end_date) +
           (wlc ? wlc.events_on(start_date, end_date) : [])).uniq
      else
        @events =
          (resource.events_on(start_date, end_date) +
           (cc ? cc.events_on(start_date, end_date) : []) +
           (dc ? dc.events_on(start_date, end_date) : []) +
           (wlc ? wlc.events_on(start_date, end_date) : [])).uniq
      end
    else
      @events =
        ((cc ? cc.events_on(start_date, end_date) : []) +
         (dc ? dc.events_on(start_date, end_date) : []) +
         (wlc ? wlc.events_on(start_date, end_date) : [])).uniq
    end
#    @events = Event.events_on(Time.zone.parse(start_date),
#                              Time.zone.parse(end_date) - 1.day)
    #@events = Event.beginning(Time.zone.parse(start_date)).until(Time.zone.parse(end_date))
#    @events = Event.split_multi_day_events(@events)
    @schedule_events = @events.collect {|e| ScheduleEvent.new(e, resource)}
    begin
      respond_to do |format|
        format.json { render json: @schedule_events }
      end
    end
  end
end
