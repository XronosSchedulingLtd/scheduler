class RotaTemplatesController < ApplicationController
  before_action :set_rota_template, only: [:show,
                                           :edit,
                                           :update,
                                           :destroy,
                                           :do_clone]

  # GET /rota_templates
  # GET /rota_templates.json
  def index
    @rota_templates = RotaTemplate.page(params[:page]).order('name')
  end

  # GET /rota_templates/1
  # GET /rota_templates/1.json
  def show
  end

  # GET /rota_templates/new
  def new
    @rota_template = RotaTemplate.new
  end

  # GET /rota_templates/1/edit
  def edit
  end

  # POST /rota_templates
  # POST /rota_templates.json
  def create
    @rota_template = RotaTemplate.new(rota_template_params)

    respond_to do |format|
      if @rota_template.save
        format.html { redirect_to @rota_template, notice: 'Rota template was successfully created.' }
        format.json { render :show, status: :created, location: @rota_template }
      else
        format.html { render :new }
        format.json { render json: @rota_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rota_templates/1
  # PATCH/PUT /rota_templates/1.json
  def update
    respond_to do |format|
      if @rota_template.update(rota_template_params)
        format.html { redirect_to @rota_template, notice: 'Rota template was successfully updated.' }
        format.json { render :show, status: :ok, location: @rota_template }
      else
        format.html { render :edit }
        format.json { render json: @rota_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rota_templates/1
  # DELETE /rota_templates/1.json
  def destroy
    @rota_template.destroy
    respond_to do |format|
      format.html { redirect_to rota_templates_url }
      format.json { head :no_content }
    end
  end

  # POST /rota_templates/1/do_clone
  def do_clone
    @new_template = @rota_template.do_clone
    redirect_to rota_templates_path
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_rota_template
      @rota_template = RotaTemplate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rota_template_params
      params.require(:rota_template).permit(:name)
    end
end