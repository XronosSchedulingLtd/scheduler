class ErasController < ApplicationController
  before_action :set_era, only: [:show, :edit, :update, :destroy]

  # GET /eras
  # GET /eras.json
  def index
    @eras = Era.all
    if request.xhr?
      render :layout => false
    else
      render
    end
  end

  # GET /eras/1
  # GET /eras/1.json
  def show
  end

  # GET /eras/new
  def new
    @era = Era.new
  end

  # GET /eras/1/edit
  def edit
  end

  # POST /eras
  # POST /eras.json
  def create
    @era = Era.new(era_params)

    respond_to do |format|
      if @era.save
        format.html { redirect_to @era, notice: 'Era was successfully created.' }
        format.json { render :show, status: :created, location: @era }
      else
        format.html { render :new }
        format.json { render json: @era.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /eras/1
  # PATCH/PUT /eras/1.json
  def update
    respond_to do |format|
      if @era.update(era_params)
        format.html { redirect_to @era, notice: 'Era was successfully updated.' }
        format.json { render :show, status: :ok, location: @era }
      else
        format.html { render :edit }
        format.json { render json: @era.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /eras/1
  # DELETE /eras/1.json
  def destroy
    @era.destroy
    respond_to do |format|
      format.html { redirect_to eras_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_era
      @era = Era.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def era_params
      params.require(:era).permit(:name, :starts_on, :ends_on)
    end
end
