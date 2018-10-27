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

  def dragged
    #
    #  The meaning of this flag is perhaps slightly surprising.
    #  It controls whether we return an error code at the communications
    #  level.  We reserve these for when the processing has gone horribly
    #  wrong.  If we simply want to tell the user a reason why we haven't
    #  done what they want, then we need to return success at the comms
    #  level so we can pass a message in the data.
    #
    success = false
    message = nil
    #
    #  params[:item_id] tells us what has been dragged
    #  params[:element_id] tells us what it has been dragged onto
    #
    #  The target element might be a ResourceGroup, in which case we
    #  are un-committing something, or else it might be a Resource,
    #  in which case we are committing something.
    #
    #  The thing being dragged may be a request (begins Req) or
    #  an existing commitment (begins Com).
    #
    item_id = params[:item_id]
    element_id = params[:element_id]
    if item_id && element_id
      element = Element.find_by(id: element_id)
      requested = @request.element.entity
      if requested.is_a?(Group) && element
        members = requested.members(nil, true, true)
        #
        #  Is the item a request?  If so then the item_id will contain
        #  the request id as an embedded item, but we don't need it.
        #
        checker = item_id.match(/\AReq\d+-\d\z/)
        if checker
          #
          #  The user has dragged a request item.  He has dragged it
          #  onto an element of some sort.  Provided this is a suitable
          #  item to fulfill the request, we create a new commitment.
          #
          if members.include?(element.entity)
            commitment = @request.fulfill(element)
            success = true
            unless commitment.valid?
              message = "This resource is already committed to the event"
            end
          else
            success = true
            message = "Not a suitable resoure for the request"
          end
        else
          #
          #  Is it an existing commitment?
          #
          checker = item_id.match(/\ACom(\d+)\z/)
          if checker
            commitment = Commitment.find_by(id: checker[1])
            if commitment
              #
              #  Two possibilities.
              #
              #  1) It can be dragged onto another suitable resource to
              #     fulfill the parent request.  Change the commitment.
              #
              #  2) It can be dragged anywhere else.  Delete the commitment,
              #     meaning it reverts to being an unfulfilled request.
              #
              @request.unfulfill(commitment.element_id)
              success = true
              if members.include?(element.entity)
                commitment = @request.fulfill(element)
                unless commitment.valid?
                  message = "This resource is already committed to the event"
                end
              end
            end
          end
        end
      end
    end
    respond_to do |format|
      format.json do
        if success
          #
          #  If we succeeded then we don't really have any information
          #  to pass back apart from the success, but the other end is
          #  expecting some valid JSON-structured data.
          #
          if message
            render json: {message: message}
          else
            render json: ["OK"]
          end
        else
          render json: ["Failed"], status: :bad_request
        end
      end
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
