# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EventcategoriesController < ApplicationController
  before_action :set_eventcategory, only: [:show, :edit, :update, :destroy]

  # GET /eventcategories
  # GET /eventcategories.json
  def index
    @eventcategories = Eventcategory.all.order("name")
  end

  # GET /eventcategories/1
  # GET /eventcategories/1.json
  def show
  end

  # GET /eventcategories/new
  def new
    @eventcategory = Eventcategory.new
  end

  # GET /eventcategories/1/edit
  def edit
  end

  # POST /eventcategories
  # POST /eventcategories.json
  def create
    @eventcategory = Eventcategory.new(eventcategory_params)

    respond_to do |format|
      if @eventcategory.save
        format.html { redirect_to eventcategories_path, notice: 'Eventcategory was successfully created.' }
        format.json { render :show, status: :created, location: @eventcategory }
      else
        format.html { render :new }
        format.json { render json: @eventcategory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /eventcategories/1
  # PATCH/PUT /eventcategories/1.json
  def update
    respond_to do |format|
      if @eventcategory.update(eventcategory_params)
        format.html { redirect_to eventcategories_path, notice: 'Eventcategory was successfully updated.' }
        format.json { render :show, status: :ok, location: @eventcategory }
      else
        format.html { render :edit }
        format.json { render json: @eventcategory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /eventcategories/1
  # DELETE /eventcategories/1.json
  def destroy
    @eventcategory.destroy
    respond_to do |format|
      format.html { redirect_to eventcategories_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_eventcategory
      @eventcategory = Eventcategory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def eventcategory_params
      params.require(:eventcategory).permit(:name, :pecking_order, :schoolwide, :publish, :unimportant, :can_merge, :can_borrow, :compactable, :deprecated, :privileged)
    end
end
