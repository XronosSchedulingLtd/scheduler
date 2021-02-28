#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainStaffsController < ApplicationController

  before_action :set_progenitors, only: [:create]
  before_action :set_ad_hoc_domain_staff, only: [:destroy]

  # POST /ad_hoc_domain_cycle/1/ad_hoc_domain_staffs.json
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
    if @ad_hoc_domain_subject
      #
      #  Does a suitable AHD_Staff record already exist?
      #
      staff_element =
        Element.find_by(
          id: ad_hoc_domain_staff_params[:staff_element_id],
          entity_type: "Staff")
      if staff_element
        @ad_hoc_domain_staff =
          @ad_hoc_domain_cycle.ad_hoc_domain_staffs.
                               find_by(staff_id: staff_element.entity_id)
      end
      if @ad_hoc_domain_staff
        #
        #  The AHD_Staff record exists already. The most we can do
        #  is add another link.
        #
        respond_to do |format|
          begin
            @ad_hoc_domain_subject.ad_hoc_domain_staffs << @ad_hoc_domain_staff
          rescue ActiveRecord::RecordInvalid => e
            @error_text = e.to_s
            format.js {
              render :createfailed,
                     status: :conflict,
                     locals: { owner_id: @ad_hoc_domain_subject.id_suffix}
            }
          else
            @folded = false
            #
            #  At this point we need to refresh both the subject listing
            #  on the by-staff tab and the staff listing on the by-subject
            #  tab.  Both must already exist.
            #
            format.js { render :linked }
          end
        end
      else
        #
        #  Does not exist.  Need to create and link.
        #
        @ad_hoc_domain_staff =
          @ad_hoc_domain_cycle.ad_hoc_domain_staffs.
                                 new(ad_hoc_domain_staff_params)
        if @ad_hoc_domain_staff.save
          @ad_hoc_domain_subject.ad_hoc_domain_staffs << @ad_hoc_domain_staff
          result = true
        else
          result = false
        end
        respond_to do |format|
          if result
            @folded = false
            @num_staff = @ad_hoc_domain_cycle.num_real_staff
            @num_pupils = @ad_hoc_domain_cycle.num_real_pupils
            format.js {
              render :created_and_linked,
                     locals: {
                       position: @ad_hoc_domain_cycle.position_of(@ad_hoc_domain_staff)
                     }
            }
          else
            format.js { render :createfailed,
                        status: :conflict,
                        locals: { owner_id: @ad_hoc_domain_subject.id_suffix} }
          end
        end
      end
    else
      #
      #  A simple request to create a new staff record.
      #
      @ad_hoc_domain_staff =
        @ad_hoc_domain_cycle.ad_hoc_domain_staffs.
                             new(ad_hoc_domain_staff_params)

      respond_to do |format|
        if @ad_hoc_domain_staff.save
          #
          #  We have a new staff record, which will appear only in the
          #  "by staff" listing (because it isn't currently linked to
          #  a subject).  Inject it.
          #
          @ad_hoc_domain_cycle.reload
          format.js {
            render :created,
            locals: {
              position: @ad_hoc_domain_cycle.position_of(@ad_hoc_domain_staff)
            }
          }
        else
          format.js { render :createfailed,
                      status: :conflict,
                      locals: { owner_id: @ad_hoc_domain_cycle.id_suffix }}
        end
      end
    end
  end

  # DELETE /ad_hoc_domain_staffs/1
  # DELETE /ad_hoc_domain_staffs/1.json
  def destroy
    @erstwhile_subjects = @ad_hoc_domain_staff.ad_hoc_domain_subjects.to_a
    @ad_hoc_domain_cycle = @ad_hoc_domain_staff.ad_hoc_domain_cycle
    @ad_hoc_domain_staff.destroy
    respond_to do |format|
      #
      #  If we've deleted a member of staff then their entry in the
      #  by_staff tab disappears entirely, plus any entries which they
      #  had in the by_subject tab should go too.  The request must
      #  have been issued from the by_staff tab.
      #
      format.js
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_progenitors
    #
    #  We may have been invoked in the context of a subject, or merely
    #  in the context of a cycle.
    #
    if params[:ad_hoc_domain_subject_id]
      @ad_hoc_domain_subject =
        AdHocDomainSubject.find(params[:ad_hoc_domain_subject_id])
      @ad_hoc_domain_cycle = @ad_hoc_domain_subject.ad_hoc_domain_cycle
    else
      #
      #  Not really needed, but let's be explicit.
      #
      @ad_hoc_domain_subject = nil
      @ad_hoc_domain_cycle =
        AdHocDomainCycle.find(params[:ad_hoc_domain_cycle_id])
    end
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
