module CommitmentsHelper

  def approval_table_header
    ["<table class=\"zftable\">",
     "  <tr>",
     "    <th>Event</th>",
     "    <th>Owner</th>",
     "    <th>Organiser</th>",
     "    <th>Starts</th>",
     "    <th>Ends</th>",
     "    <th>Otherwise<br/>complete</th>",
     "    <th></th>",
     "  </tr>"].join("\n").html_safe
  end

  #
  #  This one is for use in the commitment listing.
  #
  def commitment_approval_links(commitment)
    if commitment.confirmed?
      text = reject_link(commitment, "Reject", true)
    elsif commitment.requested?
      text = "#{approve_link(commitment, "Approve", true)} / #{reject_link(commitment, "Reject", true)} / #{noted_link(commitment, "Noted", true)}"
    elsif commitment.rejected?
      text = "#{approve_link(commitment, "Approve", true)} / #{noted_link(commitment, "Noted", true)}"
    elsif commitment.noted?
      text = "#{approve_link(commitment, "Approve", true)} / #{reject_link(commitment, "Reject", true)}"
    else
      #
      #  Should be just "uncontrolled", but allow for anything.
      #
      text = ""
    end
    text.html_safe
  end

  def element_name_with_cover(commitment)
    result = h(commitment.element.name)
    if commitment.covering
      result = result +
                "<br/>&nbsp;&nbsp;(Covering ".html_safe +
                h(commitment.covering.element.name) +
                ")"
    end
    if commitment.covered
      result = result +
                "<br/>&nbsp;&nbsp;(Covered by ".html_safe +
                h(commitment.covered.element.name) +
                ")"
    end
    result
  end

  def delete_link(commitment)
    link_to("&#215;".html_safe, commitment, method: :delete, remote: true)
  end

  def approve_link(commitment, text, singleton = false)
    #
    #  A bit of reverse-compatibility.  New code has singleton set to true.
    #
    if singleton
      "<span class=\"commitment-yes\">#{
        link_to(text, "#", class: "approval-yes")
       }</span>"
    else
      "<span class=\"commitment-yes\">#{
        link_to(text, approve_commitment_path(commitment),
                :method => :put, :remote => true)
       }</span>"
    end
  end

  def reject_link(commitment, text, singleton = false)
    if singleton
      "<span class=\"commitment-no\">#{
        link_to(text, "#", class: "approval-no")
       }</span>"
    else
      "<span class=\"commitment-no\">#{
        link_to(text, reject_commitment_path(commitment),
                :method => :put,
                :remote => true,
                :class => "rejection-link")
       }</span>"
    end
  end

  def noted_link(commitment, text, singleton = false)
    if singleton
      "<span class=\"commitment-noted\">#{
        link_to(text, "#", class: "approval-noted")
       }</span>"
    else
      "<span class=\"commitment-noted\">#{
        link_to(text, noted_commitment_path(commitment),
                :method => :put,
                :remote => true,
                :class => "noted-link")
       }</span>"
    end
  end

  def header_menu_text(user)
    if user.create_events?
      "Menu (<span id='pending-grand-total' data-auto-poll=#{user.start_auto_polling}>#{user.pending_grand_total}</span>)".html_safe
    else
      "Menu"
    end
  end

#  def form_menu_text(user)
#    if user.create_events?
#      "Forms (<span id='pending-forms'>#{user.forms_pending}</span>)".html_safe
#    else
#      "Forms"
#    end
#  end

  def events_menu_text(user)
    "Events (<span id='pending-events-total'>#{user.events_pending_total}</span>)".html_safe
  end

  def my_events_menu_text(user)
    "Mine (<span id='pending-my-events'>#{user.events_pending}</span>)".html_safe
  end

  def controlled_element_menu_text(ce)
    "#{ce.name} (<span id='pending-element-#{ce.id}'>#{ce.permissions_pending}</span>)".html_safe
  end

  def commitment_entries_for(event, target_class, editing, user)
    commitments =
      event.commitments.select {|c| c.element.entity_type == target_class.to_s}
    result = ["<ul class=\"no-bullet\">"]
    commitments.each do |commitment|
      body = element_name_with_cover(commitment)
      if user
        #
        #  Does it need any embellishment?
        #
        body = icon_prefix(commitment, body)
        #
        #  And any buttons?
        #
        if editing && user.can_delete?(commitment)
          body = "#{body} #{delete_link(commitment)}"
        end
        #
        #  If the user is editing this event, then we also do a quick
        #  check for clashes.  This is done for people and places only.
        #
        if editing &&
           (target_class == Staff ||
            target_class == Pupil ||
            target_class == Location) &&
           commitment.has_simple_clash?
          #
          #  Put it in yet another span.
          #
          body = "<span class=\"double-booked\" title=\"Double booked\">#{body}</span>"
        end
        result << "<li>#{body}</li>"
      else
        #
        #  Non logged-in users just get to see firm commitments, and
        #  don't get any colours or buttons.
        #
        unless commitment.tentative? || commitment.rejected?
          result << "<li>#{body}</li>"
        end
      end
    end
    result << "</ul>"
    result.join("\n").html_safe
  end

  def commitment_status(commitment)
    if commitment.rejected?
      "Rejected"
    elsif commitment.requested?
      "Pending"
    elsif commitment.noted?
      "Noted"
    else
      "OK"
    end
  end

  def commitment_status_class(commitment)
    #
    #  The model actually does the work.
    #
    commitment.status_class
  end

  def commitment_form_status(commitment)
    response = commitment.user_form_response
    if response
      if response.complete?
        link_to("Complete", user_form_response_path(response))
      elsif response.partial?
        link_to("Partial", user_form_response_path(response))
      else
        "Empty"
      end
    else
      "None"
    end
  end

  def commitment_owner_mailto(commitment)
    email = commitment.event.owners_email
    if email
      mail_to(email,
              commitment.event.owners_initials,
              target: "_blank").html_safe
    else
      commitment.event.owners_initials
    end
  end

  def commitment_organiser_mailto(commitment)
    email = commitment.event.organisers_email
    if email
      mail_to(email,
              commitment.event.organisers_initials,
              target: "_blank").html_safe
    else
      commitment.event.organisers_initials
    end
  end

  def approvals_image(
    action:,
    size:     32,
    enabled:  true,
    title:    nil)

    "<img #{
      enabled ? "class=\"approval-#{action}\"" : "class=\"approval-disabled-button\""
    } #{
      enabled && title ? "title=\"#{title}\"" : ""
    } src=\"/images/#{action}#{size}.png\">"
  end

  def approve_icon(enabled)
    approvals_image(action: "approve", enabled: enabled, title: "Approve").html_safe
  end

  def approved_icon
    approvals_image(action: "approve", size: 16, enabled: true).html_safe
  end

  def reject_icon(enabled)
    approvals_image(action: "reject", enabled: enabled, title: "Reject").html_safe
  end

  def rejected_icon
    approvals_image(action: "reject", size: 16, enabled: true).html_safe
  end

  def note_icon(enabled)
    approvals_image(action: "hold",
                    enabled: enabled,
                    title: "Noted - hold pending more information").html_safe
  end

  def noted_icon
    approvals_image(action: "hold", size: 16, enabled: true).html_safe
  end

  def requested_icon
    approvals_image(action: "request", size: 16, enabled: true).html_safe
  end

  def three_icons(approve, noted, reject)
    "#{approve_icon(approve)} #{note_icon(noted)} #{reject_icon(reject)}".html_safe
  end

  def blank_icon(enabled)
    approvals_image(action: "blank",
                    enabled: enabled).html_safe
  end

end

