class AdHocDomainSubjectsController < ApplicationController

  include AdHoc

  before_action :set_ad_hoc_domain, only: [:create]
  before_action :set_ad_hoc_domain_subject, only: [:destroy]

  # GET /ad_hoc_domains
  # GET /ad_hoc_domains.json
  def index
    @ad_hoc_domains = AdHocDomain.all
  end

  # POST /ad_hoc_domain/1/ad_hoc_domain_subjects
  # POST /ad_hoc_domain/1/ad_hoc_domain_subjects.json
  def create
    @ad_hoc_domain_subject =
      @ad_hoc_domain.ad_hoc_domain_subjects.new(ad_hoc_domain_subject_params)

    respond_to do |format|
      if @ad_hoc_domain_subject.save
        #
        #  We're going to need to refresh the entire listing of subjects
        #  (because our new one could be anywhere in the list), which
        #  in turn needs a whole hierarchy of new blank records.
        #
        generate_blanks(@ad_hoc_domain)
        format.js { render :created, locals: { owner_id: @ad_hoc_domain.id} }
      else
        format.js { render :createfailed, status: :conflict }
      end
    end
  end

  # DELETE /ad_hoc_domain_subjects/1
  # DELETE /ad_hoc_domain_subjects/1.json
  def destroy
    @ad_hoc_domain = @ad_hoc_domain_subject.ad_hoc_domain
    @ad_hoc_domain_subject.destroy
    respond_to do |format|
      generate_blanks(@ad_hoc_domain)
      format.js { render :destroyed, locals: { owner_id: @ad_hoc_domain.id} }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad_hoc_domain
    @ad_hoc_domain = AdHocDomain.find(params[:ad_hoc_domain_id])
  end

  def set_ad_hoc_domain_subject
    @ad_hoc_domain_subject = AdHocDomainSubject.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_subject_params
    params.require(:ad_hoc_domain_subject).
           permit(:subject_element_name, :subject_element_id)
  end

end
