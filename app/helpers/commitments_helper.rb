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
              :method => :put, :remote => true)
     }</span>"
  end

  def header_menu_text(user)
    if user.element_owner
      "Menu (#{user.permissions_pending})"
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
      #
      #  Does it need any embellishment?
      #
      if commitment.rejected
        body = "<span class=\"rejected-commitment\">#{body}</span>"
      elsif commitment.tentative
        body = "<span class=\"tentative-commitment\">#{body}</span>"
      elsif commitment.constraining
        body = "<span class=\"constraining-commitment\">#{body}</span>"
      end
      #
      #  And any buttons?
      #
      if (commitment.tentative || commitment.constraining) &&
         user.can_approve?(commitment)
        #
        #  Usually we don't get a delete link, but it's just possible
        #  we might.  If we actually own the event, rather than just
        #  having overriding edit permission (usually brought on by
        #  controlling one of the resources) then we still need the button.
        #
        if editing && user.owns?(event)
          body = "#{body} #{delete_link(commitment)}"
        end
        if commitment.rejected
          body = "#{body} #{approve_link(commitment, "Yes")}" 
        elsif commitment.tentative
          body = "#{body} #{approve_link(commitment, "Yes")}/#{reject_link(commitment, "No")}" 
        else
          body = "#{body} #{reject_link(commitment, "No")}" 
        end
      elsif editing
        body = "#{body} #{delete_link(commitment)}"
      end
      result << "<li>#{body}</li>"
    end
    result << "</ul>"
    result.join("\n").html_safe
  end

end

