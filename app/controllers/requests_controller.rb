#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2022 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

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
      @event.journal_resource_request_destroyed(@request, current_user)
      if request.format.html?
        #
        #  A standalone request - not part of an editing session
        #
        RequestNotifier.new.
                        request_destroyed(@request).
                        send_notifications_for(current_user, @event)
      else
        #
        #  Should be part of an editing session.
        #
        if session[:request_notifier]
          session[:request_notifier].request_destroyed(@request)
        end
      end
      @request.destroy
      @event.reload
      @resourcewarning = false
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def increment
    @event = @request.event
    if current_user.can_subedit?(@request)
      @request.increment_and_save
      @request.reload
      @amended_request_id = @request.id
      @event.journal_resource_request_incremented(@request, current_user)
      if session[:request_notifier]
        session[:request_notifier].request_incremented(@request)
      end
      @resourcewarning = false
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
    end
  end

  def decrement
    @event = @request.event
    if current_user.can_subedit?(@request)
      @request.decrement_and_save
      @request.reload
      @amended_request_id = @request.id
      @event.journal_resource_request_decremented(@request, current_user)
      if session[:request_notifier]
        session[:request_notifier].request_decremented(@request)
      end
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
              if commitment.valid?
                @request.event.journal_resource_request_allocated(@request,
                                                                  current_user,
                                                                  element)
              else
                message = "This resource is already committed to the event"
              end
            else
              success = true
              message = "Not a suitable resource for the request"
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
                old_element = commitment.element
                @request.unfulfill(commitment.element_id)
                @request.event.journal_resource_request_deallocated(
                  @request,
                  current_user,
                  old_element)
                success = true
                if members.include?(element.entity)
                  commitment = @request.fulfill(element)
                  if commitment.valid?
                    @request.event.journal_resource_request_allocated(
                      @request,
                      current_user,
                      element)
                  else
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

  #
  #  This method can be used in two ways:
  #
  #  1) To provide a listing of all the requests for a resource.
  #     Used by administrators of a resource.
  #  2) To provide a listing of all the requests by a user.
  #
  def index
    if current_user.can_add_concerns? &&
          params[:element_id] &&
          @element = Element.find_by(id: params[:element_id])
      #
      #  By element
      #
      selector = @element.requests
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
        selector.includes([:event, :commitments, :user_form_response]).
                 page(page_no).
                 order('events.starts_at')
      @show_owner          = true
      @show_organiser      = true
      @show_resource       = false
      @show_action_buttons = false
      @title = "Events requesting #{@element.short_name}"
    elsif params[:user_id] && @user = User.find_by(id: params[:user_id])
      #
      #  By requesting user
      #
      selector = Request.owned_or_organised_by(@user)
      if params.has_key?(:pending)
        @pending = true
        selector = selector.future
        @flip_target = user_requests_path(@user)
        @flip_text = "See All"
      else
        @pending = false
        @flip_target = user_requests_path(@user, pending: true)
        @flip_text = "See Pending"
      end
      page_no = params[:page]
      unless page_no
        previous_requests_count = selector.until(Time.zone.now.midnight).count
        page_no = (previous_requests_count / Request.per_page) + 1
      end
      @requests =
        selector.includes([:event, :commitments, :element, :user_form_response]).
                 page(page_no).
                 order('events.starts_at')
      @show_owner          = false
      @show_organiser      = false
      @show_resource       = true
      @show_action_buttons = true
      @title = "Requests by #{@user.name}"
    else
      #
      #  Send him off to look at his own events.
      #
      redirect_to user_events_path(current_user)
    end
  end

  def reconfirm
    @request.reconfirmed = true
    @request.save
    @request.event.journal_resource_request_reconfirmed(@request, current_user)
    redirect_back fallback_location: root_path
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
      when 'dragged', 'index', 'reconfirm'
        if params[:user_id]
          #
          #  Need to be the user, or an admin
          #
          current_user.admin? || params[:user_id].to_i == current_user.id
        else
          #
          #  Need to be an administrator for the relevant resource
          #  but we will leave the actual check for now.  We want to
          #  return a meaningful error message if it's not permitted,
          #  not just raise a processing error.
          #
          true
        end
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
