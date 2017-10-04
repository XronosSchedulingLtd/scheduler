# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ScheduleController < ApplicationController
  include DisplaySettings

  layout 'schedule'

  def show
    if params[:date]
      #
      #  If the request specifies a date then we get a little tricky.
      #  We could just shove that date in the :last_start_date field
      #  in the session and then go on to display the page, but then
      #  the specified date would stay in the URL.  Instead we shove
      #  it there and then redirect to the root (which is us again)
      #  but it means that if the user later refreshes the page, he
      #  or she won't be sent back to this date.
      #
      session[:last_start_date] = Time.zone.parse(params[:date])
      #
      #  We also allow the possibility of specifying a particular
      #  concern belonging to the user which should be set to visible.
      #  This is to facilitate the approval of event requests.
      #
      concern_id = params[:concern_id]
      if concern_id
        #
        #  Possible we might get nonsense here - don't want to
        #  raise an error.  Calling just find() would raise an
        #  error if the concern id was invalid.
        #
        concern = Concern.find_by(id: concern_id)
        if concern && concern.user == current_user
          unless concern.visible
            concern.visible = true
            concern.save
          end
        end
      else
        #
        #  Or alternatively, it is possible to specify an element
        #  id.  This allows users who can add concerns to get one
        #  intelligently added directly through a link.
        #
        element_id = params[:element_id]
        if current_user.can_add_concerns? && element_id
          element = Element.find_by(id: element_id)
          if element
            #
            #  He or she may already have one.
            #
            existing_concern = current_user.concern_with(element)
            if existing_concern
              unless existing_concern.visible
                existing_concern.visible = true
                existing_concern.save
              end
            else
              #
              #  Need to add one.
              #
              current_user.concerns.create({
                element:       element,
                list_teachers: current_user.list_teachers,
                colour:        element.preferred_colour ?
                               element.preferred_colour :
                               current_user.free_colour,
                visible:       true
              })
            end
          end
        end
      end
      #
      #  And it's possible that the URL specifies that we should
      #  turn on the user's own events.
      #
      if params.has_key?(:my_events) && current_user
        unless current_user.show_owned
          current_user.show_owned = true
          current_user.save
        end
      end
      redirect_to :root
    else
      #
      #  We should decide here what exactly gets shown in the way
      #  of columns, user information and concerns - *not* in the view.
      #
      if (current_user && current_user.known?) ||
         Property.public_ones.count > 1
        @show_lhs     = true
      else
        #
        #  Note that the key word here is "show".  The div containing
        #  a possible pseudo-concern will still be there (and so the
        #  corresponding events will still be fetched), but it will be
        #  hidden.
        #
        @show_lhs     = false
      end
      setvars_for_lhs(current_user)
      #
      #  Make space for creating a new concern.
      #
      @concern = Concern.new
      start_at = session[:last_start_date] || Time.zone.now
      @default_date = start_at.strftime("%Y-%m-%d")
      @show_jump = true
      @show_search = true
      respond_to do |format|
        format.html
      end
    end
  end

  def events
    ea = EventAssembler.new(session, current_user, params)
    @schedule_events = ea.call
    respond_to do |format|
      format.json { render json: @schedule_events }
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
