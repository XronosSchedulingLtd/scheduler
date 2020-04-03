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
    @periods = generate_periods(current_user)
  end

  # POST /freefinders
  #
  #  Despite the name, we don't currently create a record in the database.
  #
  def create
    @freefinder = Freefinder.new(freefinder_params)
    @periods = generate_periods(current_user)
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
        redirect_to edit_group_path(group_id, just_created: true)
      else
        render :new
      end
    else
      render :new
    end
  end

  private

  #
  #  Generate a structure giving the current period definitions
  #  for the day shape selected by this user.  If the user has
  #  no day shape selected, return nil.
  #
  def generate_periods(user)
    #
    #  For now we're actually just going for the system one.
    #
    day_shape = Setting.default_free_finder_day_shape
    if day_shape
      #
      #  Not sure whether to make this an array or a hash.
      #
      periods = Hash.new
      0.upto(6) do |wday|
        periods[wday] = Array.new
      end
      #
      #  Each rota slot corresponds to one time of day, and contains
      #  a list of days on which it applies.  We want it the other
      #  way around - a list of days, and for each of them the times
      #  of its periods.
      #
      day_shape.rota_slots.sort.each do |rs|
        rs.periods do |wday, starts_at, ends_at|
          periods[wday] << [starts_at, ends_at]
        end
      end
      periods
    else
      nil
    end
  end

  def send_csv(freefinder)
    result = freefinder.to_csv
    send_data(result,
              :filename => "free.csv",
              :type => "application/csv")
  end

  def authorized?(action = action_name, resource = nil)
    known_user? && current_user.can_find_free
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
