# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ScheduleController < ApplicationController
  layout 'schedule'

  #
  #  This is much like an Event, but carries more display information.
  #
  class ScheduleEvent

    def initialize(event, current_user)
      @event  = event
      if event.eventcategory_id == Event.lesson_category.id
        if current_user &&
           current_user.ownerships.size > 0
          if event.covered_by?(current_user.ownerships[0].element)
            @colour = "red"
          elsif event.involves?(current_user.ownerships[0].element)
            @colour = "#225599"
          else
            @colour = "gray"
          end
        else
          @colour = "gray"
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
  end

  def events
#    raise params.inspect
    start_date = Time.zone.parse(params[:start])
    end_date   = Time.zone.parse(params[:end]) - 1.day
    cc = Eventcategory.find_by_name("Calendar")
    dc = Eventcategory.find_by_name("Duty")
    wlc = Eventcategory.find_by_name("Week letter")
    if current_user && current_user.ownerships.size > 0
      @events =
        ((current_user.ownerships.collect {|o|
          o.element.entity.events_on(start_date, end_date) }.flatten) +
         (wlc ? wlc.events_on(start_date, end_date) : [])).uniq
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
    @schedule_events = @events.collect {|e| ScheduleEvent.new(e, current_user)}
    begin
      respond_to do |format|
        format.json { render json: @schedule_events }
      end
    end
  end
end
