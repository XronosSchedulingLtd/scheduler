# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EventsourcesController < ApplicationController
  before_action :set_eventsource, only: [:show, :edit, :update, :destroy]

  # GET /eventsources
  # GET /eventsources.json
  def index
    @eventsources = Eventsource.all
  end

  # GET /eventsources/1
  # GET /eventsources/1.json
  def show
  end

  # GET /eventsources/new
  def new
    @eventsource = Eventsource.new
  end

  # GET /eventsources/1/edit
  def edit
  end

  # POST /eventsources
  # POST /eventsources.json
  def create
    @eventsource = Eventsource.new(eventsource_params)

    respond_to do |format|
      if @eventsource.save
        format.html { redirect_to eventsources_path, notice: 'Eventsource was successfully created.' }
        format.json { render :show, status: :created, location: @eventsource }
      else
        format.html { render :new }
        format.json { render json: @eventsource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /eventsources/1
  # PATCH/PUT /eventsources/1.json
  def update
    respond_to do |format|
      if @eventsource.update(eventsource_params)
        format.html { redirect_to eventsources_path, notice: 'Eventsource was successfully updated.' }
        format.json { render :show, status: :ok, location: @eventsource }
      else
        format.html { render :edit }
        format.json { render json: @eventsource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /eventsources/1
  # DELETE /eventsources/1.json
  def destroy
    @eventsource.destroy
    respond_to do |format|
      format.html { redirect_to eventsources_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_eventsource
      @eventsource = Eventsource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def eventsource_params
      params.require(:eventsource).permit(:name)
    end
end
