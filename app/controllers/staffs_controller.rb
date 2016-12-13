# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_staff
      @staff = Staff.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def staff_params
      params.require(:staff).permit(:name,
                                    :initials,
                                    :surname,
                                    :title,
                                    :forename,
                                    :email,
                                    :source_id,
                                    :active,
                                    :current,
                                    :multicover)
    end

    def authorized?(action = action_name, resource = nil)
      (logged_in? && current_user.admin)
    end

end
