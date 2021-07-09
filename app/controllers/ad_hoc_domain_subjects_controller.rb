#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainSubjectsController < ApplicationController

  before_action :set_progenitors, only: [:create]
  before_action :set_ad_hoc_domain_subject, only: [:destroy]

  # POST /ad_hoc_domain_cycle/1/ad_hoc_domain_subjects.json
  # POST /ad_hoc_domain_staff/1/ad_hoc_domain_subjects.json
  def create
    #
    #  Two different ways we can be called - with or without an
    #  ad_hoc_domain_staff_id specified.
    #
    #  If none is specified then we're on the "by subject" listing
    #  page and someone has simply asked to add another subject.
    #
    #  If one has been specified, then we're on the "by staff"
    #  listing page and the user wants to add a new subject
    #  to an existing member of staff.
    #
    if @ad_hoc_domain_staff
      #
      #  Does a suitable AHD_Subject already exist?
      #
      subject_element =
        Element.find_by(
          id: ad_hoc_domain_subject_params[:subject_element_id],
          entity_type: "Subject")
      if subject_element
        @ad_hoc_domain_subject =
          @ad_hoc_domain_cycle.ad_hoc_domain_subjects.
                               find_by(subject_id: subject_element.entity_id)
      end
      if @ad_hoc_domain_subject
        #
        #  The AHD_subject record exists already. The most we can do
        #  is add another link.
        #
        respond_to do |format|
          begin
            @ad_hoc_domain_staff.ad_hoc_domain_subjects <<
              @ad_hoc_domain_subject
          rescue ActiveRecord::RecordInvalid => e
            @error_text = e.to_s
            format.js {
              render :createfailed,
                     status: :conflict,
                     locals: { parent: @ad_hoc_domain_staff }
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
        @ad_hoc_domain_subject =
          @ad_hoc_domain_cycle.ad_hoc_domain_subjects.
                                 new(ad_hoc_domain_subject_params)
        if @ad_hoc_domain_subject.save
          @ad_hoc_domain_staff.ad_hoc_domain_subjects << @ad_hoc_domain_subject
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
                       position: @ad_hoc_domain_cycle.position_of(@ad_hoc_domain_subject)
                     }
            }
          else
            format.js { render :createfailed,
                        status: :conflict,
                        locals: { parent: @ad_hoc_domain_staff } }
          end
        end
      end
    else
      #
      #  A simple request to create a new subject record.
      #
      @ad_hoc_domain_subject =
        @ad_hoc_domain_cycle.ad_hoc_domain_subjects.
                             new(ad_hoc_domain_subject_params)

      respond_to do |format|
        if @ad_hoc_domain_subject.save
          #
          #  We have a new subject record, which will appear only in the
          #  "by subject" listing (because it isn't currently linked to
          #  a staff member).  Inject it.
          #
          @ad_hoc_domain_cycle.reload
          format.js {
            render :created,
            locals: {
              position: @ad_hoc_domain_cycle.position_of(@ad_hoc_domain_subject)
            }
          }
        else
          format.js {
            render :createfailed,
            status: :conflict,
            locals: { parent: @ad_hoc_domain_cycle }
          }
        end
      end
    end
  end


  # DELETE /ad_hoc_domain_subjects/1
  # DELETE /ad_hoc_domain_subjects/1.json
  def destroy
    #
    #  Before deleting the subject we need a list of the staff previously
    #  listed as teaching it, because all their entries will need updating
    #  too.
    #
    @erstwhile_staff = @ad_hoc_domain_subject.ad_hoc_domain_staffs.to_a
    @ad_hoc_domain_subject.destroy
    respond_to do |format|
      format.js
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    #
    #  Note that we allow *any* domain controller access.  This is
    #  just possibly a security risk, but easier than checking them
    #  individually.
    #
    logged_in? && (current_user.admin || current_user.domain_controller?)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_progenitors
    #
    #  We may have been invoked in the context of a staff, or merely
    #  in the context of a cycle.
    #
    if params[:ad_hoc_domain_staff_id]
      @ad_hoc_domain_staff =
        AdHocDomainStaff.find(params[:ad_hoc_domain_staff_id])
      @ad_hoc_domain_cycle = @ad_hoc_domain_staff.ad_hoc_domain_cycle
    else
      #
      #  Not really needed, but let's be explicit.
      #
      @ad_hoc_domain_staff = nil
      @ad_hoc_domain_cycle =
        AdHocDomainCycle.find(params[:ad_hoc_domain_cycle_id])
    end
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
