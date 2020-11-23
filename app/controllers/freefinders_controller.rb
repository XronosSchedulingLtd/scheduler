# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

#
#   !!!!DANGER WILL ROBINSON!!!!
#
#  Freefinders are used for two things:
#
#  1. Finding free resources at a given time
#  2. Finding a free time for a list of resources
#
#  and the way in which they do this is slightly curious - driven by
#  being developed at different times.  It may yet come back to bite me.
#
#  For the first case, we use new and create, and the record is never saved
#  to the database.  This one was implemented first.  The database table
#  existed purely to define the fields in the model.  Possibly an odd
#  way of doing it.
#
#  For the second case we use edit and update, and the record *does* get
#  saved to the database so the user can repeat a search later.  If at
#  first invocation of edit the user does not have a record then one is
#  created and populated with default values.
#
#  The user also has an option to reset his or her saved record (only one
#  per user) to the system defaults.
#
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
      @new_group = @freefinder.create_group(current_user)
      if @new_group
        redirect_to edit_group_path(@new_group, just_created: true)
      else
        render :new
      end
    else
      render :new
    end
  end

  #
  #  Rather strangely, we ignore the id given and fetch the user's
  #  existing FreeFinder, or create a new one.
  #
  # GET /freefinders/1/edit
  def edit
    ensure_freefinder
    ensure_elements
  end

  def reset
    reset_freefinder
    ensure_elements
    respond_to do |format|
      format.html { render :edit }
    end
  end

  #
  #  Called by our front end to add an element to our list.
  #
  def add_element
#    puts "request.xhr? yields #{request.xhr?}"
#    puts "request.format.js? yields #{request.format.js?.inspect}"
#    puts "request.format.html? yields #{request.format.html?.inspect}"
    ensure_freefinder
    if params[:element_id]
      element_id = params[:element_id].to_i
      if element_id != 0
        unless @freefinder.ft_element_ids.include? element_id
          #
          #  Make sure it really exists.
          #
          element = Element.find_by(id: element_id)
          if element
            @freefinder.ft_element_ids << element_id
            @freefinder.save
          end
        end
      end
    end
    ensure_elements
    respond_to do |format|
      format.js
    end
  end

  def remove_element
    ensure_freefinder
    if params[:element_id]
      element_id = params[:element_id].to_i
      if element_id != 0
        if @freefinder.ft_element_ids.include? element_id
          @freefinder.ft_element_ids.delete(element_id)
          @freefinder.save
        end
      end
    end
    ensure_elements
    respond_to do |format|
      format.js
    end
  end

  #
  # PUT /freefinders/1
  #
  # And again, we ignore the id given.  We put to the user's existing
  # FreeFinder.  It should not be possible for him/her not to have one,
  # but...
  #
  def update
    ensure_freefinder
    if @freefinder.update(freefinder_params)
      if @freefinder.ft_element_ids.empty?
        @freefinder.errors[:base] <<
        "Please say who you want to find free time for."
      else
        ensure_elements
        begin
          #
          #  Surely most of this logic should be in the model?
          #
          @days = []
          @fsf = FreeSlotFinder.new(@elements,
                                    @freefinder.ft_duration,
                                    @freefinder.ft_day_starts_at,
                                    @freefinder.ft_day_ends_at)
          @freefinder.ft_num_days.times do |i|
            date = @freefinder.ft_start_date + i.days
            if @freefinder.ft_days.include?(date.wday)
              slots =
                @fsf.slots_on(@freefinder.ft_start_date + i.days).
                     at_least_mins(@freefinder.ft_duration)
              unless slots.empty?
                Rails.logger.debug("slots is of class #{slots.class}")
                @days << slots
              end
            end
          end
        rescue ArgumentError => e
          @freefinder.errors[:base] << e.to_s
        end
      end
    end
    ensure_elements
    respond_to do |format|
      format.html { render :edit }
    end
  end

  private

  def ensure_freefinder
    @freefinder = current_user.freefinder
    if @freefinder
      #
      #  We keep the old settings, but not the start date if it's
      #  in the past.
      #
      today = Date.today
      if @freefinder.ft_start_date < today
        @freefinder.ft_start_date = today
      end
    else
      @freefinder =
        current_user.create_freefinder(Freefinder.system_defaults)
    end
  end

  def reset_freefinder
    @freefinder = current_user.freefinder
    if @freefinder
      @freefinder.update(
        Freefinder.system_defaults.merge({ft_element_ids: []}))
    else
      @freefinder =
        current_user.create_freefinder(Freefinder.system_defaults)
    end
  end

  def ensure_elements
    @elements = Element.where(id: @freefinder.ft_element_ids).to_a
  end

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
                  :end_time_text,
                  :ft_start_date,
                  :ft_num_days,
                  :ft_day_starts_at,
                  :ft_day_ends_at,
                  :ft_duration,
                  ft_days: [])
  end
end
