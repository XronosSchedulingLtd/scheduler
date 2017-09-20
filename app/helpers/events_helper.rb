module EventsHelper

  def be_linken(text, element)
    if can_roam? && element
      link_to(h(text), element)
    else
      h(text)
    end
  end

  def highlighted_name(commitment, show_clashes, user)
    text = be_linken(commitment.element.name, commitment.element)
    if commitment.rejected
      text = "<span class='rejected-commitment' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'>#{text}</span>"
    elsif commitment.tentative
      text = "<span class='tentative-commitment'>#{text}</span>"
    elsif commitment.constraining
      text = "<span class='constraining-commitment'>#{text}</span>"
    end
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
      if commitment.rejected
        "Rejected"
      elsif commitment.tentative
        "Pending"
      else
        "OK"
      end
    else
      "Unknown"
    end
  end

  def resource_status_class(event, element)
    commitment = event.commitment_to(element)
    if commitment
      if commitment.rejected
        "rejected-commitment"
      elsif commitment.tentative
        "tentative-commitment"
      else
        "constraining-commitment"
      end
    else
      "unknown-commitment"
    end
  end

  def resource_form_status(event, element)
    commitment = event.commitment_to(element)
    if commitment
      response = commitment.user_form_responses[0]
      if response
        if response.complete
          "Complete"
        else
          "Pending"
        end
      else
        "None"
      end
    else
      ""
    end
  end

end
