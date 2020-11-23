module FreefindersHelper

  def ff_booking_link(text, starting_time, ending_time, element_ids)
    link_to(
      text,
      new_event_path(
        starts_at: starting_time,
        ends_at: ending_time,
        precommit: element_ids.collect {|eid| eid.to_s}.join(",")
      ),
      class: 'zfbutton tiny teensy button_link ff-booking'
    )
  end

  def ff_booking_links(fsf_result, time_slot)
    #
    #  What exactly we return depends on the relative sizes of what
    #  was asked for and what we have.
    #
    results = []
    if time_slot.duration > fsf_result.mins_required * 60
      starting_time = time_slot.beginning.on(fsf_result.date)
      ending_time = starting_time + fsf_result.mins_required.minutes
      results << ff_booking_link("First #{fsf_result.mins_required}",
                                 starting_time,
                                 ending_time,
                                 fsf_result.element_ids)

      ending_time = time_slot.ending.on(fsf_result.date)
      results << ff_booking_link('Book all',
                                 starting_time,
                                 ending_time,
                                 fsf_result.element_ids)

      starting_time = ending_time - fsf_result.mins_required.minutes

      results << ff_booking_link("Last #{fsf_result.mins_required}",
                                 starting_time,
                                 ending_time,
                                 fsf_result.element_ids)

    else
      starting_time = time_slot.beginning.on(fsf_result.date)
      ending_time = time_slot.ending.on(fsf_result.date)
      results << ff_booking_link('Book',
                                 starting_time,
                                 ending_time,
                                 fsf_result.element_ids)
    end
    results.join(" ").html_safe
  end

end
