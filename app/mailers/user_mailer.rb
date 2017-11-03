class UserMailer < ActionMailer::Base
  add_template_helper(UserMailerHelper)
  default from: "abingdon@scheduler.org.uk"

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

  def resource_requested_email(owner, resource, event, user = nil)
    @resource = resource
    @event = event
    if @event.organiser
      @name = @event.organiser.entity.name
    elsif @event.owner
      @name = @event.owner.name
    elsif user
      @name = user.name
    else
      @name = "System"
    end
    mail(to: owner.email,
         from: Setting.from_email_address,
         subject: "Request for #{resource.name}")
  end

  def resource_request_cancelled_email(owner, resource, event, user = nil)
    @resource = resource
    @event = event
    if @event.organiser
      @name = @event.organiser.entity.name
    elsif @event.owner
      @name = @event.owner.name
    elsif user
      @name = user.name
    else
      @name = "System"
    end
    mail(to: owner.email,
         from: Setting.from_email_address,
         subject: "Request for #{resource.name} cancelled")
  end

  def pending_approvals_email(email, queues)
    puts "In pending_approvals_email for #{email} with #{queues.size} queues."
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
