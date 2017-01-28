class RotaSlotsController < ApplicationController
  before_action :set_rota_slot, only: [:show, :edit, :update, :destroy]

  # GET /rota_slots
  # GET /rota_slots.json
  def index
    @rota_slots = RotaSlot.all
  end

  # GET /rota_slots/1
  # GET /rota_slots/1.json
  def show
  end

  # GET /rota_slots/new
  def new
    @rota_slot = RotaSlot.new
  end

  # GET /rota_slots/1/edit
  def edit
  end

  # POST /rota_slots
  # POST /rota_slots.json
  def create
    @rota_slot = RotaSlot.new(rota_slot_params)

    respond_to do |format|
      if @rota_slot.save
        format.html { redirect_to @rota_slot, notice: 'Rota slot was successfully created.' }
        format.json { render :show, status: :created }
      else
        format.html { render :new }
        format.json { render json: @rota_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rota_slots/1
  # PATCH/PUT /rota_slots/1.json
  def update
    respond_to do |format|
      if @rota_slot.update(rota_slot_params)
        format.html { redirect_to @rota_slot, notice: 'Rota slot was successfully updated.' }
        format.json { render :show, status: :ok, location: @rota_slot }
      else
        format.html { render :edit }
        format.json { render json: @rota_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rota_slots/1
  # DELETE /rota_slots/1.json
  def destroy
    @rota_slot.destroy
    respond_to do |format|
      format.html { redirect_to rota_slots_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rota_slot
      @rota_slot = RotaSlot.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rota_slot_params
      params.require(:rota_slot).permit(:rota_template_id,
                                        :starts_at,
                                        :ends_at,
                                        :days => [])
    end
end
