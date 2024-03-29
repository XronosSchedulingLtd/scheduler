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
    @event_summary = EventSummary.new(@event)
    @element = commitment.element
    @commitment = commitment
    if commitment.reason.blank?
      @reason = "no reason was given"
    else
      @reason = commitment.reason
    end
    if commitment.by_whom
      @approver = commitment.by_whom.name
      parameters[:reply_to] = commitment.by_whom.email
      @approver_email = commitment.by_whom.email
    else
      @approver = "the system"
    end
    if @event && @element && @reason
      #
      #  Who the e-mail goes to depends on what information is in the
      #  event.
      #
      email = appropriate_email(@event)
      if email
        @user = User.find_by(email: email)
        @subject = "Resource request declined"
        @um_functional_styling = true
        parameters[:to] = email
        parameters[:subject] = @subject
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
    @event_summary = EventSummary.new(@event)
    @element = commitment.element
    @commitment = commitment
    if commitment.reason.blank?
      @reason = nil
    else
      @reason = commitment.reason
    end
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
        @subject = 'Resource request noted'
        @um_functional_styling = true
        parameters[:to] = email
        parameters[:subject] = @subject
        parameters[:from] = Setting.from_email_address
        mail(parameters)
      else
        Rails.logger.info("Unable to send request noted e-mail.  No-one to send to.")
      end
    end
  end

  def commitment_approved_email(commitment)
    parameters = Hash.new
    @event      = commitment.event
    @event_summary = EventSummary.new(@event)
    @element    = commitment.element
    @commitment = commitment
    @complete   = @event.complete
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
        @subject = "Resource request approved"
        @um_functional_styling = true
        parameters[:to] = email
        parameters[:subject] = @subject
        parameters[:from] = Setting.from_email_address
        mail(parameters)
      else
        Rails.logger.info("Unable to send commitment approved e-mail.  No-one to send to.")
      end
    end
  end

  def do_commitment_email(owner, resource, event, user, cancelled)
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
  def commitment_requested_email(owner, resource, event, user = nil)
    do_commitment_email(owner, resource, event, user, false)
  end

  def commitment_request_cancelled_email(owner, resource, event, user = nil)
    do_commitment_email(owner, resource, event, user, true)
  end

  def do_request_email(subject, owner, resource, event, record, user = nil)
    @resource = resource
    @event = event
    parameters = {
      to:      owner.email,
      from:    Setting.from_email_address,
      subject: subject
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
    @previous_quantity = record.original_quantity
    @new_quantity      = record.current_quantity
    @num_allocated     = record.num_allocated
    mail(parameters)
  end

  def request_adjusted_email(owner, resource, event, record, user = nil)
    do_request_email("Request for #{resource.name} adjusted",
                     owner,
                     resource,
                     event,
                     record,
                     user)
  end

  def request_created_email(owner, resource, event, record, user = nil)
    do_request_email("New request for #{resource.name}",
                     owner,
                     resource,
                     event,
                     record,
                     user)
  end

  def request_deleted_email(owner, resource, event, record, user = nil)
    do_request_email("Request for #{resource.name} deleted",
                     owner,
                     resource,
                     event,
                     record,
                     user)
  end

  def event_deleted_email(
    owner,        # The owner of the resource
    resource,     # The resource - an element.  May be nil.
    event,        # The event being deleted
    quantity,     # The quantity requested, or nil
    allocated,    # The number already allocated
    user)         # The person who did the deed

    @resource      = resource
    @event         = event
    @event_summary = EventSummary.new(@event)
    if @resource
      @subject       = "Event using #{@resource.name} deleted"
    else
      @subject       = "Event deleted"
    end
    @body_subject  = "Event deleted"
    @quantity      = quantity
    @allocated     = allocated
    @user_name     = user.name
    @um_functional_styling = true
    parameters = {
      to:      owner.email,
      from:    Setting.from_email_address,
      subject: @subject
    }
    mail(parameters)
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

  def resource_clash_email(email, queues)
    @queues = queues
    @um_functional_styling = true
    mail(to: email,
         from: Setting.from_email_address,
         subject: "Possible clashing events")
  end

  def predicted_absences_email(email, event_notes)
    @subject = 'Predicted absences'
    texts = Array.new
    event_notes.each do |en|
      title = "Projected absences for #{en.event.body} on #{en.event.starts_at.strftime("%d/%m/%Y")}."
      texts << title
      texts << en.note.contents.indent(2)
    end
    @body_text = texts.join("\n")
    @event_notes = event_notes
    @um_functional_styling = true
    mail(to: email,
         from: Setting.from_email_address,
         subject: @subject)
  end

  def resource_loading_email(email, item)
    @element = item.element
    @data = item.data
    @num_overloads = item.num_overloads
    mail(to: email,
         from: Setting.from_email_address,
         subject: "Predicted loading for resource \"#{item.element.name}\"")
  end

  def forms_overdue_email(email, items, user)
    @items = items
    @user = user
    @subject = 'There are forms awaiting your input'
    @um_functional_styling = true
    mail(to: email,
         from: Setting.from_email_address,
         subject: @subject)
  end

  def reconfirm_requests_email(email, items, user)
    @items = items
    @user = user
    @subject = 'Please reconfirm your requests'
    @um_functional_styling = true
    mail(to: email,
         from: Setting.from_email_address,
         subject: @subject)
  end

  def prompt_for_staff_email(email, items, user)
    @items = items
    @user = user
    @subject = 'Please add staff to your events'
    @um_functional_styling = true
    mail(to: email,
         from: Setting.from_email_address,
         subject: @subject)
  end

  def comment_added_email(
    email,
    event,
    element,
    comment,
    commenter,
    did_pushback)
    @comment = comment
    @event = event
    @event_summary = EventSummary.new(@event)
    @element = element
    @commenter = commenter
    @did_pushback = did_pushback
    @subject = "Comment added to form"
    @user = User.find_by(email: email)
    @um_functional_styling = true
    mail(
      to: email,
      from: Setting.from_email_address,
      reply_to: commenter.email,
      subject: @subject)
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
