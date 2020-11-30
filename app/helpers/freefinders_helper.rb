module FreefindersHelper

  def ff_booking_link(
    text,
    starting_time,
    ending_time,
    eventcategory,
    element_ids)

    path_hash = {
      starts_at: starting_time,
      ends_at: ending_time,
      precommit: element_ids.collect {|eid| eid.to_s}.join(","),
      noedit: 1
    }
    if eventcategory
      path_hash[:eventcategory_id] = eventcategory.id
    end
    link_to(
      text,
      new_event_path(path_hash),
      class: 'zfbutton tiny teensy button_link ff-booking'
    )
  end

  def ff_booking_links(fsf_result, time_slot)
    #
    #  What exactly we return depends on the relative sizes of what
    #  was asked for and what we have.
    #
    results = []
    if current_user.editor? && current_user.can_add_resources?
      eventcategory = Eventcategory.cached_category("Meeting")
      starting_time = time_slot.beginning.on(fsf_result.date)
      ending_time = starting_time + fsf_result.mins_required.minutes
      results <<
        ff_booking_link(
          "Book",
          starting_time,
          ending_time,
          eventcategory,
          fsf_result.element_ids)
      if time_slot.duration > fsf_result.mins_required * 60
        #
        #  Give a slider as well.
        #
        results << " <div class='ff-slidecontainer'>"
        results << "<div class='ff-slider'></div>"
        results << "</div>"
      else
      end
    end
    results.join(" ").html_safe
  end

end
