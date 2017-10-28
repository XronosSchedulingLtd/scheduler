class CommitmentsController < ApplicationController
  before_action :set_commitment, only: [:ajaxapprove,
                                        :approve,
                                        :ajaxreject,
                                        :reject,
                                        :ajaxnoted,
                                        :destroy,
                                        :view]

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
        Rails.logger.debug("Previous commitment count = #{previous_commitment_count}")
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
  def create
    @commitment = Commitment.new(commitment_params)
    #
    #  It's possible that the user hasn't specified an element, in
    #  which case the later code will fail at saving the commitment
    #  and we'll go round again.  However, we need to do one check
    #  before attempting the save, but we mustn't attempt it if we
    #  haven't got an element.
    #
    if @commitment.element
      if current_user.needs_permission_for?(@commitment.element)
        @commitment.status = :requested
      else
        @commitment.status = :uncontrolled
      end
    else
      @commitment.status = :uncontrolled
    end
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
    @resourcewarning = false # current_user.warn_no_resources && @event.resourceless?
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
      if @event.complete
        #
        #  Given that our commitment was previously tentative, this
        #  event must now be newly complete.
        #
        UserMailer.event_complete_email(@event).deliver
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
      UserMailer.commitment_rejected_email(@commitment).deliver
      @commitment.user_form_responses.each do |ufr|
        if ufr.complete
          ufr.complete = false
          ufr.save
        end
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
      @commitment.noted_and_save!(current_user)
      @event.reload
      @event.journal_commitment_noted(@commitment, current_user)
      @commitment.user_form_responses.each do |ufr|
        if ufr.complete
          ufr.complete = false
          ufr.save
        end
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
