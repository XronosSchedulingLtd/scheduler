class AdHocDomainStaffsController < ApplicationController

  include AdHoc

  before_action :set_ad_hoc_domain_subject, only: [:create]
  before_action :set_ad_hoc_domain_staff, only: [:destroy]

  # POST /ad_hoc_domain_subject/1/ad_hoc_domain_staffs
  # POST /ad_hoc_domain_subject/1/ad_hoc_domain_staffs.json
  def create
    @ad_hoc_domain_staff =
      @ad_hoc_domain_subject.ad_hoc_domain_staffs.new(ad_hoc_domain_staff_params)

    respond_to do |format|
      if @ad_hoc_domain_staff.save
        #
        #  We're going to need to refresh the entire listing of staffs
        #  (because our new one could be anywhere in the list), which
        #  in turn needs a whole hierarchy of new blank records.
        #
        generate_blanks(@ad_hoc_domain_subject)
        format.js { render :created,
                    locals: { owner_id: @ad_hoc_domain_subject.id} }
      else
        format.js { render :createfailed,
                    status: :conflict,
                    locals: { owner_id: @ad_hoc_domain_subject.id} }
      end
    end
  end

  # DELETE /ad_hoc_domain_staffs/1
  # DELETE /ad_hoc_domain_staffs/1.json
  def destroy
    @ad_hoc_domain_subject = @ad_hoc_domain_staff.ad_hoc_domain_subject
    @ad_hoc_domain_staff.destroy
    respond_to do |format|
      generate_blanks(@ad_hoc_domain_subject)
      format.js { render :destroyed, locals: { owner_id: @ad_hoc_domain_subject.id} }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad_hoc_domain_subject
    @ad_hoc_domain_subject =
      AdHocDomainSubject.find(params[:ad_hoc_domain_subject_id])
  end

  def set_ad_hoc_domain_staff
    @ad_hoc_domain_staff = AdHocDomainStaff.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_staff_params
    params.require(:ad_hoc_domain_staff).
           permit(:staff_element_name, :staff_element_id)
  end

end
