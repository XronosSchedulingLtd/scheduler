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
        concern = current_user.concerns.find_by(id: concern_id)
        if concern
          unless concern.visible
            concern.visible = true
            concern.save
          end
          #
          #  This concern might belong to a concern set other than
          #  the current one.  Change the current concern set if this
          #  is the case.
          #
          #  Note that both the concern's concern set, and the user's
          #  current concern set might potentially be nil.  Happily
          #  these match up.
          #
          if concern.concern_set_id != current_user.current_concern_set_id
            current_user.current_concern_set = concern.concern_set
            current_user.save
          end
        end
      else
        #
        #  Or alternatively, it is possible to specify an element
        #  id.  This allows users who can add concerns to get one
        #  intelligently added directly through a link.
        #
        #  Note that we only ever add a concern to the default concern
        #  set.
        #
        element_id = params[:element_id]
        if current_user && current_user.can_add_concerns? && element_id
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
            #
            #  And switch to the default concern set, so it is actually
            #  visible.
            #
            if current_user.current_concern_set != nil
              current_user.current_concern_set = nil
              current_user.save
            end
          end
        end
      end
      #
      #  And it's possible that the URL specifies that we should
      #  turn on the user's own events.
      #
      if params.has_key?(:my_events) && known_user?
        unless current_user.show_owned
          current_user.show_owned = true
          current_user.save
        end
      end
      #
      #  If an andopen parameter has been specified, then preserve
      #  it for next time.
      #
      andopen = params[:andopen]
      if andopen
        session[:andopen] = andopen
      else
        session.delete(:andopen)
      end
      redirect_to :root
    else
      #
      #  We should decide here what exactly gets shown in the way
      #  of columns, user information and concerns - *not* in the view.
      #
      if known_user? ||
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
      #
      #  Do we want to open the dialogue for an event as well?
      #  Note that currently we allow the andopen trick only if
      #  a date is specified as well.  This would be the point to
      #  add some extra code if we want to allow it to work without
      #  a date.
      #
      andopen = session[:andopen]
      if andopen
        #
        #  Allowed only one go at this.
        #
        session.delete(:andopen)
        #
        #  And if you're not logged in you can't do it at all.
        #
        if known_user?
          #
          #  Quick check that the requested event does actually
          #  exist.  Avoids opening a window only to find that
          #  the given id is rubbish.
          #
          #  Note that a logged in, known user can always look at
          #  an event, but how much can be seen and whether editing
          #  is possible is decided later.
          #
          if Event.find_by(id: andopen)
            @andopen = andopen
          end
        end
      end
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
  #  Non logged in users can specify a date on a show, but nothing else.
  #
  #  If you're not logged in and you specify any of the others then you
  #  will be asked to log in.  If you are logged in, but don't have
  #  permissions, then they don't do much.
  #
  def authorized?(action = action_name, resource = nil)
    if logged_in?
      if current_user.admin?
        true
      else
        action == 'show' || action == 'events'
      end
    else
      (action == 'show' &&
       !(params.has_key?(:concern_id) ||
         params.has_key?(:element_id) ||
         params.has_key?(:my_events) ||
         params.has_key?(:andopen))) ||
      (action == 'events')
    end
  end

end
