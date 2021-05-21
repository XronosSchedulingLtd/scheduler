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
                                                     :destroy]

  before_action :set_staff_and_allocation, only: [:allocate, :save]

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

  # PATCH ad_hoc_domain_staff/1/ad_hoc_domain_allocation/1/save
  #
  def save
    #
    #  We are receiving a list of allocations for one staff member
    #  within an ad_hoc_allocation.  Note it's for one staff member,
    #  not for one subject.  If a single staff member teaches more
    #  than one subject then we handle all their allocations
    #  together.
    #
    Rails.logger.debug(ad_hoc_domain_allocation_params[:allocations].inspect)
    respond_to do |format|
      if @ad_hoc_domain_allocation.update_allocations(
          @ad_hoc_domain_staff,
          ad_hoc_domain_allocation_params.to_h[:allocations])
        format.json
      else
        format.json { render :save_failed, status: 99 }
      end
    end
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
    #
    #  No further action required, but this method is actually
    #  used.
    #
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
      permit(:name, allocations: [:starts_at, :ends_at, :pcid])
  end

end

