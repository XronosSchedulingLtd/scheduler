# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ReconfirmationPrompter

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet < Hash

    #
    #  One of these per user who is going to get notices.
    #
    class Recipient

      class Item
        attr_reader :request

        def initialize(request)
          @request = request
        end

        def event_description
          "#{@request.event.starts_at_text} - #{@request.event.body}"
        end

        def request_description
          quantity = @request.quantity
          resource = @request.element.name
          "#{ActionController::Base.helpers.pluralize(quantity, resource)}"
        end

        def to_partial_path
          'request_reconfirmation_item'
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
        @items = Array.new
      end

      def note_request(request)
        @items << Item.new(request)
      end

      #
      #  Send the e-mails for this recipient.
      #
      def send_emails
        UserMailer.reconfirm_requests_email(@user.email,
                                            @items.sort,
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

    def note_request(user, request)
      self.recipient(user).note_request(request)
    end
  end

  attr_reader :rs

  def initialize
    @rs = RecipientSet.new
  end

  def process_element(element)
    if element.entity.respond_to?(:confirmation_days)
      confirmation_days = element.entity.confirmation_days
      if confirmation_days > 0
        start_date = Date.today
        end_date = start_date + confirmation_days
        requests =
          element.requests.
                  includes(event: :owner).
                  during(start_date, end_date).
                  awaiting_reconfirmation
        requests.each do  |request|
          user = request.event.owner
          if user
            #
            #  Some users do a lot of this and they're allowed to
            #  opt out of receiving these prompts.
            #
            if user.confirmation_messages
              @rs.note_request(user, request)
            end
          end
        end
      end
    end
  end

  def scan_requests
    #
    #  We have an interesting problem in that we're really only interested
    #  in entities which:
    #
    #  a) Have the right configuration field, and
    #  b) Have it set to a value > 0
    #
    #  For now this means just resourcegroups.  It makes sense to try to
    #  fetch as few as possible from the database now, because otherwise
    #  we might get many hundreds, but each resourcegroup might have a
    #  different setting.  The approach we take is to do it one resource
    #  group at a time.
    #
    #  Work will be needed as and when requests are added to other
    #  things.
    #
    Resourcegroup.all.includes(:element).each do |rg|
      process_element(rg.element)
    end
    self
  end

  def send_emails
    @rs.send_emails
    nil
  end

end
