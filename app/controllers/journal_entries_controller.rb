# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class JournalEntriesController < ApplicationController
  before_action :set_element, only: [:index]

  # GET /journals
  # GET /journals.json
  def index
    selector = @element.journal_entries.order('created_at')
    @journal_entries = selector.page(params[:page])
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.can_view_journal_for?(:elements)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_element
    @element = Element.find(params[:element_id])
  end

end
