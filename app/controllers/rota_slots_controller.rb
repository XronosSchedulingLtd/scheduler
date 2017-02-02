class RotaSlotsController < ApplicationController
  before_action :find_rota_template
  before_action :set_rota_slot, only: [:show, :edit, :update, :destroy]

  # GET /rota_template/1/rota_slots
  # GET /rota_template/1/rota_slots.json
  def index
    @rota_slots = @rota_template.rota_slots
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

  # POST /rota_templates/1/rota_slots
  # POST /rota_templates/1/rota_slots.json
  def create
    @rota_slot = @rota_template.rota_slots.new(rota_slot_params)

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
        format.json { render :show, status: :ok }
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

    def find_rota_template
      @rota_template = RotaTemplate.find(params[:rota_template_id])
    end
                                         
    # Never trust parameters from the scary internet, only allow the white list through.
    def rota_slot_params
      params.require(:rota_slot).permit(:starts_at,
                                        :ends_at,
                                        :days => [])
    end
end
