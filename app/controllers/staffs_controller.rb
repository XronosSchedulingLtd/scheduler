# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'tempfile'
require 'ri_cal'

class StaffsController < ApplicationController
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  # GET /staffs
  # GET /staffs.json
  def index
    #
    #  If a preference is specified then it persists until another
    #  preference is specified.
    #
    if params[:inactive]
      selector = Staff.inactive
      session[:which_staff] = :inactive
    elsif params[:active]
      selector = Staff.active
      session[:which_staff] = :active
    elsif session[:which_staff] == :inactive.to_s
      selector = Staff.inactive
    else
      #
      #  Default to active
      #
      selector = Staff.active
    end
    @staffs = selector.page(params[:page]).order('surname')
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
    target_date = Date.today
    if target_date < Setting.current_era.starts_on
      target_date = Setting.current_era.starts_on
    elsif target_date > Setting.current_era.ends_on
      target_date = Setting.current_era.ends_on
    end
    @groups = @staff.groups(target_date, false)
  end

  # GET /staffs/new
  def new
    @staff = Staff.new
  end

  # GET /staffs/1/edit
  def edit
  end

  # POST /staffs
  # POST /staffs.json
  def create
    @staff = Staff.new(staff_params)

    respond_to do |format|
      if @staff.save
        format.html { redirect_to @staff, notice: 'Staff was successfully created.' }
        format.json { render :show, status: :created, location: @staff }
      else
        format.html { render :new }
        format.json { render json: @staff.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /staffs/1
  # PATCH/PUT /staffs/1.json
  def update
    respond_to do |format|
      if @staff.update(staff_params)
        format.html { redirect_to staffs_path, notice: 'Staff was successfully updated.' }
        format.json { render :show, status: :ok, location: @staff }
      else
        format.html { render :edit }
        format.json { render json: @staff.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /staffs/1
  # DELETE /staffs/1.json
  def destroy
    @staff.destroy
    respond_to do |format|
      format.html { redirect_to staffs_url }
      format.json { head :no_content }
    end
  end

  #  Not sure if one can set up a route for this.
  # GET /staffs/<initials>/ical
  def ical
    staff = Staff.find_by_initials(params[:id].upcase)
    era = Setting.current_era
    #
    #  Not sure how I ended up with this name, but "publish" means it gets
    #  included in ical downloads, and "for_users" means it is relevant,
    #  even if the user is not explicitly involved.
    #
    basic_categories = Eventcategory.publish
    extra_categories = Eventcategory.publish.for_users
    if staff && era
      starts_on = era.starts_on
      ends_on   = era.ends_on
      dbevents =
        (staff.element.events_on(starts_on, ends_on, basic_categories) +
         Event.events_on(starts_on, ends_on, extra_categories)).uniq
      tf = Tempfile.new(["#{staff.initials}", ".ics"])
      RiCal.Calendar do |cal|
        cal.add_x_property("X-WR-CALNAME", staff.initials)
        cal.add_x_property("X-WR-CALDESC", "#{staff.name}'s timetable")
        dbevents.each do |dbevent|
          cal.event do |event|
            event.summary = dbevent.body
            if dbevent.all_day
              event.dtstart = dbevent.starts_at.to_date
              event.dtend   = dbevent.ends_at.to_date + 1
            else
              event.dtstart = dbevent.starts_at
              event.dtend   = dbevent.ends_at
            end
            locations = dbevent.locations
            if locations.size > 0
              event.location = locations.collect {|l| l.name}.join(",")
            end
          end
        end
      end.export(tf)
      tf.close
      send_file(tf.path, :type => "application/ics")
    else
      redirect_to "/"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_staff
      @staff = Staff.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def staff_params
      params.require(:staff).permit(:name, :initials, :surname, :title, :forename, :email, :source_id, :active, :current)
    end

    def authorized?(action = action_name, resource = nil)
      (logged_in? && current_user.admin) ||
      action == 'ical'
    end

end
