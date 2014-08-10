# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class PupilsController < ApplicationController
  before_action :set_pupil, only: [:show, :edit, :update, :destroy]

  # GET /pupils
  # GET /pupils.json
  def index
    @pupils = Pupil.page(params[:page]).order('surname')
  end

  # GET /pupils/1
  # GET /pupils/1.json
  def show
    target_date = Date.today
    if target_date < Setting.current_era.starts_on
      target_date = Setting.current_era.starts_on
    elsif target_date > Setting.current_era.ends_on
      target_date = Setting.current_era.ends_on
    end
    @groups = @pupil.groups(target_date, false)
  end

  # GET /pupils/new
  def new
    @pupil = Pupil.new
  end

  # GET /pupils/1/edit
  def edit
  end

  # POST /pupils
  # POST /pupils.json
  def create
    @pupil = Pupil.new(pupil_params)

    respond_to do |format|
      if @pupil.save
        format.html { redirect_to @pupil, notice: 'Pupil was successfully created.' }
        format.json { render :show, status: :created, location: @pupil }
      else
        format.html { render :new }
        format.json { render json: @pupil.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pupils/1
  # PATCH/PUT /pupils/1.json
  def update
    respond_to do |format|
      if @pupil.update(pupil_params)
        format.html { redirect_to @pupil, notice: 'Pupil was successfully updated.' }
        format.json { render :show, status: :ok, location: @pupil }
      else
        format.html { render :edit }
        format.json { render json: @pupil.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pupils/1
  # DELETE /pupils/1.json
  def destroy
    @pupil.destroy
    respond_to do |format|
      format.html { redirect_to pupils_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pupil
      @pupil = Pupil.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pupil_params
      params.require(:pupil).permit(:name, :surname, :forename, :known_as, :email, :candidate_no, :start_year, :source_id, :current)
    end
end
