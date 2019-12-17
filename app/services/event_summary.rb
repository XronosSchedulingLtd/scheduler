#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  A wrapper around an event to provide a summary of the event's
#  status to put into notification e-mails.
#  Exists to:
#
#  1. Reduce the amount of code in the view.
#  2. Allow us to have our own partial.
#  3. Do a little bit of cacheing so the view can first check
#     whether a particular category has any entries (and thus
#     decide whether to show the heading) then ask for the entries
#     without having to hit the database twice.
#
class EventSummary

  attr_reader :commitments,
              :controlled_commitments,
              :request_commitments,
              :other_commitments,
              :requests,
              :fulfilled_requests,
              :pending_requests

  def initialize(event)
    @event = event
    #
    #  Wavered between doing lots of separate database hits to
    #  select each grouping, or just two and then sort them ourselves.
    #  The database engine is doubtless faster at doing the filtering,
    #  but OTOH we are dealing with just one event, and the overhead
    #  of each d/b call probably outweighs the efficiency of the engine.
    #
    #  We'll go for just two d/b hits unless that causes problems.
    #
    @commitments = @event.commitments.to_a
    @requests = @event.requests.to_a
    #
    #  Now let's sort them.
    #
    @controlled_commitments = @commitments.select { |c| !c.uncontrolled? }
    @request_commitments = @commitments.select { |c| !!c.request }
    @other_commitments =
      @commitments.select {|c| c.uncontrolled? && c.request.nil? }
    @fulfilled_requests =
      @requests.select { |r| !r.tentative }
    @pending_requests =
      @requests.select { |r| r.tentative }
  end

  #
  #  Since we're a wrapper, pass on anything which we don't understand
  #  to our event object.
  #
  
  def method_missing(name, *args, &blk)
    Rails.logger.debug("method_missing passed #{name}")
    if @event.respond_to?(name)
      @event.send(name, *args, &blk)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    Rails.logger.debug("respond_to_missing passed #{method}")
    @event.respond_to?(method) || super
  end

  #
  #  These next two make us look like an Active Model in our own
  #  right, at least to the renderer.
  #
  #  The second one is needed because without it, we pass the call
  #  to "to_model" through to our underlying event, and then the
  #  renderer tries to render that rather than us.
  #
  def to_partial_path
    'event_summary'
  end

  def to_model
    self
  end

  #
  #  And now the extras which we supply.
  #

  #
  #  A list of all the resources which are simply attached to this
  #  event, without needing any kind of approval or request.
  #
  def simple_resource_elements
    #
    #  Uncontrolled means "not involved in approvals process".
    #  Standalone means "not connected with a request".
    #
    @other_commitments.collect {|c| c.element}
  end

  #
  #  All elements connected to this event via a commitment, regardless
  #  of status.
  #
  def all_commitment_elements_regardless
    @commitments.collect {|c| c.element}
  end

  #
  #  All elements connected to this event via a request, regardless
  #  of status.
  #
  def all_request_elements_regardless
    @requests.collect {|r| r.element}
  end

  #
  #  All elements connected to this event, regardless of how.
  #
  def all_resource_elements_regardless
    (@commitments.collect {|c| c.element} +
     @requests.collect {|r| r.element}).uniq
  end

  def controlled_commitment_texts
    @controlled_commitments.collect {|cc|
      "#{cc.element.name} - #{cc.approval_status}"
    }
  end

  #
  #  Call this with a block.
  #
  def each_controlled_commitment
    @controlled_commitments.each do |cc|
      yield cc.element, cc.approval_status
    end
  end

  def each_request
    @requests.each do |r|
      yield r.element, r.quantity, r.allocation_status
    end
  end

  #
  #  This doesn't mean alternate commitments - it means all the commitments
  #  which aren't either controlled or related to a request.
  #
  def each_other_commitment
    @other_commitments.each do |oc|
      yield oc.element
    end
  end

  #
  #  Returns a string (like "22.7%") suitable for indicating how complete
  #  the event is.  Each commitment counts as three points, and each request
  #  counts as 2 + N points, where N is the number of the item requested.
  #
  #  Un-controlled resources do not count.
  #
  #  Commitment:
  #
  #  0 - form still to be filled in, or rejected
  #  1 - form partially filled in
  #  2 - form filled in, or no form
  #  3 - approved
  #
  #  Request:
  #
  #  0 - form still to be filled in
  #  1 - form partially filled in
  #  2 - form filled in, or no form
  #  
  #  then one more point for each allocated resource.
  #
  def percentage_complete
    potential_score =
      (@controlled_commitments.count * 3) +
      (@requests.inject(0) {|sum, request| sum + 2 + request.quantity })
    actual_score = 0
    @controlled_commitments.each do |cc|
      actual_score += cc.approval_score
    end
    @requests.each do |request|
      actual_score += request.allocation_score
    end
    percentage = (actual_score.to_f * 100.0) / potential_score.to_f
    "#{'%.1f' % percentage}%"
  end
end
