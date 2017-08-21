# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class JournalsController < ApplicationController
  before_action :set_journal, only: [:show]

  # GET /journals
  # GET /journals.json
  def index
    @journals = Journal.page(params[:page])
  end

  # GET /journals/1
  def show
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_journal
      @journal = Journal.find(params[:id])
    end

end
