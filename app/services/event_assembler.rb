# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module ColourManipulation

  KNOWN_COLOUR_NAMES = {
    "red"   => "#FF0000",
    "pink"  => "#FFC0CB",
    "green" => "#008000"
  }
  KNOWN_COLOUR_NAMES.default = "#000000"

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
    #
    #  Each bit is half way between its original shade and full blast.
    #
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
end

module DisplayHelpers
  def hover_text_for(event)
    staff = event.staff_entities
    if staff.size > 0
      trailer = "\nStaff: #{staff.collect {|s| s.initials}.join(", ")}"
    else
      trailer = ""
    end
    "#{event.body} : #{event.owners_name}#{trailer}"
  end

end

class EventAssembler

  #
  #  This is much like an Event, but carries more display information.
  #
  class ScheduleEvent

    include ColourManipulation

    def redden(colour)
      "#ff7070"
    end

    def initialize(view_start,
                   event,
                   via_element,
                   current_user = nil,
                   colour = nil,
                   mine = false,
                   list_teachers = false)
      @event   = event
      @event_id = event.id
      if via_element
        @sort_by = "#{via_element.id} #{event.body}"
      else
        @sort_by = "0 #{event.body}"
      end
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
#        @colour = "#212D48"  # Blue of the title bar - good one.
#        @colour = "#663d52"  # Darkish pink
      else
        @colour = "green"
#        @colour = "#4068b2"  # Blue very like "myself" - good one.
#        @colour = "#7094ff"
#        @colour = "#3366ff"
#        @colour = "#00476b"  # Distinguised blue
      end
      #
      #  Conditions for washing out the colour.
      #
      #  1) The event is non-existent.
      #  2) The event is incomplete *and* we aren't accessing it via
      #     an element which we own.  If we are accessing it via an
      #     element which we own, then we grey out only if the corresponding
      #     commitment is still tentative.
      #
      if event.non_existent
        @colour = washed_out(@colour)
      else
        unless event.complete?
          #
          #  Users who aren't logged in don't get to know nuances
          #  about whether events are complete or not.
          #
          if current_user && current_user.known?
            if via_element
              #
              #  And only those with a special interest get to know
              #  about rejections.
              #
              if current_user.owns?(via_element) ||
                 current_user.admin ||
                 current_user.id == event.owner_id
                #
                #  Has the commitment been approved?
                #
                c = Commitment.find_by(element_id: via_element.id,
                                       event_id: event.id)
                if c
                  if c.tentative?
                    if c.rejected?
                      @colour = redden(@colour)
                    else
                      @colour = washed_out(@colour)
                    end
                  end
                else
                  #
                  #  Odd - can't find the corresponding commitment.
                  #  Err on the side of caution and wash it out.
                  #
                  @colour = washed_out(@colour)
                end
              else
                @colour = washed_out(@colour)
              end
            else
              #
              #  We're trying to look at the event *not* via
              #  a particular element.  This means we own it,
              #  are listed as the organiser, or that it's a
              #  breakthrough event of some sort.
              #
              #  Given that it's not complete, wash it out.
              #
              @colour = washed_out(@colour)
            end
          end
        end
      end
      #
      #  Now set up stuff ready for this event to be serialized
      #  as JSON.  Note that we sometimes fib slightly to FullCalendar
      #  in order to get things displayed the way we want.
      #
      #  Slight distinctions are:
      #
      #  * Editable.  From FC's point of view, this means draggable.
      #               Sometimes we want to prevent dragging, even
      #               though the user does actually have edit
      #               privileges.  We thus set it to false.
      #
      #  * All day.   This controls where FC will place the event.
      #               We too have both all-day and timed events, but
      #               for timed events which span multiple days we prefer
      #               them to be displayed in FC's all-day area, so we
      #               fib and tell FC they are all-day.
      #
      #  * End date.  For the above case, where we're fibbing about
      #               all-dayness, we also have to fib about the end
      #               date.  FC expects the end date of an all day
      #               event to be the start of the next day.  For
      #               a genuine all-day event occupying the 3rd and
      #               4th of a month.  We need to give a start date
      #               of YYYY-MM-03 and an end date of YYYY-MM-05.
      #               Happily, this is the way we store genuine all-day
      #               events too, but we need to adjust the end date
      #               for the case of a fake all-day event.
      #
      if event.multi_day_timed? && view_start <= event.starts_at.to_date
        @prefix = "(#{event.starts_at.strftime("%H:%M")}) "
      else
        @prefix = nil
      end
      @title = event.body
      if list_teachers
        staff = event.staff_entities
        if staff.size > 0
          @title += " - #{staff.collect {|s| s.initials}.join(", ")}"
        end
      end
      @all_day = event.all_day? || event.multi_day_timed?
      #
      #  Note that our idea of editable is slightly different from
      #  FullCalendar's.  If I set editable on the event data, then
      #  FullCalendar will let us drag it around - i.e. change the time.
      #  This corresponds to our idea of being retimeable.
      #
      @editable = current_user ?
                  current_user.can_drag_timing?(event) && !@multi_day_timed :
                  false
      #
      #  We are slightly coy about displaying clash information.  Only
      #  those who would be able to see the details (i.e. staff) get
      #  to see the little icon.
      #
      @has_clashes = event.has_clashes && current_user && current_user.staff?
      #
      #  Likewise for coloured flags.
      #
      if current_user && current_user.exams? && event.flagcolour
        @flag_colour = event.flagcolour
      else
        @flag_colour = ""
      end
    end

    def as_json(options = {})
      result = {
        :id            => @event_id,
        :title         => @title,
        :start         => @event.starts_at_for_fc,
        :end           => @event.ends_at_for_fc,
        :allDay        => @all_day,
        :recurring     => false,
        :editable      => @editable,
        :color         => @colour,
        :has_clashes   => @has_clashes,
        :fc            => @flag_colour,
        :sort_by       => @sort_by,
        :eventId       => @event_id
      }
      if @prefix
        result[:prefix] = @prefix
      end
      result
    end

  end

  class BackgroundEvent
    #
    #  Sort of similar-ish, but used to provide background events
    #  which typically show when the periods are in a school.
    #
   
    def initialize(starts_at, ends_at)
      @starts_at = starts_at
      @ends_at = ends_at
    end

    def as_json(options = {})
      result = {
        :start         => @starts_at.iso8601,
        :end           => @ends_at.iso8601,
        :rendering     => 'background'
      }
      result
    end

    def self.construct(rota_template, start_date, end_date)
      events = []
      start_date.upto(end_date) do |date|
        rota_template.slots_for(date) do |slot|
          starts_at, ends_at = slot.timings_for(date)
          events << BackgroundEvent.new(starts_at, ends_at)
        end
      end
      events
    end

  end

  #
  #  We also want to be able to display requests for events.  Here we focus
  #  more on the individual request rather than the event.  Because a request
  #  can specify more than one instance of a resource, we display one
  #  bar for each instance, but they need to have different IDs.
  #
  #  We also display only un-fulfilled requests.  This gives the illusion
  #  that you can fulfill one by dragging it between rows.
  #
  class ScheduleRequest
    include ColourManipulation
    include DisplayHelpers

    def initialize(main_display, element, request, index, view_start = nil)
      #
      #  The same request may appear several times, so need to generate
      #  a unique event id.
      #
      event = request.event
      #
      @id               = "Req#{request.id}-#{index}"
      @title            = "#{event.body} (#{index})"
      if main_display
        @starts_at_for_fc = event.starts_at_for_fc
        @ends_at_for_fc   = event.ends_at_for_fc
        if event.multi_day_timed? && view_start <= event.starts_at.to_date
          @prefix = "(#{event.starts_at.strftime("%H:%M")}) "
        else
          @prefix = nil
        end
        @all_day        = event.all_day? || event.multi_day_timed?
      else
        @starts_at_for_fc = event.starts_at_for_fc(false)
        @ends_at_for_fc   = event.ends_at_for_fc(false)
        @prefix           = nil
        @all_day          = event.all_day?
      end
      @resource_id      = element.id
      @request_id       = request.id
      @event_id         = request.event_id
      if element.preferred_colour
        if main_display || request.no_forms_outstanding?
          @colour = element.preferred_colour
        else
          @colour = washed_out(element.preferred_colour)
        end
      end
      @hover_text       = hover_text_for(request.event)
    end

    def as_json(options = {})
      result = {
        id:         @id,
        title:      @title,
        start:      @starts_at_for_fc,
        end:        @ends_at_for_fc,
        allDay:     @all_day,
        recurring:  false,
        editable:   true,                # For now
        resourceId: @resource_id,
        requestId:  @request_id,
        eventId:    @event_id,
        hoverText:  @hover_text
      }
      if @colour
        result[:color] = @colour
      end
      if @prefix
        result[:prefix] = @prefix
      end
      result
    end

  end

  #
  #  Similarly, for actual commitments.
  #
  #  These are used solely in the resource allocation display and are
  #  correspondingly simpler than the main ones.
  #
  class ScheduleCommitment

    include DisplayHelpers

    def initialize(element, commitment)
      @id               = "Com#{commitment.id}"
      @title            = commitment.event.body
      @starts_at_for_fc = commitment.event.starts_at_for_fc(false)
      @ends_at_for_fc   = commitment.event.ends_at_for_fc(false)
      @all_day          = commitment.event.all_day?
      @resource_id      = element.id
      @event_id         = commitment.event_id
      if commitment.request
        @request_id = commitment.request.id
        @editable   = true
        if commitment.request.element.preferred_colour
          @colour = commitment.request.element.preferred_colour
        end
      else
        @request_id = 0
        @editable   = false
        unless element.add_directly?
          @colour     = 'red'
        end
      end
      @hover_text       = hover_text_for(commitment.event)
    end

    def as_json(options = {})
      result = {
        id:         @id,
        title:      @title,
        start:      @starts_at_for_fc,
        end:        @ends_at_for_fc,
        allDay:     @all_day,
        recurring:  false,
        editable:   @editable,
        resourceId: @resource_id,
        requestId:  @request_id,
        eventId:    @event_id,
        hoverText:  @hover_text
      }
      if @colour
        result[:color] = @colour
      end
      result
    end

  end

  def initialize(session, current_user, params)
    @session      = session
    @current_user = current_user
    @params       = params
    @start_date   = Time.zone.parse(@params[:start])
    @end_date     = Time.zone.parse(@params[:end]) - 1.day
  end

  def call
#    raise params.inspect
    resulting_events = []
    if @current_user && @current_user.known?
      concern_id = @params[:cid].to_i
      if concern_id == 0
        #
        #  For this particular request, we make a note of the start
        #  date, in order to be able to return to it on a page refresh
        #  later.
        #
        @session[:last_start_date] = @start_date
        #
        #  We are being asked for the usual list of events for the
        #  current user.  These consist of:
        #
        #  * Events the user owns (i.e. he or she edited them in).
        #  * Events the user's element is listed as organising.
        #
        #  As an order of precedence, we classify the events in that order.
        #  Each event should appear only once, and in the category which
        #  is listed here first.
        #
        #
        watched_elements =
          @current_user.concerns.visible.collect {|concern| concern.element}
        if @current_user.show_owned
          my_owned_events =
            @current_user.events_on(@start_date,
                                   @end_date,
                                   nil,
                                   nil,
                                   true)
          my_organised_events =
            Event.events_on(@start_date,
                            @end_date,
                            nil,
                            nil,
                            nil,
                            nil,
                            true,
                            @current_user.own_element) - my_owned_events
          #
          #  Now I want to subtract from my owned events, the list of
          #  events involving elements which I am currently watching by
          #  another means.
          #
          #  Currently this is only going to work for direct involvement,
          #  not involvement via a group.
          #
          my_owned_events =
            my_owned_events.select { |e|
              !e.eventcategory.visible || !e.involves_any?(watched_elements)
            }
        else
          my_owned_events = []
          my_organised_events = []
        end
        selector = Eventcategory.schoolwide
        unless @current_user.suppressed_eventcategories.empty?
          selector = selector.exclude(@current_user.suppressed_eventcategories)
        end
        #
        #  The to_a causes the query to actually happen.
        #
        schoolwide_categories = selector.to_a
        if schoolwide_categories.empty?
          schoolwide_events = []
        else
          schoolwide_events =
            Event.events_on(@start_date,
                            @end_date,
                            schoolwide_categories) -
                            (my_owned_events + my_organised_events)
        end
        resulting_events =
          my_owned_events.collect {|e|
            ScheduleEvent.new(@start_date,
                              e,
                              nil,
                              @current_user,
                              @current_user.colour_not_involved)
          } +
          my_organised_events.collect {|e|
            ScheduleEvent.new(@start_date,
                              e,
                              nil,
                              @current_user,
                              @current_user.colour_not_involved)
          } +
          schoolwide_events.collect {|e|
            ScheduleEvent.new(@start_date,
                              e,
                              nil,
                              @current_user)
          }
        if @current_user && @current_user.day_shape
          resulting_events +=
            BackgroundEvent.construct(@current_user.day_shape,
                                      @start_date.to_date,
                                      @end_date.to_date)
        end
      else
        #
        #  An explicit request for the events relating to a specified
        #  element.  Only allow it if the element is listed as being
        #  one of the current user's interests.  This is to stop users
        #  being able to hand-craft requests for information to which
        #  they might not be entitled.
        #
        concern =
          @current_user.concerns.detect {|ci| ci.id == concern_id}
        if concern && concern.visible
          element = concern.element
          selector = Eventcategory.not_schoolwide.visible
          unless @current_user.suppressed_eventcategories.empty?
            selector =
              selector.exclude(@current_user.suppressed_eventcategories)
          end
          #
          #  The .to_a forces the lambda to be evaluated now.  We don't
          #  want the database being queried again and again for the
          #  same answer.
          #
          event_categories = selector.to_a
          #
          #  Does the user have any extra event categories listed?
          #
          #  Note that we make no attempt here to check whether the
          #  user is allowed to have any extra - that's done at
          #  the stage of updating the user's record.
          #
          unless @current_user.extra_eventcategories.empty?
            extra_categories =
              Eventcategory.where(id: @current_user.extra_eventcategories)
            unless extra_categories.empty?
              event_categories = (event_categories + extra_categories).uniq
            end
          end
          #
          #  Start by assembling all the relevant commitments, including
          #  those for events flagged as being non-existent.
          #
          #  Pre-load the events too, because we're going to use those.
          #
          #  Then deal with the question of whether to display each
          #  event.  We show it if any of the following applies:
          #
          #  * The commitment is firm (the usual case)
          #  * The current user owns the element.
          #  * The current user has the can_view_unconfirmed? flag set
          #  * The current user owns the event.
          #
          #  Tentative events (those awaiting approval) thus aren't shown
          #  in the context of the un-approved item, except to a select few.
          #
          #  Then we switch our attention to the actual events.  It's
          #  just possible that the same event has been selected twice
          #  (because of group membership) so uniq them, and then
          #  construct our ScheduleEvent objects - one per event.
          #
          if event_categories.empty?
            #
            #  If the user has suppressed all his event categories
            #  then the underlying code would treat an empty array
            #  as meaning "no restriction" and you'd be back to seeing
            #  them all again.
            #
            resulting_events = []
          else
            selector =
              element.commitments_on(startdate:           @start_date,
                                     enddate:             @end_date,
                                     eventcategory:       event_categories,
                                     include_nonexistent: true)
            if concern.list_teachers
              selector = selector.preload(event: {staff_elements: :entity})
            else
              selector = selector.preload(:event)
            end
            resulting_events =
                      selector.
                      select {|c| concern.owns ||
                                  @current_user.can_view_unconfirmed? ||
                                  !c.tentative? ||
                                  c.event.owner_id == @current_user.id }.
                      collect {|c| c.event}.
                      uniq.
                      collect {|e|
                        ScheduleEvent.new(@start_date,
                                          e,
                                          element,
                                          @current_user,
                                          concern.colour,
                                          concern.equality,
                                          concern.list_teachers)
                      }
          end
          #
          #  And add in any outstanding requests for this element's
          #  entity.  The method quickly returns an empty array if
          #  the entity is not eligible for requests.
          #
          requests = requests_for(element.entity, true, @start_date)
          unless requests.empty?
            resulting_events += requests
          end
        end
      end
    else
      #
      #  We expect to be passed a *fake* concern ID - starts with E
      #  followed by a number.  It must lead us to the element of a
      #  public property.
      #
      #  We also might be passed no ID at all, in which case we
      #  return just the breakthrough events.
      #
      fake_id = @params[:cid]
      if fake_id =~ /^E\d+$/
        element_id = fake_id[1..-1].to_i
        element = Element.find_by(id: element_id)
        if element &&
          element.entity_type == "Property" &&
          element.entity.make_public
          #
          #  This looks like a really weird test, but I want to treat
          #  the absence of the relevant key as being equivalent to true.
          #  Absence will return nil.  Only an actual value of false
          #  should suppress the events.
          #
          if @session[fake_id] != false
            #
            #  Now, in picking the events to show I want to filter out
            #  any where the category means they would break through
            #  anyway.  Basically these are key dates and week letters.
            #
            resulting_events +=
              element.events_on(@start_date,
                                @end_date,
                                Eventcategory.not_schoolwide.visible.to_a).collect {|e|
                ScheduleEvent.new(@start_date,
                                  e, nil, nil, element.preferred_colour)
              }
          end
        end
      elsif fake_id.blank?
        @session[:last_start_date] = @start_date
        resulting_events =
         Event.events_on(
           @start_date,
           @end_date,
           Eventcategory.schoolwide.visible.to_a).collect {|e|
             ScheduleEvent.new(@start_date,
                               e, nil, nil)}
      end
    end
    return resulting_events
  end

  #
  #  This method produces event-like objects, but for requests rather
  #  than commitments.  It is used in the resource allocation display
  #  and in the main schedule display.
  #
  #  We can produce:
  #
  #  * One entry per outstanding request.
  #  * A single entry for the request, regardless.
  #
  #  For the main display we do a single entry, but for the resource
  #  allocation display we do one per outstanding request.
  #
  #  We default to doing it for the allocation display.
  #
  def requests_for(entity, main_display = false, start_date = nil)
    result = []
    if entity.can_have_requests?
      entity.element.
             requests.
             during(@start_date, @end_date + 1.day).
             includes([:event, :user_form_response, :commitments]).
             each do |r|
        if main_display
          result << ScheduleRequest.new(main_display,
                                        entity.element,
                                        r,
                                        r.quantity,
                                        start_date)
        else
          r.num_outstanding.times do |i|
            result << ScheduleRequest.new(main_display,
                                          entity.element,
                                          r,
                                          i + 1)
          end
        end
      end
    end
    result
  end

  #
  #  And this produces events for a specified entity.  We want just direct
  #  firm commitments, and we display them slightly differently from
  #  in the main display.  These are simpler, and intended just for
  #  the resource allocation display.
  #
  #  We go only for direct commitments - no groups or anything like that.
  #
  def events_for(entity)
    result = []
    entity.element.
           commitments.
           firm.
           during(@start_date, @end_date + 1.day).
           includes(:event).
           each do |c|
      result << ScheduleCommitment.new(entity.element, c)
    end
    result
  end
end
