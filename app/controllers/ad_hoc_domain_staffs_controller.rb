#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainStaffsController < ApplicationController

  include AdHoc

  before_action :set_ad_hoc_domain_cycle, only: [:create]
  before_action :set_ad_hoc_domain_staff, only: [:destroy]

  # POST /ad_hoc_domain_subject/1/ad_hoc_domain_staffs
  # POST /ad_hoc_domain_subject/1/ad_hoc_domain_staffs.json
  def create
    #
    #  Two different ways we can be called - with or without an
    #  ad_hoc_domain_subject_id specified.
    #
    #  If none is specified then we're on the "by staff" listing
    #  page and someone has simply asked to add another member of
    #  staff.
    #
    #  If one has been specified, then we're on the "by subject"
    #  listing page and the user wants to add a new member of staff
    #  to an existing subject.
    #

    #
    #  Does a suitable AHD_Staff record already exist?
    #
    staff_element =
      Element.find_by(
        id: ad_hoc_domain_staff_params[:staff_element_id],
        entity_type: "Staff")
    if staff_element
      @ad_hoc_domain_staff =
        AdHocDomainStaff.find_by(staff_id: staff_element.entity_id)
    end
    if @ad_hoc_domain_staff
      #
      #  The AHD_Staff record exists already. The most we can do
      #  is add another link.  It is therefore a requirement that
      #  a peer_id has been specified.
      #
      @ad_hoc_domain_subject =
        AdHocDomainSubject.find_by(
          id: ad_hoc_domain_staff_params[:peer_id])
      if @ad_hoc_domain_subject
        #
        #  OK - we want to link these two, provided they are not
        #  already linked.
        #
        @ad_hoc_domain_staff.ad_hoc_domain_subjects << @ad_hoc_domain_subject
        result = true
      else
        result = false
      end
    else
      @ad_hoc_domain_staff =
        @ad_hoc_domain_cycle.ad_hoc_domain_staffs.
                               new(ad_hoc_domain_staff_params)
      if @ad_hoc_domain_staff.save
        if @ad_hoc_domain_staff.peer_id
          peer = AdHocDomainSubject.find_by(id: @ad_hoc_domain_staff.peer_id)
          if peer
            @ad_hoc_domain_staff.ad_hoc_domain_subjects << peer
          end
        end
        result = true
      else
        result = false
      end
    end
    respond_to do |format|
      if result
        #
        #  We're going to need to refresh the entire listing of staffs
        #  (because our new one could be anywhere in the list), which
        #  in turn needs a whole hierarchy of new blank records.
        #
        generate_blanks(@ad_hoc_domain_cycle)
        @folded = false
        @num_staff = @ad_hoc_domain_cycle.num_real_staff
        @num_pupils = @ad_hoc_domain_cycle.num_real_pupils
        format.js { render :created,
                    locals: { owner_id: @ad_hoc_domain_cycle.id} }
      else
        format.js { render :createfailed,
                    status: :conflict,
                    locals: { owner_id: @ad_hoc_domain_cycle.id} }
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
      @folded = false
      @num_staff = @ad_hoc_domain_subject.num_real_staff
      @num_pupils = @ad_hoc_domain_subject.num_real_pupils
      format.js { render :destroyed, locals: { owner_id: @ad_hoc_domain_subject.id} }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad_hoc_domain_cycle
    @ad_hoc_domain_cycle =
      AdHocDomainCycle.find(params[:ad_hoc_domain_cycle_id])
  end

  def set_ad_hoc_domain_staff
    @ad_hoc_domain_staff = AdHocDomainStaff.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_staff_params
    params.require(:ad_hoc_domain_staff).
           permit(:staff_element_name, :staff_element_id, :peer_id)
  end

end
