# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ResourceClashNotifier

  #
  #  Records a resource clash, which may happen on more than one date.
  #
  #  It counts as the same clash if the two clashing events have corresponding
  #  origin_hashes (as defined by Event#origin_hash).
  #
  #  Thus, given A clashing with B and C clashing with D, either:
  #
  #  A.origin_hash == C.origin_hash && B.origin_hash == D.origin_hash
  #
  #  or
  #
  #  A.origin_hash == D.origin_hash && B.origin_hash == C.origin_hash
  #
  #  We have to check both ways because we can't be sure which way around
  #  the pairs might have been created and/or detected.
  #
  #
  #  Our search algorithm is not terribly efficient, but we're anticipating
  #  only relatively few unique cases - perhaps 20 for a single resource.
  #
  class ResourceClash

    def joint_identifier(able, baker)
      #
      #  Create a string which will be the same for any pair of events
      #  which produce the same two naive_identifiers, whichever way around
      #  we are passed the events.
      #
      [able.event.naive_identifier, baker.event.naive_identifier].sort.join("+")
    end

    #
    #  Pass in two commitments which clash.
    #
    #
    def initialize(able, baker)
      @able = able
      @baker = baker
      @joint_naive_id = joint_identifier(able, baker)
      instances = 1
      @dates = [@able.event.starts_at]
      @date_amalgamator = nil
    end

    def matches?(able, baker)
      #
      joint_identifier(able, baker) == @joint_naive_id
    end

    def add(able)
      @dates << able.event.starts_at
    end

    #
    #  These next ones should be called only after we've accumulated
    #  all our dates.
    #
    def as_html
      ensure_amalgamator
      @date_amalgamator.as_html
    end

    def as_text(prefix = "")
      ensure_amalgamator
      @date_amalgamator.as_text(prefix: prefix)
    end

    def description
      st1 = sub_text(@able.event)
      st2 = sub_text(@baker.event)
      "#{st1} and #{st2} on:"
    end

    private

    def ensure_amalgamator
      unless @date_amalgamator
        @date_amalgamator = DateAmalgamator.new(@dates)
      end
    end

    def sub_text(event)
      "#{event.body} #{event.duration_or_all_day_string}"
    end

  end

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet < Hash

    #
    #  One of these per user who is going to get notices.
    #
    class Recipient
      class ElementQueue < Array
        attr_reader :element

        def initialize(element)
          @element = element
          super()
        end

        def dump
          puts "      #{@element.name}"
          puts "        #{self.size} clashes"
        end

        def add(able, baker)
          #
          #  Need to check whether this new entry can be merged with
          #  any of the existing entries in my queue.
          #
          self.each do |entry|
            if entry.matches?(able, baker)
              entry.add(able)
              return
            end
          end
          #
          #  Didn't match any.
          #
          self << ResourceClash.new(able, baker)
        end

      end

      attr_reader :email

      def initialize(email)
        @email = email
        @my_queues = Hash.new
      end

      def note_clash(element, first, second)
        queue = (@my_queues[element.id] ||= ElementQueue.new(element))
        queue.add(first, second)
      end

      def dump
        puts "    Dumping Recipient"
        puts "    Email #{@email}"
        puts "    #{@my_queues.size} resources"
        @my_queues.each do |key, mq|
          mq.dump
        end
      end

      #
      #  Send the e-mails for this recipient.
      #
      def send_emails
        if @my_queues.size > 0
          UserMailer.resource_clash_email(@email,
                                          @my_queues.values).deliver_now
        end
      end

    end
    #
    #  Find the recipient record for a given e-mail address, creating
    #  it if it does not already exist.
    #
    def recipient(email)
      self[email] ||= Recipient.new(email)
    end

    def dump
      puts "  Dumping RecipientSet"
      self.each do |key, r|
        r.dump
      end
    end

    def send_emails
      self.each do |key, r|
        r.send_emails
      end
    end

  end

  attr_reader :rs

  def initialize
    @rs = RecipientSet.new
  end

  #
  #  Find the approvers for the indicated element who have opted
  #  to receive daily e-mails. (It's actually an opt-out thing.
  #  The default is on.)
  #
  def appropriate_approver_emails(element)
    element.concerns.owned.collect {|c| c.user}.
     uniq.select {|u| u.resource_clash_notification?}.
     collect {|u| u.email}
  end

  def process_element(element)
    #
    #  We need to find all future commitments for this element which clash
    #  (in the use of this element) with at least one other future event.
    #
    #  We are interested only in firm commitments - either approved or
    #  uncontrolled.  Requests which have not yet been granted will
    #  be flagged at the confirmation stage.  Requests which have been
    #  rejected are not our problem.
    #
    #  Events can be in one of five states:
    #
    #  Uncontrolled     <=
    #  Confirmed        <=
    #  Requested
    #  Rejected
    #  Noted
    #
    #  Of these, only "Uncontrolled" and "Confirmed" warrant any e-mails.
    #
    approver_emails = appropriate_approver_emails(element)
    non_busy_category_ids =
      Eventcategory.non_busy_categories.collect {|nbc| nbc.id}
    #
    #  Use to_a to load them all in one go.
    #
    relevant_commitments =
      element.
      commitments.
      future.
      firm.
      includes(:event).
      select {|c|
        #
        #  Filter out events in non-busy categories.
        #
        !non_busy_category_ids.include?(c.event.eventcategory_id)
      }.sort
    #
    #  For efficiency, rather than doing a relevant_commitments.each
    #  loop we can shift() each element off the array and then compare
    #  with those remaining.  We thus have a steadily decreasing
    #  array to worry about.
    #
    #  We also need check only until we find an event completely
    #  after our current event, since they're sorted in order.
    #
    while (current = relevant_commitments.shift) do
      #
      #  Need to check the current commitment against those remaining.
      #
      #  Our sort algorithm sorts events into order by start time,
      #  and then end time.  Thus given two events with the same start
      #  time, the shorter one comes first in our sort.
      #
      #  Thus as soon as we detect another event in our remaining array
      #  which does *not* overlap with our current event, we can stop
      #  looking.
      #
      relevant_commitments.each do |candidate|
        if current.overlaps?(candidate)
          #
          #  Found a clash.  It doesn't count as a clash if either
          #  of our two commitments has been covered (i.e. the event
          #  has been relocated to another room).
          #
          unless current.covered || candidate.covered
            approver_emails.each do |ae|
              @rs.recipient(ae).note_clash(element, current, candidate)
            end
          end
        else
          break
        end
      end
    end
  end

  def scan_elements
    Element.owned.each do |element|
      self.process_element(element)
    end
    self
  end

  def send_emails
    @rs.send_emails
    nil
  end

  def dump
    puts "Dumping ApprovalNotifier"
    @rs.dump
    nil
  end
end
