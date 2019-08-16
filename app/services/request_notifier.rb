#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  First usage (original intention)
#  --------------------------------
#
#  An instance of this class is stored in a user's session and used
#  to keep track of and then send any e-mails needed as a result of
#  the user requesting or cancelling a request for a controlled resource.
#
#  The above assumes a single event is being edited, and that it's an
#  ongoing user session - that is, we aren't doing all our processing
#  in one go, but having a multi-request dialogue with the user.  Hence
#  the need to store in the session, but also the assumption that only
#  the one event is involved.
#
#  We have a record relating to *one* event, and we keep track of
#  the changes made to resources for that event.
#
#    * Commitments may be added or removed.
#    * Requests may be added, incremented, decremented or removed.
#
#  Because our data structure is to be stored in the session, it is
#  important to keep the size of data small and easily serializable.
#
#  For commitments being amended (added/removed) it is enough to keep
#  track of the corresponding element id.  Indeed, we're not particularly
#  interested in the commitment id, because an original commitment might
#  be deleted and a fresh one created, in which case we regard ourselves
#  as being back where we started.
#
#  For requests, we need to store more - both the request id and the
#  element id, plus the original quantity.
#
#
#  A later requirement has now arisen.
#
#  Repeating events
#  ----------------
#
#  Here we may generate a whole heap of additions/subtractions for
#  an element, on a wide range of events.  What we really don't want
#  to do is send the user one e-mail per request.  They could get
#  hundreds.  We need to batch them up.  However, the job is made
#  slightly easier in that all the work is done in a single go
#  by the server.  We process a whole batch as the result of a single
#  request from the user's browser.  We thus don't need to be stored
#  in the session, but we do need to create a single e-mail (per
#  resource) at the end.
#
#  We thus need new data structures.
#
#  * We need to keep track of which resources have had commitments added
#    or removed, and then for each resource we need to keep track of all
#    the events to which it has been added or taken away.
#
#  * We also need to keep track of resources which can have requests,
#    and for these we need to make a list of all events where a request
#    has been added, adjusted or removed.
#
#  This is the opposite way around from the original processing, where
#  we assumed that there was just the one event, and kept track of
#  which resources had been added to it or removed from it.
#
#  We should be able to do the old trick of squashing cases where
#  the same resource is added/removed or remove/added for a single
#  event, although I don't think it will actually arise given the current
#  repeating event processing.
#
#  New entry points:
#
#  * batch_commitment_added
#  * batch_commitment_removed
#  * batch_request_added
#  * batch_request_adjusted
#  * batch_request_removed
#

class RequestNotifier

  #
  #  Object to record all the updates involving commitments to a given element.
  #
  #  This object is used solely for the batch processing.
  #  
  #
  class ElementRecord

    attr_reader :events_added_to,
                :events_removed_from

    def initialize(element, event)
      #
      #  In each of these, we will store simply the starts_at field,
      #  and index by event id.
      #
      @events_added_to = Hash.new
      @events_removed_from = Hash.new
    end

    def commitment_added(commitment)
      unless @events_removed_from.delete(commitment.event_id)
        @events_added_to[commitment.event_id] = commitment.event.starts_at_text
      end
    end

    def commitment_removed(commitment)
      unless @events_added_to.delete(commitment.event_id)
        @events_removed_from[commitment.event_id] = commitment.event.starts_at_text
      end
    end

    def empty?
      @events_added_to.empty? && @events_removed_from.empty?
    end

  end

  #
  #  This item is used to keep track of adjustments to requests in the
  #  course of an editing session.
  #
  class RequestRecord
    attr_reader :original_quantity, :description, :element_id, :num_allocated
    attr_accessor :current_quantity

    def initialize(request, original_quantity)
      @original_quantity = original_quantity
      @description = "Request for #{request.element.name}"
      @current_quantity = original_quantity
      @element_id = request.element_id
      @num_allocated = request.num_allocated
    end
  end

  def initialize(general_title = "<none given>")

    @general_title = general_title
    @elements_added   = Array.new
    @elements_removed = Array.new
    @requests_adjusted = Hash.new
    @requests_destroyed = Hash.new

    @element_records = Hash.new
  end

  #=================================================================
  #
  #  New processing - doing a batch.
  #
  #=================================================================
 
  #
  #  It is a requirement that the commitment is already linked to
  #  the event and resource before we get it, although it may not
  #  yet have been saved to the database.
  #
  def batch_commitment_added(commitment)
    if commitment.tentative?
      element_record =
        @element_records[commitment.element_id] ||=
          ElementRecord.new(commitment.element, commitment.event)
      element_record.commitment_added(commitment)
    end
  end

  def batch_commitment_removed(commitment)
    if commitment.tentative? && !commitment.rejected?
      element_record =
        @element_records[commitment.element_id] ||=
          ElementRecord.new(commitment.element, commitment.event)
      element_record.commitment_removed(commitment)
    end
  end

  def send_batch_notifications(by_user)
    #
    #  We send one e-mail per non-empty element record.
    #
    @element_records.each do |element_id, record|
      unless record.empty?
        if resource = Element.find_by(id: element_id)
          resource.owners.each do |owner|
            if owner.immediate_notification
              UserMailer.resource_batch_email(owner,
                                              resource,
                                              record,
                                              by_user,
                                              @general_title).deliver_now
            end
          end
        end
      end
    end
  end

  #=================================================================
  #
  #  Original processing - interactive session.
  #
  #=================================================================
  #
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
  #  We want to keep track of the requests which have been changed,
  #  and report only the final result.
  #
  #  If someone increments and then decrements, we need send no
  #  e-mail.
  #
  def request_adjusted(request, previous_quantity)
    #
    #  The first time we see a reference to a given request we store
    #  a record of its previous quantity value - i.e. the original
    #  value at the start of the session.
    #
    record =
      @requests_adjusted[request.id] ||=
      RequestRecord.new(request, previous_quantity)
    if request.quantity == record.original_quantity
      #
      #  Back to where we started.  Get rid of this entry.
      #
      @requests_adjusted.delete(request.id)
    else
      record.current_quantity = request.quantity
    end
  end

  #
  #  This should be called after the request has been saved to the
  #  database so it has an id number.
  #
  def request_added(request)
    request_adjusted(request, 0)
    self
  end

  def request_incremented(request)
    request_adjusted(request, request.quantity - 1)
    self
  end

  def request_decremented(request)
    request_adjusted(request, request.quantity + 1)
    self
  end

  def request_destroyed(request)
    if @requests_adjusted[request.id]
      original_quantity = @requests_adjusted[request.id].original_quantity
      @requests_adjusted.delete(request.id)
    else
      original_quantity = request.quantity
    end
    #
    #  If the original quantity was 0, then the request was created
    #  during this editing session so we don't need to tell anyone
    #  about it.
    #
    unless original_quantity == 0
      @requests_destroyed[request.id] =
        RequestRecord.new(request, original_quantity)
    end
    self
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
            UserMailer.commitment_request_cancelled_email(owner,
                                                          resource,
                                                          event,
                                                          user).deliver_now
          end
        end
      end
      event.requests.each do |request|
        resource = request.element
        resource.owners.each do |owner|
          if owner.immediate_notification
            UserMailer.commitment_request_cancelled_email(owner,
                                                          resource,
                                                          event,
                                                          user).deliver_now
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
              UserMailer.commitment_request_cancelled_email(owner,
                                                          resource,
                                                          event,
                                                          user).deliver_now
            end
          end
        end
      end
      @requests_destroyed.each do |key, record|
        resource = Element.find_by(id: record.element_id)
        if resource
          resource.owners.each do |owner|
            UserMailer.commitment_request_cancelled_email(owner,
                                                        resource,
                                                        event,
                                                        user).deliver_now
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
              UserMailer.commitment_requested_email(owner,
                                                    resource,
                                                    event,
                                                    user).deliver_now
            end
          end
        end
      end
      #
      #  Or adjusted any?
      #
      @requests_adjusted.each do |key, record|
        resource = Element.find_by(id: record.element_id)
        if resource
          resource.owners.each do |owner|
            if record.original_quantity == 0
              UserMailer.request_created_email(owner,
                                               resource,
                                               event,
                                               record,
                                               user).deliver_now
            else
              UserMailer.request_adjusted_email(owner,
                                                resource,
                                                event,
                                                record,
                                                user).deliver_now
            end
          end
        end
      end
    end
  end


end
