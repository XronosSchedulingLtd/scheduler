class UserMailer < ActionMailer::Base
  default from: "abingdon@scheduler.org.uk"

  def cover_clash_email(user, clashes, oddities)
    @clashes = clashes.sort
    @oddities = oddities.sort
    @current_clash_date_html  = Time.zone.parse("2010-01-01")
    @current_clash_date_txt   = Time.zone.parse("2010-01-01")
    @current_oddity_date_html = Time.zone.parse("2010-01-01")
    @current_oddity_date_txt  = Time.zone.parse("2010-01-01")
    mail(to: user.email,
         subject: "Possible cover issues")
  end

  def commitment_rejected_email(commitment)
    parameters = Hash.new
    @event = commitment.event
    @element = commitment.element
    if commitment.reason.blank?
      @reason = "no reason was given"
    else
      @reason = commitment.reason
    end
    if commitment.by_whom
      @rejecter = commitment.by_whom.name
      parameters[:reply_to] = commitment.by_whom.email
    else
      @rejecter = "the system"
    end
    if @event && @element && @reason
      #
      #  Who the e-mail goes to depends on what information is in the
      #  event.
      #
      if @event.organiser
        parameters[:to] = @event.organiser.entity.email
      else
        parameters[:to] = @event.owner.email
      end
      parameters[:subject] = "Resource request declined"
      mail(parameters)
    end
  end

  def event_complete_email(event)
    @event = event
    if @event.organiser
      email = @event.organiser.entity.email
    else
      email = @event.owner.email
    end
    mail(to: email, subject: "Event now complete")
  end

  def resource_requested_email(owner, resource, event)
    @resource = resource
    @event = event
    if @event.organiser
      @name = @event.organiser.entity.name
    else
      @name = @event.owner.name
    end
    mail(to: owner.email, subject: "Request for #{resource.name}")
  end

  def pending_approvals_email(email, user_set)
    @user_set = user_set
    mail(to: email, subject: "Pending event approvals")
  end

  def clash_notification_email(email, body_text)
    @body_text = body_text
    mail(to: email, subject: "Predicted absences")
  end

end
