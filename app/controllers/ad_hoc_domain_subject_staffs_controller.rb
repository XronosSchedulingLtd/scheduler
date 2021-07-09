#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainSubjectStaffsController < ApplicationController
  before_action :set_ad_hoc_domain_subject_staff, only: :destroy

  def destroy
    @ad_hoc_domain_subject = @ad_hoc_domain_subject_staff.ad_hoc_domain_subject
    @ad_hoc_domain_staff = @ad_hoc_domain_subject_staff.ad_hoc_domain_staff
    @ad_hoc_domain_subject_staff.destroy
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

  def set_ad_hoc_domain_subject_staff
    @ad_hoc_domain_subject_staff = AdHocDomainSubjectStaff.find(params[:id])
  end
end


