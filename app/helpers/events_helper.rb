module EventsHelper

  def highlighted_name(commitment)
    text = h(commitment.element.name)
    if commitment.covering
      text = text + " (covering #{h(commitment.covering.element.short_name)})"
    end
    if commitment.rejected
      text = "<span class='rejected-commitment' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'>#{text}</span>"
    elsif commitment.tentative
      text = "<span class='tentative-commitment'>#{text}</span>"
    elsif commitment.constraining
      text = "<span class='constraining-commitment'>#{text}</span>"
    end
    text
  end

  #
  #  Generate suitable html to list the members of a commitment set
  #  reasonably intelligently.
  #
  def list_commitment_set(commitment_set)
    results = Array.new
    commitment_set.each do |commitment|
      #
      #  Don't list covered commitments explicitly.  Let them appear
      #  under the covering commitment.
      #
      unless commitment.covered
        results << highlighted_name(commitment)
      end
    end
    results.join(", ").html_safe
  end

  def approval_links(commitment)
    text = highlighted_name(commitment)
    if commitment.rejected
      text = "#{text} #{approve_link(commitment, "Confirm")}"
    elsif commitment.tentative
      text = "#{text} #{approve_link(commitment, "Confirm")} / #{reject_link(commitment, "Raise issue")}"
    else
      text = "#{text} #{reject_link(commitment, "Raise issue")}"
    end
    text.html_safe
  end

end
