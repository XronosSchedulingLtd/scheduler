class CoversController < ApplicationController
  #
  #  Normally we would have a before_action to find our commitment,
  #  but the trouble is we need to do that before we can decide
  #  whether the user is authorised to invoke this controller.
  #
  #  Therefore, at the risk of losing a bit of clarity, we'll do the
  #  finding of the commitment in the authorized? method.
#  before_action :set_commitment

  class PseudoCommitmentSet < Array
    def show_clashes
      true
    end
  end

  #
  # /commitments/1/coverwith/1.json
  #
  #  Sets a covering commitment for the indicated commitment.  The id
  #  which we are passed indicates the element to do the covering.
  #
  #  If we are passed an id of 0, then that means we are to remove
  #  any existing cover from the commitment.
  #
  #  If an existing cover exists on the commitment then we replace
  #  the covering element (if it differs) rather than creating a new
  #  cover.
  #
  #  Note that when we create a commitment we deliberately do not
  #  give it a source id.  This is to distinguish our manually
  #  created commitments from those created by the data importer.
  #  If they come from an external MIS then they should have a source id.
  #
  def coverwith
    id = params[:id]
    #
    #  Normally notifications are sent at the end of an editing session.
    #  The request_notifier is created when the user starts editing
    #  an event, and then notices are sent when the edit session finishes.
    #  In between the request_notifier is stored in the session.
    #
    #  In the case of cover however, there is no edit session.  We
    #  create and use a request_notifier within the duration of
    #  this method.  The most e-mails we can send is two - if the
    #  user has an existing pending request and changes it to another
    #  one which also needs approval, and also wants immediate
    #  notification.
    #
    request_notifier = RequestNotifier.new
    if id == "0"
      if @commitment.covered
        request_notifier.commitment_removed(@commitment.covered)
        @commitment.covered.destroy
        @commitment.reload
      end
      to_list = @commitment
    else
      @element = Element.find(id)
      if @commitment.covered &&
         @commitment.covered.element == @element
        #
        #  The user has asked for exactly the same as he's already
        #  got.  Leave things alone.
        #
        #  Should we actually change things if the user has,
        #  for instance, re-requested a room which was previously
        #  turned down?  See how it goes and whether the user experience
        #  surprises them.
        #
        to_list = @commitment.covered
      else
        #
        #  Originally we tried to re-cycle an existing cover commitment,
        #  but there's a danger it may have left-over flags set.  Destroy
        #  it and start again.
        #
        if @commitment.covered
          #
          #  Need to check for pending approval of the previously
          #  requested cover element and send a cancellation e-mail if
          #  required.
          #
          request_notifier.commitment_removed(@commitment.covered)
          @commitment.covered.destroy
          @commitment.reload
        end
        c = Commitment.create!({
          element:   @element,
          event:     @commitment.event,
          covering:  @commitment,
          tentative: current_user.needs_permission_for?(@element)
        })
        request_notifier.commitment_added(c)
        #
        #  Need to check for pending approval and send e-mail if
        #  required.
        #
        to_list = c
      end
    end
    request_notifier.send_notifications_for(current_user,
                                            @commitment.event)
    #
    #  Now need to prepare some replacement HTML to go in the dialogue's
    #  description of locations.
    #
    @pcs = PseudoCommitmentSet.new
    @pcs << to_list
    respond_to do |format|
      format.json
    end
  end

  private

  #
  #  We have only the one action at the moment, and we kind of assume
  #  that you're authorized as long as you're logged in.
  #
  def authorized?(action = action_name, resource = nil)
    if logged_in?
      @commitment = Commitment.find(params[:commitment_id])
      current_user.can_relocate?(@commitment.event)
    else
      false
    end
  end

end
