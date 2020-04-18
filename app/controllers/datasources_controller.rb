# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class DatasourcesController < ApplicationController
  before_action :set_datasource, only: [:show, :edit, :update, :destroy]

  # GET /datasources
  # GET /datasources.json
  def index
    @datasources = Datasource.all
  end

  # GET /datasources/1
  # GET /datasources/1.json
  def show
  end

  # GET /datasources/new
  def new
    @datasource = Datasource.new
  end

  # GET /datasources/1/edit
  def edit
  end

  # POST /datasources
  # POST /datasources.json
  def create
    @datasource = Datasource.new(datasource_params)

    respond_to do |format|
      if @datasource.save
        format.html { redirect_to datasources_path, notice: 'Datasource was successfully created.' }
        format.json { render :show, status: :created, location: @datasource }
      else
        format.html { render :new }
        format.json { render json: @datasource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datasources/1
  # PATCH/PUT /datasources/1.json
  def update
    respond_to do |format|
      if @datasource.update(datasource_params)
        format.html { redirect_to datasources_path, notice: 'Datasource was successfully updated.' }
        format.json { render :show, status: :ok, location: @datasource }
      else
        format.html { render :edit }
        format.json { render json: @datasource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /datasources/1
  # DELETE /datasources/1.json
  def destroy
    if @datasource.can_destroy?
      @datasource.destroy
      respond_to do |format|
        format.html { redirect_to datasources_url }
        format.json { head :no_content }
      end
    else
      redirect_back fallback_location: root_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datasource
      @datasource = Datasource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def datasource_params
      params.require(:datasource).permit(:name)
    end
end
