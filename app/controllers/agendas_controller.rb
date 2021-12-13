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
    #  Whose agenda should we show?
    #  A specified one overrides the logged in one.
    #
    if params[:tt]
      #
      #  The user may have sent something invalid, but if they do
      #  then they'll see nothing.
      #
      @uuid = params[:tt]
    else
      @uuid = "UUE-#{current_user&.own_element&.uuid}"
    end
    #
    #  Do we want zoom links?
    #
    @default_date = Date.today.strftime("%Y-%m-%d")
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
    known_user? || params.has_key?(:tt)
  end

end
