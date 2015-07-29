# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ScheduleController < ApplicationController
  layout 'schedule'

  #
  #  This is much like an Event, but carries more display information.
  #
  class ScheduleEvent

    #
    #  A bit of messing about is needed to generate a constant hash with
    #  a default value.
    #
    KNOWN_COLOUR_NAMES = lambda do
      known_colour_names = {
        "red"   => "#FF0000",
        "pink"  => "#FFC0CB",
        "green" => "#008000"
      }.default = "#000000"
      known_colour_names
    end.call

    #
    #  Passed a colour, produces a more greyed out version of the same
    #  colour.  Lighter, and with less colour density, but still
    #  clearly related.
    #
    def washed_out(colour)
      if colour[0] != "#"
        colour = KNOWN_COLOUR_NAMES[colour]
      end
      red_bit   = colour[1,2].hex
      green_bit = colour[3,2].hex
      blue_bit  = colour[5,2].hex
      red_bit   = (255 - (255 - red_bit)   / 2)
      green_bit = (255 - (255 - green_bit) / 2)
      blue_bit  = (255 - (255 - blue_bit)  / 2)
      "##{
           sprintf("%02x", red_bit)
         }#{
           sprintf("%02x", green_bit)
         }#{
           sprintf("%02x", blue_bit)
         }"
    end

    def initialize(event, current_user = nil, colour = nil, mine = false)
      @event  = event
      if colour
        @colour = colour
        #
        #  If this is an event covered by the current user, *and* we
        #  are selecting it by the current user's own element, then we
        #  change the colour to red.  Likewise for invigilations.
        #
        if mine &&
           current_user &&
           current_user.known? &&
           (event.covered_by?(current_user.own_element) ||
            event.eventcategory_id == Event.invigilation_category.id)
          @colour = "red"
        end
      elsif event.eventcategory_id == Event.weekletter_category.id
        @colour = "pink"
      else
        @colour = "green"
      end
      if event.non_existent
        @colour = washed_out(@colour)
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
    #
    #  Make space for creating a new concern.
    #
    @concern = Concern.new
  end

  def events
#    raise params.inspect
    start_date = Time.zone.parse(params[:start])
    end_date   = Time.zone.parse(params[:end]) - 1.day
    concern_id = params[:cid].to_i
    if current_user && current_user.known?
      if concern_id == 0
        #
        #  We are being asked for the usual list of events for the
        #  current user.  These consist of:
        #
        #  * Events the user owns (i.e. he or she edited them in).
        #  * Events the user's element is listed as organising.
        #  * Breakthrough events, for all users.  These too are to go.
        #  * As a special case for now, calendar events if the
        #    user has asked for them.  Later on, calendar events will
        #    be specified by them involving the calendar element.
        #
        #  As an order of precedence, we classify the events in that order.
        #  Each event should appear only once, and in the category which
        #  is listed here first.
        #
        #
        if current_user.show_owned
          my_owned_events =
            current_user.events_on(start_date,
                                   end_date,
                                   nil,
                                   nil,
                                   true)
          my_organised_events =
            Event.events_on(start_date,
                            end_date,
                            nil,
                            nil,
                            nil,
                            nil,
                            true,
                            current_user.own_element) - my_owned_events
        else
          my_owned_events = []
          my_organised_events = []
        end
        breakthrough_events =
          Event.events_on(start_date,
                          end_date,
                          Eventcategory.for_users) -
                          (my_owned_events + my_organised_events)
        if current_user.show_calendar
          calendar_events =
            Event.events_on(start_date,
                            end_date,
                            "Calendar",
                            nil,
                            nil,
                            nil,
                            true) - (my_owned_events +
                                     my_organised_events +
                                     breakthrough_events)
        else
          calendar_events = []
        end
        @schedule_events =
          calendar_events.collect {|e|
            ScheduleEvent.new(e,
                              current_user,
                              "green")
          } +
          my_owned_events.collect {|e|
            ScheduleEvent.new(e,
                              current_user,
                              current_user.colour_not_involved)
          } +
          my_organised_events.collect {|e|
            ScheduleEvent.new(e,
                              current_user,
                              current_user.colour_not_involved)
          } +
          breakthrough_events.collect {|e|
            ScheduleEvent.new(e,
                              current_user)
          }
      else
        #
        #  An explicit request for the events relating to a specified
        #  element.  Only allow it if the element is listed as being
        #  one of the current user's interests.  This is to stop users
        #  being able to hand-craft requests for information to which
        #  they might not be entitled.
        #
        concern =
          current_user.concerns.detect {|ci| ci.id == concern_id}
        if concern && concern.visible
          element = concern.element
          @schedule_events =
            element.events_on(start_date,
                              end_date,
                              nil,
                              nil,
                              true,
                              true).collect {|e|
              ScheduleEvent.new(e,
                                current_user,
                                concern.colour,
                                concern.equality)
            }
        else
          @schedule_events = []
        end
      end
    else
      @schedule_events =
        Event.events_on(start_date,
                        end_date,
                        Eventcategory.public_ones).collect {|e|
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
