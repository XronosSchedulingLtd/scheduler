class TutorgroupsController < ApplicationController
  before_action :set_tutorgroup, only: [:show, :edit, :update, :destroy]

  # GET /tutorgroups
  # GET /tutorgroups.json
  def index
    @tutorgroups = Tutorgroup.page(params[:page]).order('start_year DESC')
  end

  # GET /tutorgroups/1
  # GET /tutorgroups/1.json
  def show
  end

  # GET /tutorgroups/new
  def new
    @tutorgroup = Tutorgroup.new
  end

  # GET /tutorgroups/1/edit
  def edit
  end

  # POST /tutorgroups
  # POST /tutorgroups.json
  def create
    @tutorgroup = Tutorgroup.new(tutorgroup_params)

    respond_to do |format|
      if @tutorgroup.save
        format.html { redirect_to @tutorgroup, notice: 'Tutorgroup was successfully created.' }
        format.json { render :show, status: :created, location: @tutorgroup }
      else
        format.html { render :new }
        format.json { render json: @tutorgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tutorgroups/1
  # PATCH/PUT /tutorgroups/1.json
  def update
    respond_to do |format|
      if @tutorgroup.update(tutorgroup_params)
        format.html { redirect_to @tutorgroup, notice: 'Tutorgroup was successfully updated.' }
        format.json { render :show, status: :ok, location: @tutorgroup }
      else
        format.html { render :edit }
        format.json { render json: @tutorgroup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tutorgroups/1
  # DELETE /tutorgroups/1.json
  def destroy
    @tutorgroup.destroy
    respond_to do |format|
      format.html { redirect_to tutorgroups_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tutorgroup
      @tutorgroup = Tutorgroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tutorgroup_params
      params.require(:tutorgroup).permit(:name, :house, :staff_id, :era_id, :start_year, :current)
    end
end
