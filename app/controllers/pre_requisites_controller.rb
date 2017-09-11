class PreRequisitesController < ApplicationController
  before_action :set_pre_requisite, only: [:show, :edit, :update, :destroy]

  # GET /pre_requisites
  # GET /pre_requisites.json
  def index
    @pre_requisites = PreRequisite.all.order(:priority)
  end

  # GET /pre_requisites/1
  # GET /pre_requisites/1.json
  def show
  end

  # GET /pre_requisites/new
  def new
    @pre_requisite = PreRequisite.new
  end

  # GET /pre_requisites/1/edit
  def edit
  end

  # POST /pre_requisites
  # POST /pre_requisites.json
  def create
    @pre_requisite = PreRequisite.new(pre_requisite_params)

    respond_to do |format|
      if @pre_requisite.save
        format.html { redirect_to pre_requisites_path, notice: 'Pre requisite was successfully created.' }
        format.json { render :show, status: :created, location: @pre_requisite }
      else
        format.html { render :new }
        format.json { render json: @pre_requisite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pre_requisites/1
  # PATCH/PUT /pre_requisites/1.json
  def update
    respond_to do |format|
      if @pre_requisite.update(pre_requisite_params)
        format.html { redirect_to pre_requisites_path, notice: 'Pre requisite was successfully updated.' }
        format.json { render :show, status: :ok, location: @pre_requisite }
      else
        format.html { render :edit }
        format.json { render json: @pre_requisite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pre_requisites/1
  # DELETE /pre_requisites/1.json
  def destroy
    @pre_requisite.destroy
    respond_to do |format|
      format.html { redirect_to pre_requisites_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pre_requisite
      @pre_requisite = PreRequisite.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pre_requisite_params
      params.require(:pre_requisite).permit(:label,
                                            :description,
                                            :element_id,
                                            :element_name,
                                            :priority)
    end
end
