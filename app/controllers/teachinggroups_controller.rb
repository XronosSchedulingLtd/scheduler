class TeachinggroupsController < ApplicationController
  before_action :set_teachinggroup, only: [:show, :edit, :update, :destroy]

  # GET /teachinggroups
  # GET /teachinggroups.json
  def index
    @teachinggroups = Teachinggroup.page(params[:page]).order('name')
  end

  # GET /teachinggroups/1
  # GET /teachinggroups/1.json
  def show
  end

  # GET /teachinggroups/new
  def new
    @teachinggroup = Teachinggroup.new
  end

  # GET /teachinggroups/1/edit
  def edit
  end

  # POST /teachinggroups
  # POST /teachinggroups.json
  def create
    @teachinggroup = Teachinggroup.new(teachinggroup_params)

    respond_to do |format|
      if @teachinggroup.save
        format.html { redirect_to @teachinggroup, notice: 'Teachinggroup was successfully created.' }
        format.json { render :show, status: :created, location: @teachinggroup }
      else
        format.html { render :new }
        format.json { render json: @teachinggroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teachinggroups/1
  # PATCH/PUT /teachinggroups/1.json
  def update
    respond_to do |format|
      if @teachinggroup.update(teachinggroup_params)
        format.html { redirect_to @teachinggroup, notice: 'Teachinggroup was successfully updated.' }
        format.json { render :show, status: :ok, location: @teachinggroup }
      else
        format.html { render :edit }
        format.json { render json: @teachinggroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teachinggroups/1
  # DELETE /teachinggroups/1.json
  def destroy
    @teachinggroup.destroy
    respond_to do |format|
      format.html { redirect_to teachinggroups_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_teachinggroup
      @teachinggroup = Teachinggroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def teachinggroup_params
      params.require(:teachinggroup).permit(:name, :era_id, :current, :source_id)
    end
end
