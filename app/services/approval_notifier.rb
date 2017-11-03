
class ApprovalNotifier

  #
  #  One of these per user who is going to get notices.
  #
  class Recipient

    class ElementQueue
      attr_reader :element

      def initialize(element)
        @element = element
        @commitments = Array.new
      end

      def <<(commitment)
        @commitments << commitment
      end

      def dump
        puts "      #{@element.name}"
        puts "        #{@commitments.size} commitments"
      end
    end

    attr_reader :pending_sets, :email

    def initialize(email)
      @email = email
      @rejections = Array.new
      @forms = Array.new
      @my_queues = Hash.new
    end

    def send_email
      UserMailer.pending_approvals_email(@user.email, self).deliver
    end

    def note_request(element, commitment)
      queue = (@my_queues[element.id] ||= ElementQueue.new(element))
      queue << commitment
    end

    def note_form(commitment)
      @forms << commitment
    end

    def note_rejection(commitment)
      @rejections << commitment
    end

    def dump
      puts "    Dumping Recipient"
      puts "    Email #{@email}"
      puts "    #{@rejections.size} rejections"
      puts "    #{@forms.size} forms to fill in"
      puts "    #{@my_queues.size} resources"
      @my_queues.each do |key, mq|
        mq.dump
      end
    end

    def self.send_emails
      @@user_sets.each do |key, us|
        us.send_email
      end
    end

  end

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet

    def initialize
      @recipients = Hash.new
    end

    #
    #  Find the recipient record for a given e-mail address, creating
    #  it if it does not already exist.
    #
    def recipient(email)
      @recipients[email] ||= Recipient.new(email)
    end

    def count
      @recipients.count
    end

    def dump
      puts "  Dumping RecipientSet"
      @recipients.each do |key, r|
        r.dump
      end
    end

  end

  attr_reader :rs

  def initialize
    @rs = RecipientSet.new
  end

  #
  #  Return the e-mail of the requester of a resources.
  #
  #  Note that it is possible (just) for the event to have neither
  #  owner nor organiser.  This can happen when a teacher chooses
  #  to re-locate a lesson to another room which is a controlled
  #  resource, and then the controller rejects the request.
  #
  #  Order of choice is:
  #
  #  Organiser
  #  Owner
  #  Teacher
  #
  #  and if all else fails, return nil.
  #
  def requester_email(c)
    event = c.event
    if event.organiser
      event.organiser.entity.email
    elsif event.owner
      event.owner.email
    else
      staff = event.staff
      if staff.size > 0
        staff[0].entity.email
      else
        nil
      end
    end
  end

  #
  #  Find the approvers for the indicated element who have opted
  #  to receive daily e-mails. (It's actually an opt-out thing.
  #  The default is on.)
  #
  def appropriate_approver_emails(element)
    (element.concerns.owned.collect {|c| c.user} +
     User.administrators.to_a).
     uniq.select {|u| u.email_notification}.
     collect {|u| u.email}
  end

  def process_element(element)
    #
    #  We need to find all future commitments for this element which are
    #  in a state which warrants some sort of notification.  For each
    #  one found, we add a record to our data structures, enabling us
    #  to send e-mails later.
    #
    #  Events can be in one of five states:
    #
    #  Uncontrolled
    #  Confirmed
    #  Requested
    #  Rejected
    #  Noted
    #
    #  Of these, only "Requested" and "Rejected" warrant any e-mails.
    #
    approver_emails = appropriate_approver_emails(element)
    element.commitments.
            future.
            notifiable.
            includes([:event, :user_form_responses]).each do |c|
      if c.requested?
        if c.user_form_responses.size == 0 || c.user_form_responses[0].complete?
          approver_emails.each do |ae|
            @rs.recipient(ae).note_request(element, c)
          end
        elsif c.user_form_responses.size > 0 && c.user_form_responses[0].empty?
          email = requester_email(c)
          if email
            @rs.recipient(email).note_form(c)
          end
        end
      elsif c.rejected?
        email = requester_email(c)
        if email
          @rs.recipient(email).note_rejection(c)
        end
      end
    end
  end

  def scan_elements
    Element.owned.each do |element|
      self.process_element(element)
    end
  end

  def send_emails
  end

  def dump
    puts "Dumping ApprovalNotifier"
    @rs.dump
    nil
  end
end
