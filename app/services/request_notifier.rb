# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  An instance of this class is stored in a user's session and used
#  to keep track of and then send any e-mails needed as a result of
#  the user requesting or cancelling a request for a controlled resource.
#
class RequestNotifier

  def initialize
    @elements_added   = Array.new
    @elements_removed = Array.new
  end

  #
  #  Called when a new commitment is added to the event currently
  #  being edited.  Makes a note of it if it is one we should send
  #  e-mails about.
  #
  def commitment_added(commitment)
    #
    #  As this is a brand new commitment, it can be tentative
    #  but it can't be rejected.  No-one has had time to reject
    #  it yet.
    #
    if commitment.tentative?
      #
      #  We are keeping track of net change, so we record that
      #  the resource has been added, unless it was earlier
      #  removed within the current editing session, in which case
      #  we just remove our note of its removal.
      #
      if @elements_removed.include?(commitment.element_id)
        @elements_removed -= [commitment.element_id]
      else
        @elements_added << commitment.element_id
      end
    end
  end

  def commitment_removed(commitment)
    if commitment.tentative? && !commitment.rejected?
      if @elements_added.include?(commitment.element_id)
        @elements_added -= [commitment.element_id]
      else
        @elements_removed << commitment.element_id
      end
    end
  end

  #
  #  Called when a user has finished editing an event.  Sends any
  #  notifications needed for requested resources, provided the administrator
  #  of said resource has requested immediate notification.
  #
  #  Also called when an event is about to be deleted and sends similar
  #  notifications for cancelled requests.
  #
  def send_notifications_for(user, event, deleting = false)
    if deleting
      #
      #  This is an all-in-one operation and doesn't involve
      #  our own records of what's been happening.
      #
      event.commitments.tentative.not_rejected.each do |c|
        resource = c.element
        resource.owners.each do |owner|
          if owner.immediate_notification
            UserMailer.resource_request_cancelled_email(owner,
                                                        resource,
                                                        event,
                                                        user).deliver
          end
        end
      end
    else
      #
      #  Has the user deleted any signficant elements in the course
      #  of this editing session?
      #
      @elements_removed.each do |er|
        resource = Element.find_by(id: er)
        if resource
          resource.owners.each do |owner|
            if owner.immediate_notification
              UserMailer.resource_request_cancelled_email(owner,
                                                          resource,
                                                          event,
                                                          user).deliver
            end
          end
        end
      end
      #
      #  And added any?
      #
      @elements_added.each do |er|
        resource = Element.find_by(id: er)
        if resource
          resource.owners.each do |owner|
            if owner.immediate_notification
              UserMailer.resource_requested_email(owner,
                                                  resource,
                                                  event,
                                                  user).deliver
            end
          end
        end
      end
    end
  end


end
