class ImplementAdhocJob < ApplicationJob
  #
  #  We have our own queue which should be configured as:
  #
  #  * Only one job at a time
  #  * Only one attempt
  #
  queue_as :ahdj

  rescue_from(Exception) do |exception|
    Rails.logger.debug("Encountered exception #{exception.to_s}")
    if @cycle
      @cycle.note_failed
    end
  end

  around_enqueue do |_job, block|
    #
    #  As were are solely responsible for the job status fields in the
    #  parent AdHocDomainCycle, we do the work of checking whether
    #  the enqueuing is permitted.
    #
    #  If we choose not to enqueue it then we shove something into
    #  the second job argument (which is an array) to indicate that
    #  we haven't.  It's an array because those are effectively passed
    #  by reference in a function call.  If we add something to that
    #  array, the caller will be able to see it.
    #
    allocation = _job.arguments[0]
    result = _job.arguments[1]
    cycle = allocation.ad_hoc_domain_cycle
    if cycle.note_queued(allocation)
      block.call
    else
      result << :cant
    end
  end

  #
  #  We expect an allocation on which to do the work and an empty array
  #  in which we can pass back results.  The latter item is not used
  #  here (because we are working asynchronously) but is used in the
  #  callback if it prevents execution.
  #
  #  ActiveJob is a bit lacking in clearly needed facilities.  Apparently
  #  the means to return an indication of whether the job was enqueued
  #  has been added in Rails 7, but it's a weird thing to have forgotten
  #  to do in the first place.  This is a nasty frig until the new
  #  facility becomes available in that release.
  #
  #  Don't attempt to do anything with "result" in this function because
  #  it won't achieve anything.
  #
  def perform(allocation, result)
    # 
    #  For our argument, we expect the AdHocDomainAllocation.
    #
    @cycle = allocation.ad_hoc_domain_cycle
    @cycle.note_started
    generator = AdHocDomainAllocationGenerator.new(allocation)
    generator.generate do |created, deleted, amended, percentage|
      Rails.logger.debug "Created: #{created}, deleted: #{deleted}, amended: #{amended}"
      @cycle.update_counts(created, deleted, amended, percentage)
    end
    @cycle.note_finished
  end
end
