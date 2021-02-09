#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainsController < ApplicationController

  class PseudoStaff
    #
    #  Used simply for displaying our info sorted by staff member.
    #
    include Comparable

    attr_reader :staff,
                :staff_name,
                :num_real_subjects,
                :num_real_pupils,
                :ad_hoc_domain_subjects

    def initialize(ad_hoc_domain_staffs)
      @staff = ad_hoc_domain_staffs[0].staff
      @staff_name = ad_hoc_domain_staffs[0].staff_name
      @num_real_subjects = ad_hoc_domain_staffs.size
      @num_real_pupils = ad_hoc_domain_staffs.inject(0) {|sum, s| sum + s.num_real_pupils}
      @ad_hoc_domain_subjects = ad_hoc_domain_staffs.collect {|s| s.ad_hoc_domain_subject}.sort
    end

    def to_partial_path
      'pseudo_staff'
    end

    def <=>(other)
      if other.instance_of?(PseudoStaff)
        #
        if self.staff
          if other.staff
            result = self.staff <=> other.staff
            if result == 0
              #  We must return 0 iff we are the same record.
              result = self.id <=> other.id
            end
          else
            #
            #  Other is not yet complete.  Put it last.
            #
            result = -1
          end
        else
          #
          #  We are incomplete and go last.
          #
          result = 1
        end
      else
        result = nil
      end
      result
    end

  end

  include AdHoc

  before_action :set_ad_hoc_domain,
                only: [
                  :edit,
                  :update,
                  :destroy,
                  :edit_controllers,
                  :add_controller,
                  :remove_controller]
  before_action :set_ad_hoc_domain_et_al, only: [:show]

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
    #  Before we can do a sensible "show", we need at least one cycle.
    #  If we do have one or more cycles, then we will show the one
    #  requested in the URL, or the default one.
    #
    #  First, do we have any?
    #
    if @ad_hoc_domain.ad_hoc_domain_cycles.empty?
      @have_cycles = false
      @active_tab = 0
    else
      @have_cycles = true
      @active_tab = 1
      #
      #  Given that we have at least one cycle, the question then arises
      #  of which one to show.  In order:
      #
      #  * The one specified in the URL
      #  * The currently configured default one
      #  * The last one chronologically
      #
      if params[:cycle_id]
        @ad_hoc_domain_cycle =
          @ad_hoc_domain.ad_hoc_domain_cycles.find_by(id: params[:cycle_id])
      end
      unless @ad_hoc_domain_cycle
        #
        #  Either nothing was specified, or it was invalid.
        #
        @ad_hoc_domain_cycle = @ad_hoc_domain.default_cycle
      end
      unless @ad_hoc_domain_cycle
        #
        #  Still nothing.  Take the last one.
        #
        @ad_hoc_domain_cycle = @ad_hoc_domain.ad_hoc_domain_cycles.sort.last
      end
      #
      #  Has the requester specified a particular tab to make active?
      #  Note that passing a non-numeric parameter here will send you
      #  to tab 0, because that's how to_i works.
      #
      if params[:tab]
        @active_tab = params[:tab].to_i
      end
      #
      #  Now let's pre-load all the records below the chosen cycle.
      #  This also involves reloading the one which we've chosen.
      #
      cycle_id = @ad_hoc_domain_cycle.id
      @ad_hoc_domain_cycle =
        @ad_hoc_domain.ad_hoc_domain_cycles.
                       includes(
                         ad_hoc_domain_subjects: [
                           :subject,
                           {
                             ad_hoc_domain_staffs: [
                               :staff,
                               {
                                 ad_hoc_domain_pupil_courses: [pupil: :element]
                               }
                             ]
                           }
                         ]).find_by(id: cycle_id)

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
      generate_blanks(@ad_hoc_domain_cycle)
      @folded = true
      @pseudo_staffs =
        @ad_hoc_domain_cycle.ad_hoc_domain_staffs.
                       group_by {|ahds| ahds.staff_id}.
                       values.
                       collect {|arr| PseudoStaff.new(arr)}.sort
    end
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
    @ad_hoc_domain = AdHocDomain.find(params[:id])
  end

  def set_ad_hoc_domain_et_al
    #
    #  Get the cycles as well for now.
    #
    @ad_hoc_domain =
      AdHocDomain.includes(:ad_hoc_domain_cycles).find(params[:id])
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
                  :default_day_shape_id,
                  :default_lesson_mins,
                  :mins_step)
  end

end
