#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainAllocationsController < ApplicationController
  before_action :set_ad_hoc_domain_cycle, only: [:new, :create]

  before_action :set_ad_hoc_domain_allocation, only: [:edit,
                                                     :update,
                                                     :show,
                                                     :destroy,
                                                     :allocate]

  before_action :set_staff_and_allocation, only: [:allocate]

  def new
    @ad_hoc_domain_allocation =
      @ad_hoc_domain_cycle.ad_hoc_domain_allocations.new
  end

  def create
    @ad_hoc_domain_allocation =
      @ad_hoc_domain_cycle.ad_hoc_domain_allocations.new(
        ad_hoc_domain_allocation_params)
    respond_to do |format|
      if @ad_hoc_domain_allocation.save
        format.html {
          redirect_to ad_hoc_domain_url(
            @ad_hoc_domain_cycle.ad_hoc_domain,
            params: {
              cycle_id: @ad_hoc_domain_cycle.id,
              tab: 3
            }
          )
        }
      else
        format.html { render :new }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @ad_hoc_domain_allocation.update(ad_hoc_domain_allocation_params)
        format.html {
          redirect_to ad_hoc_domain_url(
            @ad_hoc_domain_allocation.ad_hoc_domain_cycle.ad_hoc_domain,
            params: {
              cycle_id: @ad_hoc_domain_allocation.ad_hoc_domain_cycle_id,
              tab: 3
            }
          )
        }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @ad_hoc_domain_cycle = @ad_hoc_domain_allocation.ad_hoc_domain_cycle
    @ad_hoc_domain = @ad_hoc_domain_cycle.ad_hoc_domain
    @ad_hoc_domain_allocation.destroy
    redirect_to ad_hoc_domain_url(
      @ad_hoc_domain,
      params: {
        cycle_id: @ad_hoc_domain_cycle.id,
        tab: 3
      }
    )
  end

  #
  #  What we show is a listing of the relevant staff and how we're getting
  #  on at allocating them.
  #
  def show
    @staffs =
      @ad_hoc_domain_allocation.ad_hoc_domain_cycle.
                                ad_hoc_domain_staffs.
                                sort
  end

  def allocate
  end

  private

  def set_ad_hoc_domain_cycle
    @ad_hoc_domain_cycle = AdHocDomainCycle.find(params[:ad_hoc_domain_cycle_id])
  end

  def set_ad_hoc_domain_allocation
    @ad_hoc_domain_allocation = AdHocDomainAllocation.find(params[:id])
  end

  def set_staff_and_allocation
    @ad_hoc_domain_staff =
      AdHocDomainStaff.find(params[:ad_hoc_domain_staff_id])
    @ad_hoc_domain_allocation =
      AdHocDomainAllocation.find(params[:id])

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_allocation_params
    params.require(:ad_hoc_domain_allocation).
           permit(:name)
  end

end

