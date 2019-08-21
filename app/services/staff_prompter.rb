# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class StaffPrompter

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet < Hash

    #
    #  One of these per user who is going to get notices.
    #
    class Recipient

      class Item
        attr_reader :event, :num_needed, :num_staff

        def initialize(event, num_needed, num_staff)
          @event      = event
          @num_needed = num_needed
          @num_staff  = num_staff
        end

        def event_description
          "#{@event.starts_at_text} - #{@event.body}"
        end

        def request_description
          "#{@num_needed} staff needed (currently #{@num_staff})"
#          "#{@num_staff} staff attached to the event out of #{@num_needed} apparently needed"
        end

        def to_partial_path
          'request_reconfirmation_item'
        end

        def <=>(other)
          if other.instance_of?(Item)
            self.event <=> other.event
          else
            nil
          end
        end

      end

      attr_reader :email

      def initialize(user)
        @user  = user
        @items = Hash.new
      end

      def note_event(event, num_needed, num_staff)
        unless @items[event.id]
          @items[event.id] = Item.new(event, num_needed, num_staff)
        end
      end

      #
      #  Send the e-mails for this recipient.
      #
      def send_emails
        UserMailer.prompt_for_staff_email(@user.email,
                                          @items.values.sort,
                                          @user).deliver_now
      end

    end
    #
    #  Find the recipient record for a given e-mail address, creating
    #  it if it does not already exist.
    #
    def recipient(user)
      self[user.email] ||= Recipient.new(user)
    end

    def send_emails
      self.each do |key, r|
        r.send_emails
      end
    end

    def note_event(user, event, num_needed, num_staff)
      self.recipient(user).note_event(event, num_needed, num_staff)
    end
  end

  attr_reader :rs

  def initialize
    @rs = RecipientSet.new
  end

  def process_event(event)
    #
    #  What we have here is an event with at least one request
    #  which needs to have staff numbers checked.
    #
    num_staff = event.staff(true).count
    #
    #  And how many do we need?
    #  Interestingly, the corresponding requested elements should
    #  be already in memory, but I suspect we're going to generate
    #  another database hit because they were selectively loaded
    #  and there's no way I know of for saying, "Just the ones
    #  already loaded".
    #
    num_needed = 0
    event.requests.includes(element: {entity: :persona} ).each do |request|
      if request.element.entity.respond_to?(:needs_people?)
        num_needed += request.quantity
      end
    end
    if num_needed > num_staff
      #
      #  This one warrants a warning e-mail.  It should go to both the
      #  owner and the organiser (if any), unless they have opted out.
      #
      #  The accumulation code invoked by note_event will filter out
      #  duplicates.
      #
      owner = event.owner
      if owner && owner.prompt_for_forms?
        @rs.note_event(owner, event, num_needed, num_staff)
      end
      #
      #  And the organiser, if any.
      #
      organiser = event.organiser_user
      if organiser  && organiser.prompt_for_forms?
        @rs.note_event(organiser, event, num_needed, num_staff)
      end
    end
  end

  def scan_events
    #
    #  For now we are processing just resource groups.  We may later
    #  decide to extend this to other things.
    #
    #  Start by finding all the Resourcegroups which have the relevant
    #  bits set.
    #
    num_days = 0
    element_ids =
      Resourcegroup.all.
                    includes([:element, :persona]).
                    select {|rg| rg.needs_people? && rg.form_warning_days > 0}.
                    collect do |rg|
                      if rg.form_warning_days > num_days
                        num_days = rg.form_warning_days
                      end
                      rg.element.id
                    end
    #
    #  And then we want all the relevant events in the indicated
    #  time period.
    #
    if num_days > 0
      start_date = Date.today
      end_date = start_date + num_days
      events = Event.includes(:requested_elements).
                     during(start_date, end_date).
                     where(elements: { id: element_ids })
      events.each do |event|
        process_event(event)
      end
    end
    self
  end

  def send_emails
    @rs.send_emails
    nil
  end

end
