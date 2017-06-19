class CommitmentsController < ApplicationController
  before_action :set_commitment, only: [:approve, :reject, :destroy, :view]

  class ConcernWithRequests

    attr_reader :concern, :pending_commitments, :rejected_commitments

    def initialize(concern)
      @concern = concern
      @pending_commitments = Array.new
      @rejected_commitments = Array.new
    end

    def note(commitment)
      if commitment.rejected
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

  #
  #  Slightly unusually, doesn't give a list of all the commitments
  #  (which would be vast), but lists those in the future over which
  #  we have approval authority.
  #
  def index
    if current_user.element_owner
      @requests = Array.new
      current_user.concerns.owned.each do |concern|
#        Rails.logger.debug("Processing concern with #{concern.element.name}")
        requests = ConcernWithRequests.new(concern)
        concern.element.commitments.tentative.each do |commitment|
#          Rails.logger.debug("Event ends at #{commitment.event.ends_at}")
#          Rails.logger.debug("Currently #{Date.today}")
          if commitment.event.ends_at >= Date.today
            requests.note(commitment)
          end
        end
        @requests << requests
      end
#      Rails.logger.debug("Got #{@requests.size} owned elements.")
    else
      #
      #  Shouldn't be able to get here, but if someone is playing at
      #  silly buggers then kick them out.
      #
      redirect_to '/'
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
      @commitment.tentative =
        current_user.needs_permission_for?(@commitment.element)
    else
      @commitment.tentative = false
    end
    #
    #  Not currently checking the result of this, because regardless
    #  of whether it succeeds or fails, we just display the list of
    #  committed resources again.
    #
    if @commitment.save
      @commitment.reload
      #
      #  This array is initialised by events_controller and keeps track
      #  of all the new commitments created in an editing session.  Since
      #  this commitment has only just been created, its id can't
      #  already be in the array.
      #
      #Rails.logger.debug(session.inspect)
      session[:commitments_added] << @commitment.id
#      Rails.logger.debug("Commitments_added - #{session[:commitments_added].to_s}")
    end
    @event = @commitment.event
    respond_to do |format|
      format.js
    end
  end

  # DELETE /commitments/1.js
  def destroy
    @event = @commitment.event
    if current_user.can_delete?(@commitment)
      if session[:commitments_added].include?(@commitment.id)
        #
        #  Added and then deleted in the course of a single session.
        #  Not interesting.
        #
        session[:commitments_added] -= [@commitment.id]
      else
        #
        #  Added earlier and deleted in this editing session.  Might
        #  need to send a notification.  We do this only for commitments
        #  which were in a state of being tentative, but not rejected.
        #  In other words - those pending approval.
        #
        if @commitment.tentative && !@commitment.rejected
          session[:elements_removed] << @commitment.element_id
        end
      end
      @commitment.destroy
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
  def approve
    @event = @commitment.event
    if current_user.can_approve?(@commitment) && @commitment.tentative
      @commitment.approve_and_save!(current_user)
      @event.reload
      if @event.complete
        #
        #  Given that our commitment was previously tentative, this
        #  event must now be newly complete.
        #
        UserMailer.event_complete_email(@event).deliver
      end
    end
    @visible_commitments, @approvable_commitments =
      @event.commitments_for(current_user)
    respond_to do |format|
      format.js
    end
  end

  # PUT /commitments/1/reject.js
  def reject
    @event = @commitment.event
    if current_user.can_approve?(@commitment) &&
      (@commitment.tentative || @commitment.constraining)
      @commitment.reject_and_save!(current_user, params[:reason])
      @event.reload
      UserMailer.commitment_rejected_email(@commitment).deliver
    end
    @visible_commitments, @approvable_commitments =
      @event.commitments_for(current_user)
    respond_to do |format|
      format.js
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
