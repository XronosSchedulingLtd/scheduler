# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2022 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class CommitmentsController < ApplicationController
  before_action :set_commitment, only: [:ajaxapprove,
                                        :approve,
                                        :ajaxreject,
                                        :reject,
                                        :ajaxnoted,
                                        :noted,
                                        :destroy,
                                        :view,
                                        :dragged]

  class ConcernWithRequests

    attr_reader :concern, :pending_commitments, :rejected_commitments

    def initialize(concern)
      @concern = concern
      @pending_commitments = Array.new
      @rejected_commitments = Array.new
    end

    def note(commitment)
      if commitment.rejected?
        @rejected_commitments << commitment
      else
        @pending_commitments << commitment
      end
    end

    def anything_outstanding?
      @rejected_commitments.size > 0 ||
      @pending_commitments.size > 0
    end

    def to_partial_path
      "request_set"
    end

  end

  def index
    if current_user.can_add_concerns? &&
          params[:element_id] &&
          @element = Element.find_by(id: params[:element_id])
      selector = @element.commitments
      @allow_buttons = current_user.owns?(@element)
      if params.has_key?(:pending)
        @pending = true
        selector = selector.tentative.future
        @flip_target = element_commitments_path(@element)
        @flip_text = "See All"
      else
        @pending = false
        @flip_target = element_commitments_path(@element, pending: true)
        @flip_text = "See Pending"
      end
      #
      #  If there are lots of commitments, then it makes sense to start
      #  on the page for today.  The user can page forward or backward
      #  as required.  Do this only if the user has not specified an
      #  explicit page.
      #
      page_no = params[:page]
      unless page_no
        previous_commitment_count = selector.until(Time.zone.now.midnight).count
#        Rails.logger.debug("Previous commitment count = #{previous_commitment_count}")
        page_no = (previous_commitment_count / Commitment.per_page) + 1
      end
      @commitments =
        selector.includes(:event).page(page_no).order('events.starts_at')
    else
      #
      #  Send him off to look at his own events.
      #
      redirect_to user_events_path(current_user)
    end
  end

  # POST /commitments
  # POST /commitments.json
  #
  # Depending on the requested resource, we might create a Commitment,
  # or we might create a Request.
  #
  def create
    #
    #  Is the specific element for which we're being asked a resource
    #  group?
    #
    element =
      Element.aresourcegroup.find_by(id: commitment_params[:element_id])
    if element
      #
      #  Yes it is.  Is there already a request in place for this
      #  element?  If there is then we increment the existing one
      #  rather than creating a new one.
      #
      @request =
        element.requests.find_by(event_id: commitment_params[:event_id])
      if @request
        @request.quantity += 1
        @request.save
        @request.reload
        @amended_request_id = @request.id
        @request.event.journal_resource_request_incremented(@request,
                                                            current_user)
        if session[:request_notifier]
          session[:request_notifier].request_incremented(@request)
        end
      else
        @request = Request.new(commitment_params.merge({quantity: 1}))
        if @request.save
          @request.reload
          @amended_request_id = @request.id
          #
          @request.event.journal_resource_request_created(@request,
                                                          current_user)
          if session[:request_notifier]
            session[:request_notifier].request_added(@request)
          end
        end
      end
      @event = @request.event
    else
      @commitment = Commitment.new(commitment_params)
      set_appropriate_approval_status(@commitment)
      #
      #  Not currently checking the result of this, because regardless
      #  of whether it succeeds or fails, we just display the list of
      #  committed resources again.
      #
      if @commitment.save
        @commitment.reload
        @commitment.event.journal_commitment_added(@commitment, current_user)
        if session[:request_notifier]
          session[:request_notifier].commitment_added(@commitment)
        end
      end
      @event = @commitment.event
    end
    @quick_buttons = QuickButtons.new(@event)
    @resourcewarning = false
    respond_to do |format|
      format.js
    end
  end

  # DELETE /commitments/1.js
  def destroy
    @event = @commitment.event
    if current_user.can_delete?(@commitment)
      if session[:request_notifier]
        session[:request_notifier].commitment_removed(@commitment)
      end
      @commitment.event.journal_commitment_removed(@commitment, current_user)
      @commitment.destroy
      @event.reload
      @resourcewarning = false
#        current_user.warn_no_resources && @event.resourceless?
    end
    @quick_buttons = QuickButtons.new(@event)
    respond_to do |format|
      format.js
    end
  end

  #
  #  View the event for a specific commitment in context.
  #
  def view
  end

  # PUT /commitments/1/approve.js
  #
  #  Must check first whether the user has appropriate permissions to
  #  approve this commitment.  Theoretically, this has already been
  #  taken care of in the JavaScript front end, but it's always possible
  #  that someone will attempt to circumvent that.
  #
  #  If an unauthorised attempt is made, we don't actually comment on
  #  it (since that would give additional information to the attempted
  #  malefactor) but just re-display the event's commitments, meaning
  #  that he should lost any hand-crafted approve button which he
  #  previously created.
  #
  def do_approve
    @event = @commitment.event
    if current_user.can_approve?(@commitment) && @commitment.tentative?
      @commitment.approve_and_save!(current_user)
      @event.reload
      @event.journal_commitment_approved(@commitment, current_user)
      if @event.manual?
        UserMailer.commitment_approved_email(@commitment).
                   deliver_now
      end
      true
    else
      false
    end
  end

  def approve
    do_approve
    @visible_commitments, @approvable_commitments =
      @event.commitments_for(current_user)
    respond_to do |format|
      format.js
    end
  end

  def ajaxapprove
    @status = do_approve
    respond_to do |format|
      format.json
    end
  end
  #
  #  It would be really nice to have a single method for approve and
  #  reject, handling both Rails's remote: links (format.js) and ordinary
  #  AJAX requests (format.json), but unfortunately the former makes
  #  use of the latter under the skin.  If both exist in the same action
  #  and templates then Rails always assumes it's format.js.
  #
  #  I therefore need to put the actual work in a helper method, and
  #  have two actions being invoked.
  #
  def do_reject
    @event = @commitment.event
    if current_user.can_approve?(@commitment) &&
      (@commitment.confirmed? || @commitment.requested? || @commitment.noted?)
      @commitment.reject_and_save!(current_user, params[:reason])
      @event.reload
      @event.journal_commitment_rejected(@commitment, current_user)
      if @event.manual?
        UserMailer.commitment_rejected_email(@commitment).deliver_now
      end
      if @commitment.user_form_response &&
         @commitment.user_form_response.complete?
        @commitment.user_form_response.status = :partial
        @commitment.user_form_response.save
      end
      return true
    else
      return false
    end
  end

  #
  #  This one handles remote links, and sends back some JavaScript
  #  to be executed in the client.
  #
  def reject
    do_reject
    respond_to do |format|
      format.js do
        @visible_commitments, @approvable_commitments =
          @event.commitments_for(current_user)
      end
    end
  end

  #
  #  And this one handles genuine AJAX requests.
  #
  def ajaxreject
    @status = do_reject
    respond_to do |format|
      format.json
    end
  end

  def do_noted
    @event = @commitment.event
    if current_user.can_approve?(@commitment) &&
      (@commitment.requested? || @commitment.rejected?)
      @commitment.noted_and_save!(current_user, params[:reason])
      @event.reload
      @event.journal_commitment_noted(@commitment, current_user)
      if @event.manual?
        UserMailer.commitment_noted_email(@commitment).deliver_now
      end
      if @commitment.user_form_response &&
         @commitment.user_form_response.complete?
        @commitment.user_form_response.status = :partial
        @commitment.user_form_response.save
      end
      true
    else
      false
    end
  end

  def ajaxnoted
    @status = do_noted
    respond_to do |format|
      format.json
    end
  end

  def noted
    do_noted
    respond_to do |format|
      format.js do
        @visible_commitments, @approvable_commitments =
          @event.commitments_for(current_user)
      end
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
    if current_user.can_edit?(@commitment.event)
      #
      #  Our commitment may have been dragged onto a new element.
      #  If it has then we change the element which our commitment
      #  points to.
      #
      #  params[:element_id] tells us what it has been dragged onto
      #
      #  The target element might be a ResourceGroup, in which case we
      #  reject the attempt because it doesn't make any sense.  It has
      #  to have been dragged onto a new element.
      #
      element_id = params[:element_id]
      if element_id
        element = Element.find_by(id: element_id)
        #
        #  Note that we allow this drag only if the newly selected
        #  item is *not* a group.  On the relevant user screen, the
        #  targets are other resources in the group (which we do allow)
        #  or the group itself (which would be interpreted for a request
        #  as deallocating the item).  Since we are dealing with a
        #  commitment which is not related to a request, the latter case
        #  doesn't make any sense for us.  We definitely don't want to
        #  turn an existing commitment to one item in the group
        #  into a commitment to the whole group.
        #
        if element
          unless element.entity.is_a?(Group)
            old_element = @commitment.element
            @commitment.element = element
            if @commitment.save
              @commitment.event.journal_resource_changed(current_user,
                                                         old_element,
                                                         element)
            else
              message = "Save failed"
            end
          end
          success = true
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

  private

  def authorized?(action = action_name, resource = nil)
    logged_in? && (current_user.create_events? ||
                   (current_user.element_owner &&
                    (action == "index" ||
                     action == "approve" ||
                     action == "reject")))
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_commitment
    @commitment = Commitment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def commitment_params
    params.require(:commitment).permit(:event_id, :element_id, :element_name)
  end

end
