# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class FreefindersController < ApplicationController

  # GET /freefinders/new
  def new
    @freefinder = Freefinder.new
    @freefinder.on = Date.today
    @freefinder.start_time = Time.now
    @freefinder.end_time = @freefinder.start_time + 1.minute
  end

  # POST /freefinders
  #
  #  Despite the name, we don't currently create a record in the database.
  #
  def create
    @freefinder = Freefinder.new(freefinder_params)
    #
    #  The very minimum which we need in order to do a run is the element
    #  id of a group.
    #
    @freefinder.do_find
    #
    #  I've tried really hard to do this in a Rails native way, but
    #  the documentation is impenetrable.
    #
    if params[:export] == "Export"
      send_csv(@freefinder)
    elsif params[:create] == "Create group"
      group_id = @freefinder.create_group(current_user)
      if group_id
        redirect_to edit_group_path(group_id)
      else
        render :new
      end
    else
      render :new
    end
  end

  private

    def send_csv(freefinder)
      result = freefinder.to_csv
      send_data(result,
                :filename => "free.csv",
                :type => "application/csv")
    end

    def authorized?(action = action_name, resource = nil)
      logged_in? && current_user.staff?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def freefinder_params
      params.require(:freefinder).
             permit(:element_id,
                    :element_name,
                    :name,
                    :owner_id,
                    :on,
                    :start_time_text,
                    :end_time_text)
    end
end
