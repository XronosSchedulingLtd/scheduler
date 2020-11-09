# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class NotifiersController < ApplicationController

  # GET /notifiers/new
  def new
    @notifier = Notifier.new
    @notifier.start_date = Date.today
    #
    #  Let it default to no end date.
    #
    #  If the user has no last date, then this ends up blank and
    #  we do forever.
    #
    @notifier.modified_since = current_user.last_invig_run_date
  end

  # POST /notifiers
  #
  #  Despite the name, we don't currently create a record in the database.
  #
  def create
    @notifier = Notifier.new(notifier_params)
    respond_to do |format|
      if @notifier.save
        @notifier.execute
        if @notifier.send_notifications
          @notifier.do_send(:regardless, current_user)
        end
        if @notifier.check_clashes
          @notifier.notify_clashes
        end
        @staff_entries = @notifier.staff_entries.sort
        @sent = @notifier.send_notifications
        current_user.last_invig_run_date = Date.today
        current_user.save
        format.html
      else
        format.html { render :new }
      end
    end
  end

  #
  #  This is slightly naughty.  There is no index of notifiers
  #  because they never get saved to the database.  Instead we
  #  fire up a notifier to get a list of clashes and display
  #  that instead.
  #
  def index
    @notifier = Notifier.new({
      start_date:         Date.today,
      check_clashes:      true,
      send_notifications: false
    })
    @notifier.execute
  end

  private

    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def notifier_params
      params.require(:notifier).
             permit(:start_date,
                    :end_date,
                    :modified_since,
                    :extra_text,
                    :check_clashes,
                    :send_notifications)
    end
end
