class ItemreportsController < ApplicationController

  #
  #  Currently these don't actually get saved to the database.  We
  #  use them transitorily to invoke the Days controller and get a
  #  report.
  #
  #  This may well change.
  #
  def create
    item_report = Itemreport.new(itemreport_params)
    if item_report.concern
      redirect_to item_report.url
    else
      redirect_to :back
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end

  def itemreport_params
    params.require(:itemreport).
           permit(:concern_id, :compact, :duration, :mark_end, :locations,
                  :staff, :pupils, :periods, :starts_on,
                  :ends_on, :twelve_hour, :end_time,
                  :breaks, :suppress_empties, :tentative,
                  :firm, :categories)
  end

end
