module EventsHelper

  def colour_wrap(commitment, text)
    if commitment.rejected?
      "<span class='rejected-commitment' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'>#{text}</span>"
    elsif commitment.requested?
      "<span class='tentative-commitment'>#{text}</span>"
    elsif commitment.noted?
      "<span class='noted-commitment' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'>#{text}</span>"
    elsif commitment.constraining?
      "<span class='constraining-commitment'>#{text}</span>"
    else
      text
    end
  end

  #
  #  Like a colour wrap, but instead prefix with an icon.
  #
  def icon_prefix(commitment, text)
    if commitment.rejected?
      "<span class='keep-together' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'><img src=\"/images/reject16.png\"/> #{text}</span>"
    elsif commitment.requested?
      "<span class='keep-together' title='Awaiting approval'><img src=\"/images/request16.png\"/> #{text}</span>"
    elsif commitment.noted?
      "<span class='keep-together' title='#{h(commitment.reason)} - #{commitment.by_whom ? commitment.by_whom.name : ""}'><img src=\"/images/hold16.png\"/> #{text}</span>"
    elsif commitment.confirmed?
      "<span class='keep-together' title='Approved'><img src=\"/images/approve16.png\"/> #{text}</span>"
    else
      text
    end
  end

  def highlighted_name(commitment, show_clashes, user)
    if user && user.known?
      if commitment.instance_of?(Request)
        text = be_linken(commitment.name_with_quantity, commitment.element)
      else
        text = be_linken(commitment.element.name, commitment.element)
      end
      text = icon_prefix(commitment, text)
      if show_clashes && commitment.has_simple_clash? && user
        text = "<span class='double-booked' title='Double booked - #{commitment.text_of_clashes}'>#{text}</span>".html_safe
      end
      if commitment.covering
        if commitment.element.entity_type == "Location"
          word = "normally"
        else
          word = "covering"
        end
        text = "#{text} (#{word} <span title='#{h(commitment.covering.element.name)}'>#{be_linken(commitment.covering.element.short_name, commitment.covering.element)}</span>)"
      end
    else
      text = commitment.element.name
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
    if commitment.rejected?
      text = "#{text} #{approve_link(commitment, "Confirm")} / #{noted_link(commitment, "Noted")}"
    elsif commitment.requested?
      text = "#{text} #{approve_link(commitment, "Confirm")} / #{noted_link(commitment, "Noted")} / #{reject_link(commitment, "Raise issue")}"
    elsif commitment.noted?
      text = "#{text} #{approve_link(commitment, "Confirm")} / #{reject_link(commitment, "Raise issue")}"
    else
      text = "#{text} #{reject_link(commitment, "Raise issue")}"
    end
    #
    #  If the user doesn't get to see all forms (permissions bit) then
    #  give him a link for this specific one.
    #
    if !user_can_view_forms? && commitment.user_form_response
      text = "#{text} #{
        link_to("View form",
                user_form_response_path(commitment.user_form_response,
                                        close_after: true),
                target: :_blank)
      }"
    end
    text.html_safe
  end

  #
  #  Provide viewing links for an array of forms.
  #
  def form_viewing_links(element_connections_with_forms)
    element_connections_with_forms.collect { |ecwf| 
      link_to(ecwf.element.name,
              user_form_response_path(ecwf.user_form_response,
                                      close_after: true),
              target: :_blank)
    }.join(", ").html_safe
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
  #  A list of all the commitments which are in the approvals process,
  #  plus all the requests which exist at all.
  #
  def pending_items(event)
    event.commitments.select {|c| c.in_approvals?} + event.requests
  end

  #
  #  List all the commitments for an event which are anywhere in the
  #  approvals process - requested, approved, rejected and all the
  #  resource requests regardless of status.  Each is coloured
  #  and goes on one line on its own.
  #
  #  We expect the listing code already to have loaded all the commitments
  #  into memory, so use ordinary ruby rather than database queries to
  #  pick the ones which we want.
  #
  def approvals_table_list(event)
    pending_items(event).collect { |item|
      if item.instance_of?(Commitment)
        icon_prefix(item, h(item.element.short_name))
      else
        h(item.element.short_name)
      end
    }.join('<br/>').html_safe
  end

  #
  #  And this one must produce precisely the same number of lines as
  #  the previous one so that they line up in the display.  (Perhaps
  #  need to make sure they're the same height too?)
  #
  def forms_table_list(event)
    pending_items(event).collect { |item|
      status = item.form_status
      if status == "To fill in" ||
         status == "Complete" ||
         status == "Partial"
        #
        #  Link to edit the form.
        #
        link_to(status,
                edit_user_form_response_path(item.corresponding_form))
      elsif status == "Locked"
        #
        #  Link to display the form.
        #
        link_to(status,
                user_form_response_path(item.corresponding_form))
      else
        status
      end
    }.join('<br/>').html_safe
  end

  #
  #  Just produces a marker against each potential action.
  #
  def actions_table_list(event)
    pending_items(event).collect { |item|
      if (item.instance_of?(Commitment) && (item.rejected? || item.noted?)) ||
         item.form_status == "To fill in"
        "<" 
      else
        "&nbsp;"
      end
    }.join("<br/>").html_safe
  end

  #
  #  Generate suitable flag fields for the indicated user editing the
  #  indicated event, or a filler section if he/she doesn't deserve
  #  any.
  #
  def flags_for(f, user, event)
    can_retime = user.can_retime?(event)
    can_beshadow = user.can_beshadow?(event)
    if can_retime || can_beshadow
      fields = Array.new
      if can_retime
        fields << {
          field: :all_day_field,
          prompt: "All day",
          annotation: "The event lasts all day.  Time fields will be ignored."
        }
      end
      if can_beshadow
        fields << {
          field: :non_existent,
          prompt: "Shadow event",
          annotation: "The event doesn't really exist. It is merely a placeholder."
        }
      end
      flag_group(f, 6, 6, "Flags", fields)
    else
      "<div class='small-6 columns'></div>".html_safe
    end
  end

end
