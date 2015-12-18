class ItemreportsController < ApplicationController

  #
  #  This can actually be called when a concern already has
  #  an attached itemreport.  This is because the user might
  #  use the back button, and submit two consecutive requests
  #  using the same apparently un-saved record.  This then
  #  results in a concern having two item reports attached.
  #  Guard against this.
  #
  def create
    concern = Concern.find_by(id: itemreport_params[:concern_id])
    if concern
      if concern.itemreport
        item_report = concern.itemreport
        item_report.update(itemreport_params)
      else
        item_report = Itemreport.new(itemreport_params)
        item_report.note_type(params[:commit])
        item_report.save
      end
      if item_report.concern
        redirect_to item_report.url
      else
        redirect_to :back
      end
    else
      redirect_to :back
    end
  end

  def update
    item_report = Itemreport.find(params[:id])
    if item_report.update(itemreport_params)
      item_report.note_type(params[:commit])
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
                  :firm, :my_notes, :other_notes, :general_notes, :categories,
                  :excluded_element_name, :excluded_element_id)
  end

end
