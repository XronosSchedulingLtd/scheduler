class RotaSlotsController < ApplicationController
  before_action :find_rota_template
  before_action :set_rota_slot, only: [:show, :update, :destroy]

  # GET /rota_template/1/rota_slots.json
  def index
    @rota_slots = @rota_template.rota_slots
  end

  # GET /rota_slots/1.json
  def show
  end

  # POST /rota_templates/1/rota_slots.json
  def create
    @rota_slot = @rota_template.rota_slots.new(rota_slot_params)

    respond_to do |format|
      if @rota_slot.save
        format.json { render :show, status: :created }
      else
        format.json { render json: @rota_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rota_slots/1.json
  def update
    respond_to do |format|
      if @rota_slot.update(rota_slot_params)
        format.json { render :show, status: :ok }
      else
        format.json { render json: @rota_slot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rota_slots/1.json
  def destroy
    @rota_slot.destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

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
