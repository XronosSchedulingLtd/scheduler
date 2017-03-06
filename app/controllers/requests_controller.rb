class RequestsController < ApplicationController
  before_action :set_request, only: [:show, :update, :candidates]

  def show
    respond_to do |format|
      format.json
    end
  end

  def update
    @request.update(request_params)
    respond_to do |format|
      format.json
    end
  end

  def candidates
    @candidates = @request.candidates
    respond_to do |format|
      format.json
    end
  end

  private

  def set_request
    @request = Request.find(params[:id])
  end

  def authorized?(action = action_name, resource = nil)
    #
    #  For now, used only by exams-style people.  Will change.
    #
    (logged_in? && current_user.known? && current_user.exams?)
  end

  def request_params
    params.require(:request).permit(:quantity)
  end

end
