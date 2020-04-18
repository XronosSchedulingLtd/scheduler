# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class FormReportsController < ApplicationController

  before_action :find_element

  def create
    if @element.user_form && current_user.can_view_forms_for?(@element)
      if form_params[:starts_on]
        starts_on = Date.parse(form_params[:starts_on])
      else
        starts_on = Date.today
      end
      if form_params[:ends_on]
        ends_on = Date.parse(form_params[:ends_on])
      else
        ends_on = Date.today
      end
      @form_reporter = FormReporter.new(@element, starts_on, ends_on)
      if @form_reporter.ok?
        send_data(@form_reporter.to_csv,
                  filename: "#{@element.short_name} forms.csv",
                  type: "application/csv")
      else
        redirect_back fallback_location: root_path
      end
    else
      redirect_back fallback_location: root_path
    end
  end

  def authorized?(action = action_name, resource = nil)
    known_user? && action == 'create'
  end

  private

  def form_params
    params.require(:form_report).permit(:starts_on, :ends_on)
  end

  def find_element
    @element = Element.find(params[:element_id])
  end

end
