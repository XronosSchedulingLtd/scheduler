#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainAllocationsController < ApplicationController
  layout 'allocate', only: [:allocate]

  before_action :set_ad_hoc_domain_cycle, only: [:new, :create]

  before_action :set_ad_hoc_domain_allocation, only: [
    :edit,
    :update,
    :show,
    :destroy,
    :generate,
    :do_clone
  ]

  before_action :set_staff_and_allocation, only: [
    :allocate,
    :autoallocate,
    :save]

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

  # POST ad_hoc_domain_allocation/1/generate
  def generate
    #
    #  Generate a set of events to suit this AdHocDomainAllocation,
    #  keeping any appropriate ones which are already there, but
    #  deleting any spurious ones which we don't want.
    #
    #  Due to a deficiency in the design of ActiveJob, it is not
    #  easy to pass back a result from the enqueuing operation.
    #  This is a bit of a frig.
    #
    result = []
    @ad_hoc_domain_cycle = @ad_hoc_domain_allocation.ad_hoc_domain_cycle
    ImplementAdhocJob.perform_later(@ad_hoc_domain_allocation, result)
    @queued = result.empty?
    @job_status = @ad_hoc_domain_cycle.job_status
    respond_to do |format|
      format.json
    end
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
    respond_to do |format|
      if @ad_hoc_domain_allocation.update_allocations(
          @ad_hoc_domain_staff,
          ad_hoc_domain_allocation_params.to_h[:allocations],
          loadings_params)
        format.json
      else
        format.json { render :save_failed, status: 99 }
      end
    end
  end

  # PATCH ad_hoc_domain_staff/1/ad_hoc_domain_allocation/1/autoallocate
  #
  def autoallocate
    #
    #  We are receiving a list of allocations for one staff member
    #  within an ad_hoc_allocation.  Note it's for one staff member,
    #  not for one subject.  If a single staff member teaches more
    #  than one subject then we handle all their allocations
    #  together.
    #
    @allocator =
      AutoAllocator.new(
        @ad_hoc_domain_allocation,
        @ad_hoc_domain_staff,
        auto_allocate_params[:allocations],
        auto_allocate_params[:sundate])
    respond_to do |format|
      @allocation_set = @allocator.allocation_set
      if @allocator.do_allocation
        format.json
      else
        format.json { render :autoallocate_failed, status: 99 }
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

  def do_clone
    new_allocation = @ad_hoc_domain_allocation.dup
    new_allocation.name = "Clone of #{@ad_hoc_domain_allocation.name}"
    new_allocation.save
    respond_to do |format|
      format.html {
        redirect_to ad_hoc_domain_url(
          @ad_hoc_domain_allocation.ad_hoc_domain_cycle.ad_hoc_domain,
          params: {
            cycle_id: @ad_hoc_domain_allocation.ad_hoc_domain_cycle_id,
            tab: 3
          }
        )
      }
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
      permit(:name,
             :loadings_by_pid,
             allocations: [:starts_at, :ends_at, :pcid, clashes: []])
  end

  def auto_allocate_params
    #
    #  Strong parameters really don't work when you're trying simply
    #  to pass data from the client to the host, rather than trying to
    #  do mass assignments to a model.  We're receiving some data which we
    #  will process and send back without doing any kind of update to
    #  the database at this end.
    #
    #  Various help documents say you can still use strong parameters
    #  by adding the relevant attr_accessor to your model but from
    #  experimentation this does not seem to be the case.  The code which
    #  does initial manipulation of the received data still drops the
    #  required field.
    #  
    #  
    request.parameters.slice(:sundate, :allocations)
  end

  def loadings_params
    our_bit = request.parameters.slice(:loadings_by_pid)
    if our_bit
      our_bit[:loadings_by_pid]
    else
      nil
    end
  end
end

