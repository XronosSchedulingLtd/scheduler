#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainCyclesController < ApplicationController
  before_action :set_ad_hoc_domain, only: [:new, :create]

  def new
    @ad_hoc_domain_cycle = @ad_hoc_domain.ad_hoc_domain_cycles.new
  end

  def create
    @ad_hoc_domain_cycle =
      @ad_hoc_domain.ad_hoc_domain_cycles.new(ad_hoc_domain_cycle_params)
    respond_to do |format|
      if @ad_hoc_domain_cycle.save
        format.html { redirect_to ad_hoc_domain_url(@ad_hoc_domain)}
      else
        format.html { render :new }
      end
    end
  end

  private

  def set_ad_hoc_domain
    @ad_hoc_domain = AdHocDomain.find(params[:ad_hoc_domain_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_cycle_params
    params.require(:ad_hoc_domain_cycle).
           permit(:name,
                  :starts_on,
                  :ends_on)
  end

end

