class AdHocDomainsController < ApplicationController

  include AdHoc

  before_action :set_ad_hoc_domain,
                only: [
                  :show,
                  :edit,
                  :update,
                  :destroy,
                  :edit_controllers,
                  :add_controller,
                  :remove_controller]

  # GET /ad_hoc_domains
  # GET /ad_hoc_domains.json
  def index
    @ad_hoc_domains = AdHocDomain.all
  end

  # GET /ad_hoc_domains/new
  def new
    @ad_hoc_domain = AdHocDomain.new
    set_day_shapes
  end

  # GET /ad_hoc_domains/1
  def show
    #
    #  Need a blank AdHocDomainSubject to support the dialogue for
    #  creating a new one.
    #
    #  The following line has the effect of adding a new, blank
    #  ahds to the array which our in-memory ahd has.
    #
    #  Our "sort" method always puts new records at the end, so we end
    #  up with a form at the end of all the real records.
    #
    generate_blanks(@ad_hoc_domain)
#    @ad_hoc_domain.ad_hoc_domain_subjects.each do |ahdsubject|
#      ahdsubject.ad_hoc_domain_staffs.each do |ahdstaff|
#        ahdstaff.ad_hoc_domain_pupil_courses.new
#      end
#      ahdsubject.ad_hoc_domain_staffs.new
#    end
#    @ad_hoc_domain.ad_hoc_domain_subjects.new
  end

  # GET /ad_hoc_domains/1/edit
  def edit
    set_day_shapes
  end

  # POST /ad_hoc_domains
  # POST /ad_hoc_domains.json
  def create
    @ad_hoc_domain = AdHocDomain.new(ad_hoc_domain_params)
    set_day_shapes

    respond_to do |format|
      if @ad_hoc_domain.save
        format.html { redirect_to ad_hoc_domains_url, notice: 'Ad hoc domain was successfully created.' }
        format.json { render :show, status: :created, location: @ad_hoc_domain }
      else
        format.html { render :new }
        format.json { render json: @ad_hoc_domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ad_hoc_domains/1
  # PATCH/PUT /ad_hoc_domains/1.json
  def update
    respond_to do |format|
      if @ad_hoc_domain.update(ad_hoc_domain_params)
        format.html { redirect_to ad_hoc_domains_url, notice: 'Ad hoc domain was successfully updated.' }
        format.json { render :show, status: :ok, location: @ad_hoc_domain }
      else
        format.html { render :edit }
        format.json { render json: @ad_hoc_domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ad_hoc_domains/1
  # DELETE /ad_hoc_domains/1.json
  def destroy
    @ad_hoc_domain.destroy
    respond_to do |format|
      format.html { redirect_to ad_hoc_domains_url, notice: 'Ad hoc domain was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /ad_hoc_domains/1/edit_controllers
  def edit_controllers
  end

  # PATCH /ad_hoc_domains/1/add_controller
  def add_controller
    new_controller_id = params[:ad_hoc_domain][:new_controller_id]
    #
    #  Use find_by because we don't want an error if the id is no good.
    #
    user = User.includes(:ad_hoc_domains).find_by(id: new_controller_id)
    if user
      unless user.controls?(@ad_hoc_domain)
        @ad_hoc_domain.controllers << user
      end
    end
    respond_to do |format|
      format.html { render :edit_controllers }
      format.js { }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad_hoc_domain
    @ad_hoc_domain = AdHocDomain.preload(:ad_hoc_domain_subjects).find(params[:id])
  end

  def set_day_shapes
    tt = DayShapeManager.template_type
    if tt
      @day_shapes = tt.rota_templates
    else
      @day_shapes = []
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_params
    params.require(:ad_hoc_domain).
           permit(:name,
                  :eventsource_id,
                  :datasource_id,
                  :eventcategory_id,
                  :connected_property_element_id,
                  :connected_property_element_name,
                  :default_day_shape_id)
  end

end
