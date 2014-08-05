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

    def initialize(event, current_user, attachment)
      @event  = event
      if current_user && current_user.known? && attachment
        if event.covered_by?(current_user.own_element) ||
           event.eventcategory_id == Event.invigilation_category.id
          @colour = "red"
        else
          @colour = attachment.colour
        end
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
    @interest = Interest.new
    #
    #  This next one needs to go as soon as I get Interest creation
    #  working correctly.
    #
    @element  = Element.new
  end

  def events
#    raise params.inspect
    start_date = Time.zone.parse(params[:start])
    end_date   = Time.zone.parse(params[:end]) - 1.day
    element_id = params[:eid].to_i
    cc = Eventcategory.find_by_name("Calendar")
    dc = Eventcategory.find_by_name("Duty")
    wlc = Eventcategory.find_by_name("Week letter")
    if current_user && current_user.known?
      if element_id != 0
        i = current_user.interests.detect {|ci| ci.element_id == element_id}
        if i
          element = i.element
          @schedule_events =
            element.events_on(start_date, end_date).collect {|e|
              ScheduleEvent.new(e, current_user, i)
            }
        else
          @schedule_events = []
        end
      else
        @schedule_events =
          (current_user.ownerships.collect {|o|
             o.element.events_on(start_date, end_date).collect {|e|
               ScheduleEvent.new(e, current_user, o)
             }
           }.flatten) +
  #        (current_user.interests.collect {|i|
  #           i.element.events_on(start_date, end_date).collect {|e|
  #             ScheduleEvent.new(e, current_user, i)
  #           }
  #         }.flatten) +
          ((wlc ? wlc.events_on(start_date, end_date) : []).collect {|e|
              ScheduleEvent.new(e, current_user, nil)
           })
      end
    else
      @schedule_events =
        ((cc ? cc.events_on(start_date, end_date) : []) +
         (dc ? dc.events_on(start_date, end_date) : []) +
         (wlc ? wlc.events_on(start_date, end_date) : [])).collect {|e|
          ScheduleEvent.new(e, nil, nil)
        }
    end
    begin
      respond_to do |format|
        format.json { render json: @schedule_events }
      end
    end
  end

  private

  #
  #  Currently the only two actions which we offer are show and events,
  #  but list them explicitly in order to fail safe in the case of future
  #  expansion.
  #
  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.admin) ||
    action == 'show' || action == 'events'
  end

end
