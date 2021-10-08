class ImplementBadJob < ApplicationJob
  queue_as :ahdj

  after_perform :job_done

  rescue_from(Exception) do |exception|
    Rails.logger.debug("Encountered exception #{exception.to_s}")
    Rails.logger.debug("Magic string is #{@magic_string}")
  end

  def perform(*args)
    #
    #  This job exists just to raise an exception.
    #
    @magic_string = "Banana fritters"
    sleep(5)
    raise RuntimeError.new("Whoops mother!")
  end

  private

  def job_done
    Rails.logger.debug("In job_done********************************")
  end

end
