#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AhdEventsController < ApplicationController
  before_action :set_ad_hoc_domain_staff

  def index
    re = RotaEditor.new(
      @ad_hoc_domain_staff.rota_template,
      @ad_hoc_domain.default_day_shape)
    schedule_events = re.events
    respond_to do |format|
      format.json { render json: schedule_events }
    end
  end

  def create
    re = RotaEditor.new(
      @ad_hoc_domain_staff.rota_template,
      @ad_hoc_domain.default_day_shape)
    re.add_event(ahd_event_params[:starts_at], ahd_event_params[:ends_at])
    respond_to do |format|
      format.json
    end
  end

  def destroy
    re = RotaEditor.new(
      @ad_hoc_domain_staff.rota_template,
      @ad_hoc_domain.default_day_shape)
    re.delete_event(params[:id])
    respond_to do |format|
      format.json
    end
  end

  def update
    re = RotaEditor.new(
      @ad_hoc_domain_staff.rota_template,
      @ad_hoc_domain.default_day_shape)
    re.adjust_event(params[:id], ahd_event_params[:ends_at])
    respond_to do |format|
      format.json
    end
  end

  private

  def set_ad_hoc_domain_staff
    @ad_hoc_domain_staff =
      AdHocDomainStaff.includes(
        {rota_template: :rota_slots},
        {
          ad_hoc_domain_cycle: {
            ad_hoc_domain: {
              default_day_shape: :rota_slots
            }
          }
        }
    ).find(params[:ad_hoc_domain_staff_id])
    @ad_hoc_domain =
      @ad_hoc_domain_staff.ad_hoc_domain_cycle.
                           ad_hoc_domain
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ahd_event_params
    params.require(:ahd_event).
      permit(:starts_at, :ends_at)
  end

end

