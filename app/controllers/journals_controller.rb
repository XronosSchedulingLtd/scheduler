# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class JournalsController < ApplicationController
  before_action :set_journal, only: [:show]

  # GET /journals
  # GET /journals.json
  def index
    selector = Journal.order(:event_starts_at)
    if params[:current]
      #
      #  Want only current ones.
      #
      selector = selector.where.not(event_id: nil)
    elsif params[:deleted]
      selector = selector.where(event_id: nil)
    end
    @journals = selector.page(params[:page])
  end

  # GET /journals/1
  def show
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.can_view_journal_for?(:events)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_journal
    @journal = Journal.find(params[:id])
  end

end
