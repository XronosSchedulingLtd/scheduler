# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class FormPrompter

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet < Hash

    #
    #  One of these per user who is going to get notices.
    #
    class Recipient

      class Item
        attr_reader :request, :ufr

        def initialize(request, ufr)
          @request = request
          @ufr     = ufr
        end

        def to_partial_path
          'pending_form_item'
        end

        def event_description
          "#{@request.event.starts_at_text} - #{@request.event.body}"
        end

        def request_description
          quantity = @request.quantity
          resource = @request.element.name
          "#{ActionController::Base.helpers.pluralize(quantity, resource)}"
        end

        def <=>(other)
          if other.instance_of?(Item)
            self.request <=> other.request
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

      def note_form_needing_attention(request, ufr)
        unless @items[request.id]
          @items[request.id] = Item.new(request, ufr)
        end
      end

      #
      #  Send the e-mails for this recipient.
      #
      def send_emails
        UserMailer.forms_overdue_email(@user.email,
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

    def note_form_needing_attention(user, request, ufr)
      self.recipient(user).note_form_needing_attention(request, ufr)
    end
  end

  attr_reader :rs

  def initialize
    @rs = RecipientSet.new
  end

  def process_element(element)
    if element.entity.respond_to?(:form_warning_days)
      #
      #  Now for this element we want to find all events with
      #  forms in a state other than "complete" which are:
      #
      #  a) in the future
      #  b) within N days of today
      #
      #  The events may be linked either via commitments or
      #  via requests.  We don't cope with commitments via
      #  groups because the forms mechanism doesn't work in this
      #  scenario anyway.
      #
      form_warning_days = element.entity.form_warning_days
      if form_warning_days > 0
        start_date = Date.today
        end_date = start_date + form_warning_days
        #
        #  Once any resources have been allocated the form
        #  is locked and so there's no point in prompting the
        #  user.
        #
        requests =
          element.requests.
                  includes(:event, user_form_response: :user).
                  during(start_date, end_date).
                  none_allocated.
                  with_incomplete_form
        requests.each do  |request|
          ufr = request.user_form_response
          if ufr
            event = request.event
            owner = event.owner
            if owner && owner.prompt_for_forms?
              @rs.note_form_needing_attention(owner, request, ufr)
            end
            #
            #  And the organiser, if any.
            #
            organiser = event.organiser_user
            if organiser  && organiser.prompt_for_forms?
              @rs.note_form_needing_attention(organiser, request, ufr)
            end
          end
        end
      end
    end
  end

  def scan_elements
    #
    #  We are interested in all elements with forms attached, although
    #  for now we send the e-mails only for those which have a configured
    #  day threshold for sending them.
    #
    Element.with_form.includes(:entity).each do |element|
      process_element(element)
    end
    self
  end

  def send_emails
    @rs.send_emails
    nil
  end

end
