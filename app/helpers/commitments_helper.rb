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

  def approve_link(commitment, text)
    "<span class=\"commitment-yes\">#{
      link_to(text, approve_commitment_path(commitment),
              :method => :put, :remote => true)
     }</span>"
  end

  def reject_link(commitment, text)
    "<span class=\"commitment-no\">#{
      link_to(text, reject_commitment_path(commitment),
              :method => :put,
              :remote => true,
              :class => "rejection-link")
     }</span>"
  end

  def header_menu_text(user)
    if user.element_owner
      "Menu (<span id='pending_count'>#{user.permissions_pending}</span>)".html_safe
    else
      "Menu"
    end
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
        if commitment.rejected
          body = "<span class=\"rejected-commitment\" title=\"#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : "" }\">#{body}</span>"
        elsif commitment.tentative
          body = "<span class=\"tentative-commitment\">#{body}</span>"
        elsif commitment.constraining
          body = "<span class=\"constraining-commitment\">#{body}</span>"
        end
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
        unless commitment.tentative || commitment.rejected
          result << "<li>#{body}</li>"
        end
      end
    end
    result << "</ul>"
    result.join("\n").html_safe
  end

end

