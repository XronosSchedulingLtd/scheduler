class RequestsController < ApplicationController
  #
  #  We need the set_request to run *before* our authorized? method
  #  is invoked, so put it on the front of the chain.
  #
  prepend_before_action :set_request, except: :index

  #
  #  These methods are used for exam invigilation type requests.
  #
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

  #
  #  And these are used for user-entered requests.
  #
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
    if current_user.can_allocate_to?(@request)
      #
      #  params[:item_id] tells us what has ben dragged
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
    else
      success = true
      message = "You do not have permission to change this allocation."
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

  def index
    if current_user.can_add_concerns? &&
          params[:element_id] &&
          @element = Element.find_by(id: params[:element_id])
      selector = @element.requests
      @allow_buttons = current_user.owns?(@element)
      if params.has_key?(:pending)
        @pending = true
        selector = selector.future
        @flip_target = element_requests_path(@element)
        @flip_text = "See All"
      else
        @pending = false
        @flip_target = element_requests_path(@element, pending: true)
        @flip_text = "See Pending"
      end
      #
      #  If there are lots of requests, then it makes sense to start
      #  on the page for today.  The user can page forward or backward
      #  as required.  Do this only if the user has not specified an
      #  explicit page.
      #
      page_no = params[:page]
      unless page_no
        previous_requests_count = selector.until(Time.zone.now.midnight).count
        page_no = (previous_requests_count / Request.per_page) + 1
      end
      @requests =
        selector.includes([:event, :commitments, :user_form_response]).page(page_no).order('events.starts_at')
    else
      #
      #  Send him off to look at his own events.
      #
      redirect_to user_events_path(current_user)
    end
  end

  private

  def set_request
    @request = Request.find(params[:id])
  end

  def authorized?(action = action_name, resource = nil)
    if known_user?
      case action
      when 'show', 'update', 'candidates', 'fulfill', 'unfulfill'
        #
        #  The exam-ey ones.
        #
        current_user.exams?
      when 'destroy'
        current_user.can_delete?(@request)
      when 'increment', 'decrement'
        current_user.can_subedit?(@request)
      when 'dragged', 'index'
        #
        #  Need to be an administrator for the relevant resource
        #  but we will leave the actual check for now.  We want to
        #  return a meaningful error message if it's not permitted,
        #  not just raise a processing error.
        #
        true
      else
        #
        #  We don't know what you're trying to do, so you can't.
        #
        false
      end
    else
      false
    end
  end

  def request_params
    params.require(:request).permit(:quantity)
  end

end
