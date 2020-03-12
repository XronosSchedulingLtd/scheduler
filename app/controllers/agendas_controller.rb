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
