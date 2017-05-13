class RotaTemplatesController < ApplicationController
  before_action :find_rota_template_type, only: [:index, :new, :create]
  before_action :set_rota_template, only: [:show,
                                           :edit,
                                           :update,
                                           :destroy,
                                           :do_clone]

  # GET /rota_template_type/:id/rota_templates
  def index
    @rota_templates =
      @rota_template_type.rota_templates.page(params[:page]).order('name')
  end

  # GET /rota_templates/1
  # GET /rota_templates/1.json
  def show
  end

  # GET /rota_template_type/:id/rota_templates/new
  def new
    @rota_template = @rota_template_type.rota_templates.new
  end

  # GET /rota_templates/1/edit
  def edit
  end

  # POST /rota_template_type/:id/rota_templates
  def create
    @rota_template =
      @rota_template_type.rota_templates.new(rota_template_params)

    respond_to do |format|
      if @rota_template.save
        TemplateManager.flush_all
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
    rota_template_type = @rota_template.rota_template_type
    @rota_template.destroy
    TemplateManager.flush_all
    respond_to do |format|
      format.html { redirect_to rota_template_type_rota_templates_url(rota_template_type) }
      format.json { head :no_content }
    end
  end

  # POST /rota_templates/1/do_clone
  def do_clone
    @new_template = @rota_template.do_clone
    TemplateManager.flush_all
    redirect_to rota_template_type_rota_templates_path(@rota_template.rota_template_type)
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_rota_template
      @rota_template = RotaTemplate.find(params[:id])
    end

    def find_rota_template_type
      @rota_template_type =
        RotaTemplateType.find(params[:rota_template_type_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rota_template_params
      params.require(:rota_template).permit(:name)
    end
end
