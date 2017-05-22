class PeriodsController < ApplicationController
  def index
    @periods = []
    if current_user && (ds = current_user.day_shape)
      ds.periods do |day_no, start_time, end_time|
        @periods << PeriodSlot.new(day_no, start_time, end_time)
      end
    end
    @periods.sort!
  end

  private

  #
  #  It simplifies the front end code if we allow this method to
  #  work all the time, even if the user is not logged in.
  #  
  #  We're not actually leaking any information, because if the user
  #  is not logged in then we return an empty array regardless.
  #
  def authorized?(action = action_name, resource = nil)
    true
  end
end
