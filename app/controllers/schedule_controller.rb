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
    if current_user && current_user.known?
      if element_id != 0
        i = current_user.interests.detect {|ci| ci.element_id == element_id}
        if i
          element = i.element
          @schedule_events =
            element.events_on(start_date,
                              end_date,
                              nil,
                              nil,
                              true,
                              true).collect {|e|
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
        events_involving = ownership.element.events_on(start_date,
                                                       end_date,
                                                       nil,
                                                       nil,
                                                       true,
                                                       true)
        mine, notmine =
          events_involving.partition {|e| e.owner_id == current_user.id}
        myotherevents =
          current_user.events_on(start_date,
                                 end_date,
                                 nil,
                                 nil,
                                 true,
                                 true) - mine
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
          Event.events_on(start_date,
                          end_date,
                          Eventcategory.for_users).collect {|e|
            ScheduleEvent.new(e, current_user)
          }
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
