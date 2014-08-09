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

    def initialize(event, current_user = nil, colour = nil)
      @event  = event
      if current_user && current_user.known? && colour
        if event.covered_by?(current_user.own_element) ||
           event.eventcategory_id == Event.invigilation_category.id
          @colour = "red"
        else
          @colour = colour
        end
      elsif event.eventcategory_id == Event.weekletter_category.id
        @colour = "pink"
      else
        @colour = "green"
      end
      @editable = current_user ? current_user.can_edit?(event) : false
    end

    def as_json(options = {})
      {
        :id        => "#{@event.id}",
        :title     => @event.body,
        :start     => @event.starts_at_for_fc,
        :end       => @event.ends_at_for_fc,
        :allDay    => @event.all_day,
        :recurring => false,
        :editable  => @editable,
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
    cc = Eventcategory.cached_category("Calendar")
    dc = Eventcategory.cached_category("Duty")
    wlc = Eventcategory.cached_category("Week letter")
    if current_user && current_user.known?
      if element_id != 0
        i = current_user.interests.detect {|ci| ci.element_id == element_id}
        if i
          element = i.element
          @schedule_events =
            element.events_on(start_date, end_date).collect {|e|
              ScheduleEvent.new(e, current_user, i.colour)
            }
        else
          @schedule_events = []
        end
      else
        #
        #  On the assumption that events owned by this user will usually
        #  involve this user, and we don't want them then to be displayed
        #  twice, we gather in those first and uniq them.
        #
        #  Currently cope with only one "me" ownership.  Know there is at
        #  least one because of the current_user.known? check above.
        #
        ownership = current_user.ownerships.me[0]
        events_involving = ownership.element.events_on(start_date, end_date)
        mine, notmine =
          events_involving.partition {|e| e.owner_id == current_user.id}
        myotherevents =
          current_user.events_on(start_date, end_date) - mine
        @schedule_events =
          notmine.collect {|e| ScheduleEvent.new(e,
                                                 current_user,
                                                 ownership.colour)} +
          mine.collect {|e| ScheduleEvent.new(e,
                                              current_user,
                                              current_user.colour_involved)} +
          myotherevents.collect {|e| ScheduleEvent.new(e,
                                                       current_user,
                                                       current_user.colour_not_involved)} +
          (wlc ? wlc.events_on(start_date, end_date) : []).collect {|e|
              ScheduleEvent.new(e, current_user)
           }
      end
    else
      @schedule_events =
        ((cc ? cc.events_on(start_date, end_date) : []) +
         (dc ? dc.events_on(start_date, end_date) : []) +
         (wlc ? wlc.events_on(start_date, end_date) : [])).collect {|e|
          ScheduleEvent.new(e)
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
