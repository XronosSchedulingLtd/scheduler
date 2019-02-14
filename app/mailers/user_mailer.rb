class UserMailer < ActionMailer::Base
  add_template_helper(UserMailerHelper)

  def cover_clash_email(user, clashes, oddities)
    @clashes = clashes.sort
    @oddities = oddities.sort
    @current_clash_date_html  = Time.zone.parse("2010-01-01")
    @current_clash_date_txt   = Time.zone.parse("2010-01-01")
    @current_oddity_date_html = Time.zone.parse("2010-01-01")
    @current_oddity_date_txt  = Time.zone.parse("2010-01-01")
    mail(to: user.email,
         from: Setting.from_email_address,
         subject: "Possible cover issues")
  end

  def invigilation_clash_email(user, clashes)
    @clashes = clashes.sort
    mail(to: user.email,
         from: Setting.from_email_address,
         subject: "Possible invigilation clashes")
  end

  def commitment_rejected_email(commitment)
    parameters = Hash.new
    @event = commitment.event
    @element = commitment.element
    @commitment = commitment
    if commitment.reason.blank?
      @reason = "no reason was given"
    else
      @reason = commitment.reason
    end
    if commitment.by_whom
      @rejecter = commitment.by_whom.name
      parameters[:reply_to] = commitment.by_whom.email
      @rejecter_email = commitment.by_whom.email
    else
      @rejecter = "the system"
    end
    if @event && @element && @reason
      #
      #  Who the e-mail goes to depends on what information is in the
      #  event.
      #
      email = appropriate_email(@event)
      if email
        @user = User.find_by(email: email)
        parameters[:to] = email
        parameters[:subject] = "Resource request declined"
        parameters[:from] = Setting.from_email_address
        mail(parameters)
      else
        Rails.logger.info("Unable to send request rejected e-mail.  No-one to send to.")
      end
    end
  end

  def commitment_noted_email(commitment)
    parameters = Hash.new
    @event = commitment.event
    @element = commitment.element
    @commitment = commitment
    if commitment.reason.blank?
      @reason = nil
    else
      @reason = commitment.reason
    end
    if commitment.by_whom
      @noter = commitment.by_whom.name
      parameters[:reply_to] = commitment.by_whom.email
      @noter_email = commitment.by_whom.email
    else
      @noter = "the system"
    end
    if @event && @element
      #
      #  Who the e-mail goes to depends on what information is in the
      #  event.
      #
      email = appropriate_email(@event)
      if email
        @user = User.find_by(email: email)
        parameters[:to] = email
        parameters[:subject] = "Resource request noted"
        parameters[:from] = Setting.from_email_address
        mail(parameters)
      else
        Rails.logger.info("Unable to send request noted e-mail.  No-one to send to.")
      end
    end
  end

  def commitment_approved_email(commitment, complete)
    parameters = Hash.new
    @event      = commitment.event
    @element    = commitment.element
    @commitment = commitment
    @complete   = complete
    if commitment.by_whom
      @approver = commitment.by_whom.name
      parameters[:reply_to] = commitment.by_whom.email
      @approver_email = commitment.by_whom.email
    else
      @approver = "the system"
    end
    if @event && @element
      #
      #  Who the e-mail goes to depends on what information is in the
      #  event.
      #
      email = appropriate_email(@event)
      if email
        @user = User.find_by(email: email)
        parameters[:to] = email
        parameters[:subject] = "Request approved"
        parameters[:from] = Setting.from_email_address
        mail(parameters)
      else
        Rails.logger.info("Unable to send request approved e-mail.  No-one to send to.")
      end
    end
  end

  def event_complete_email(event)
    @event = event
    email = appropriate_email(@event)
    if email
      mail(to: email,
           from: Setting.from_email_address,
           subject: "Event now complete")
    else
      Rails.logger.info("Unable to send event complete e-mail.  No-one to send to.")
    end
  end

  def do_resource_email(owner, resource, event, user, cancelled)
    @resource = resource
    @event = event
    parameters = {
      to:      owner.email,
      from:    Setting.from_email_address,
      subject: "Request for #{resource.name}#{cancelled ? " CANCELLED" : ""}"
    }
    if @event.organiser
      parameters[:reply_to] = @event.organiser.entity.email
    elsif @event.owner
      parameters[:reply_to] = @event.owner.email
    elsif user
      parameters[:reply_to] = user.email
    end
    @owner_name = @event.owner ? @event.owner.name : "<System>"
    @organiser_name = @event.organiser ? @event.organiser.name : "<None>"
    @user_name = user ? user.name : "<None>"
    mail(parameters)
  end

  #
  #  These next two look almost identical (and they are) but
  #  because they are different actions the recipient ends up
  #  getting different e-mails.  The names of these actions dictate
  #  the names of the view templates to use.
  #
  def resource_requested_email(owner, resource, event, user = nil)
    do_resource_email(owner, resource, event, user, false)
  end

  def resource_request_cancelled_email(owner, resource, event, user = nil)
    do_resource_email(owner, resource, event, user, true)
  end

  def resource_batch_email(owner, resource, record, user, general_title)
    @resource      = resource
    @record        = record
    @general_title = general_title
    parameters = {
      to:      owner.email,
      from:    Setting.from_email_address,
      subject: "Request(s) for #{resource.name}"
    }
    parameters[:reply_to] = user.email
    @user_name = user.name
    mail(parameters)
  end

  def pending_approvals_email(email, queues)
    @queues = queues
    mail(to: email,
         from: Setting.from_email_address,
         subject: "Pending event approvals")
  end

  def clash_notification_email(email, body_text)
    @body_text = body_text
    mail(to: email,
         from: Setting.from_email_address,
         subject: "Predicted absences")
  end

  def resource_loading_email(email, item)
    @element = item.element
    @data = item.data
    @num_overloads = item.num_overloads
    mail(to: email,
         from: Setting.from_email_address,
         subject: "Predicted loading for resource \"#{item.element.name}\"")
  end

  def forms_overdue_email(email, items)
    @items = items
    mail(to: email,
         from: Setting.from_email_address,
         subject: "There are forms awaiting your input in Scheduler")
  end

  private

  def appropriate_email(event)
    #
    #  Find someone to tell about a change to this event.
    #
    if event.organiser
      email = event.organiser.entity.email
    elsif event.owner
      email = event.owner.email
    else
      staff_element = event.staff_elements.take
      if staff_element
        email = staff_element.entity.email
      else
        email = nil
      end
    end
    email
  end

end
