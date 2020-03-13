#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AgendasController < ApplicationController
  layout 'schedule'

  # GET /agenda
  #
  def show
    #
    #  Do we want zoom links?
    #
    if Setting.current.zoom_link_text.blank? ||
        Setting.current.zoom_link_base_url.blank?
      @do_zoom_links = 0
      @zoom_link_text = ''
      @zoom_link_base_url = ''
    else
      @do_zoom_links = 1
      @zoom_link_text = Setting.current.zoom_link_text
      @zoom_link_base_url = Setting.current.zoom_link_base_url
    end
  end

  # GET /agenda/events.json
  #
  def events
    ea = EventAssembler.new(session, current_user, params)
    agenda_events = ea.agenda_events
    respond_to do |format|
      format.json { render json: agenda_events }
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    known_user?
  end

end
