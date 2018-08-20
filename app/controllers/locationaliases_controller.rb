# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class LocationaliasesController < ApplicationController
  before_action :set_locationalias, only: [:show, :edit, :update, :destroy]

  # GET /locationaliases
  # GET /locationaliases.json
  def index
    @locationaliases = Locationalias.page(params[:page]).order('name')
  end

  # GET /locationaliases/1
  # GET /locationaliases/1.json
  def show
  end

  # GET /locationaliases/new
  def new
    session[:new_locationalias_from] = request.env['HTTP_REFERER']
    @locationalias = Locationalias.new
  end

  # GET /locationaliases/1/edit
  def edit
    session[:editing_locationalias_from] = request.env['HTTP_REFERER']
  end

  # POST /locationaliases
  # POST /locationaliases.json
  def create
    @locationalias = Locationalias.new(locationalias_params)

    respond_to do |format|
      if @locationalias.save
        format.html { redirect_to session[:new_locationalias_from], notice: 'Locationalias was successfully created.' }
        format.json { render :show, status: :created, location: @locationalias }
      else
        format.html { render :new }
        format.json { render json: @locationalias.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locationaliases/1
  # PATCH/PUT /locationaliases/1.json
  def update
    respond_to do |format|
      if @locationalias.update(locationalias_params)
        format.html { redirect_to session[:editing_locationalias_from], notice: 'Locationalias was successfully updated.' }
        format.json { render :show, status: :ok, location: @locationalias }
      else
        format.html { render :edit }
        format.json { render json: @locationalias.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locationaliases/1
  # DELETE /locationaliases/1.json
  def destroy
    @locationalias.destroy
    respond_to do |format|
      format.html { redirect_to locationaliases_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_locationalias
      @locationalias = Locationalias.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def locationalias_params
      params.require(:locationalias).permit(:name, :source_id, :location_id, :display, :friendly)
    end
end
