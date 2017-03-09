class ExamCyclesController < ApplicationController
  before_action :set_exam_cycle, only: [:show, :edit, :update, :destroy]

  # GET /exam_cycles
  # GET /exam_cycles.json
  def index
    @exam_cycles = ExamCycle.page(params[:page]).order('starts_on').reverse_order
  end

  # GET /exam_cycles/1
  # GET /exam_cycles/1.json
  def show
  end

  # GET /exam_cycles/new
  def new
    @exam_cycle = ExamCycle.new
  end

  # GET /exam_cycles/1/edit
  def edit
  end

  # POST /exam_cycles
  # POST /exam_cycles.json
  def create
    @exam_cycle = ExamCycle.new(exam_cycle_params)

    respond_to do |format|
      if @exam_cycle.save
        format.html { redirect_to exam_cycles_url, notice: 'Exam cycle was created successfully.' }
        format.json { render :show, status: :created, location: @exam_cycle }
      else
        format.html { render :new }
        format.json { render json: @exam_cycle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exam_cycles/1
  # PATCH/PUT /exam_cycles/1.json
  def update
    respond_to do |format|
      if @exam_cycle.update(exam_cycle_params)
        format.html { redirect_to exam_cycles_url, notice: 'Exam cycle was updated successfully.' }
        format.json { render :show, status: :ok, location: @exam_cycle }
      else
        format.html { render :edit }
        format.json { render json: @exam_cycle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exam_cycles/1
  # DELETE /exam_cycles/1.json
  def destroy
    @exam_cycle.destroy
    respond_to do |format|
      format.html { redirect_to exam_cycles_url }
      format.json { head :no_content }
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_exam_cycle
      @exam_cycle = ExamCycle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exam_cycle_params
      params.require(:exam_cycle).permit(:name,
                                         :default_rota_template_id,
                                         :default_group_element_id,
                                         :default_group_element_name,
                                         :default_quantity,
                                         :starts_on_text,
                                         :ends_on_text)
    end
end
