class RequestsController < ApplicationController
  before_action :set_request

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

  def fulfill
    eid = params[:eid]
    if eid
      element = Element.find_by(id: eid)
      if element
        new_commitment = @request.fulfill(element)
        if new_commitment.valid?
          @request.reload
        end
      end
    end
    respond_to do |format|
      format.json { render :show }
    end
  end

  def unfulfill
    eid = params[:eid]
    if eid
      @request.unfulfill(eid.to_i)
    end
    respond_to do |format|
      format.json { render :show }
    end
  end

  def destroy
    @event = @request.event
    if current_user.can_delete?(@request)
      #
      #  Should add:
      #    Notifications
      #    Journalling
      #
      @request.destroy
      @event.reload
      @resourcewarning = false
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
    end
  end

  def increment
    @event = @request.event
    if @request.quantity < @request.max_quantity &&
      current_user.can_modify?(@request)
      @request.quantity += 1
      @request.save
      @request.reload
      @resourcewarning = false
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
    end
  end

  def decrement
    @event = @request.event
    if @request.quantity > 1 &&
      current_user.can_modify?(@request)
      @request.quantity -= 1
      @request.save
      @request.reload
      @resourcewarning = false
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
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
