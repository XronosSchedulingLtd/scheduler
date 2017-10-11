module EventsHelper

  def be_linken(text, element)
    if can_roam? && element
      link_to(h(text), element)
    else
      h(text)
    end
  end

  def colour_wrap(commitment, text)
    if commitment.rejected
      "<span class='rejected-commitment' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'>#{text}</span>"
    elsif commitment.tentative
      "<span class='tentative-commitment'>#{text}</span>"
    elsif commitment.constraining
      "<span class='constraining-commitment'>#{text}</span>"
    else
      text
    end
  end

  def highlighted_name(commitment, show_clashes, user)
    text = be_linken(commitment.element.name, commitment.element)
    text = colour_wrap(commitment, text)
    if show_clashes && commitment.has_simple_clash? && user
      text = "<span class='double-booked' title='Double booked'>#{text}</span>"
    end
    if commitment.covering
      if commitment.element.entity_type == "Location"
        word = "normally"
      else
        word = "covering"
      end
      text = "#{text} (#{word} <span title='#{h(commitment.covering.element.name)}'>#{be_linken(commitment.covering.element.short_name, commitment.covering.element)}</span>)"
    end
    text
  end

  #
  #  Generate suitable html to list the members of a commitment set
  #  reasonably intelligently.
  #
  def list_commitment_set(commitment_set,
                          user = nil)
    results = Array.new
    commitment_set.each do |commitment|
      #
      #  Don't list covered commitments explicitly.  Let them appear
      #  under the covering commitment.
      #
      unless commitment.covered
        results << highlighted_name(commitment, commitment_set.show_clashes, user)
      end
    end
    results.join(", ").html_safe
  end

  def approval_links(commitment, show_clashes = false, user = nil)
    text = highlighted_name(commitment, show_clashes, user)
    if commitment.rejected
      text = "#{text} #{approve_link(commitment, "Confirm")}"
    elsif commitment.tentative
      text = "#{text} #{approve_link(commitment, "Confirm")} / #{reject_link(commitment, "Raise issue")}"
    else
      text = "#{text} #{reject_link(commitment, "Raise issue")}"
    end
    text.html_safe
  end

  #
  #  These two expect to be called on events where the corresponding
  #  commitments have been pre-loaded into memory.  They will work
  #  without, but it's less efficient.
  #
  def resource_status(event, element)
    commitment = event.commitment_to(element)
    if commitment
      commitment_status(commitment)
    else
      "Unknown"
    end
  end

  def resource_status_class(event, element)
    commitment = event.commitment_to(element)
    if commitment
      commitment.status
    else
      "unknown-commitment"
    end
  end

  def resource_form_status(event, element)
    commitment = event.commitment_to(element)
    if commitment
      commitment_form_status(commitment)
    else
      ""
    end
  end

  #
  #  List all the commitments for an event which are anywhere in the
  #  approvals process - requested, approved, rejected.  Each is coloured
  #  and goes on one line on its own.
  #
  #  We expect the listing code already to have loaded all the commitments
  #  into memory, so use ordinary ruby rather than database queries to
  #  pick the ones which we want.
  #
  def approvals_table_list(event)
    event.commitments.
          select {|c| c.in_approvals?}.
          collect {|c| colour_wrap(c, h(c.element.short_name))}.
          join("<br/>").html_safe
  end

  #
  #  And this one must produce precisely the same number of lines as
  #  the previous one so that they line up in the display.  (Perhaps
  #  need to make sure they're the same height too?)
  #
  def forms_table_list(event)
    event.commitments.
          select {|c| c.in_approvals? }.
          collect do |c|
            status = c.form_status
            if status == "To fill in" || status == "Complete"
              #
              #  Link to edit the form.
              #
              link_to(status,
                      edit_user_form_response_path(c.corresponding_form))
            elsif status == "Locked"
              #
              #  Link to display the form.
              #
              link_to(status,
                      user_form_response_path(c.corresponding_form))
            else
              status
            end
          end.
          join("<br/>").html_safe
  end

  #
  #  Just produces a marker against each potential action.
  #
  def actions_table_list(event)
    event.commitments.
          select {|c| c.in_approvals?}.
          collect do |c|
            if c.rejected || c.form_status == "To fill in"
              "<" 
            else
              "&nbsp;"
            end
          end.
          join("<br/>").html_safe
  end


end
