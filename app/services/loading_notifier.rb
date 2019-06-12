# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class LoadingNotifier

  #
  #  Responsible for storing and finding Recipient records.
  #
  class RecipientSet < Hash

    #
    #  One of these per user who is going to get notices.
    #
    class Recipient

      Item = Struct.new(:element, :data, :num_overloads)

      attr_reader :email

      def initialize(email)
        @email = email
        @items = Array.new
      end

      def note_loading_data(element, data, num_overloads)
        @items << Item.new(element, data, num_overloads)
      end

      def dump
        puts "    Dumping Recipient"
        puts "    Email #{@email}"
        puts "    Has #{@items.size} items"
      end

      #
      #  Send the e-mails for this recipient.
      #
      def send_emails
        @items.each do |item|
          UserMailer.resource_loading_email(@email,
                                            item).deliver_now
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
    (element.concerns.owned.collect {|c| c.user} +
     User.administrators.to_a).
     uniq.select {|u| u.loading_notification?}.
     collect {|u| u.email}
  end

  def process_element(element, num_days)
    if num_days > 0
      approver_emails = appropriate_approver_emails(element)
      calculator = ResourceLoadingCalculator.new(element)
      #
      #  For now we'll do the next week.  To be changed.
      #
      days = Array.new
      Date.today.upto(Date.today + (num_days - 1).days) do |date|
        days << calculator.loading_on(date)
      end
      num_overloads = ResourceLoadingCalculator.count_overloads(days)
      approver_emails.each do |ae|
        @rs.recipient(ae).note_loading_data(element, days, num_overloads)
      end
    end
  end

  def scan_elements
    #
    #  Although the loading calculator module can potentially cope with
    #  doing it for any element, at present we do it only for elements
    #  which accommodate Requests - effectively just ResourceGroups.
    #
    Element.owned.includes(:entity).each do |element|
      if element.can_have_requests? &&
         element.entity.respond_to?(:loading_report_days)
        self.process_element(element, element.entity.loading_report_days)
      end
    end
    self
  end

  def send_emails
    @rs.send_emails
    nil
  end

  def dump
    puts "Dumping LoadingNotifier"
    @rs.dump
    nil
  end
end
