# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'tempfile'
require 'ri_cal'

class StaffsController < ApplicationController
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = Staff.page(params[:page]).order('surname')
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
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
        format.html { redirect_to @staff, notice: 'Staff was successfully updated.' }
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
    era = Era.find_by_name("Academic Year 2014/15")
    if staff && era
      starts_on = era.starts_on
      ends_on   = era.ends_on
      dbevents = staff.events_on(starts_on, ends_on) +
                 Event.weekletter_category.events_on(starts_on, ends_on)
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
end
