class DaysController < ApplicationController

  #
  #  Default to all categories.
  #
  DEFAULT_CATEGORIES = []

  #
  #  We create an array of Days, based on the indicated selection criteria,
  #  then display them or allow them to be downloaded.
  #
  #  There will be options, but to prove the concept we'll first just
  #  let everything default.
  #
  def index
    #
    #  Set defaults
    #
    options = {
      do_compact:       false,
      add_duration:     false,
      mark_end:         false,
      add_locations:    false,
      add_staff:        false,
      add_pupils:       false,
      by_period:        false,
      clock_format:     :twenty_four_hour,
      no_space:         false,
      end_times:        true,
      do_breaks:        false,
      suppress_empties: false,
      show_tentative:   false,
      show_firm:        true,
      show_notes:       ""
    }
    era = Setting.next_era || Setting.current_era
    start_date   = Date.today
    end_date     = era.ends_on
    category_names = DEFAULT_CATEGORIES
    excluded_elements = Array.new
    #
    #  Have we been given a specified element?
    #
    element = nil
    item_id = params[:item_id]
    if item_id
      element = Element.find_by(id: item_id)
      unless element
        element = Element.find_by(name: item_id)
      end
      #
      #  We could go on here and try individual entities by name until
      #  we manage to find one.
      #
      #  We should perhaps change the route from elements/*/days to items/*/days
      #  to make it more logical to the user.
      #
    end
    #
    #  If nothing valid was specified, then default to the first public
    #  property.  (Used to default to element called Calendar).
    #
    unless element
      element = Property.where(make_public: true).first.element
    end
    #
    #  Check for options appended to the URL.
    #
    if params.has_key?(:compact)
      options[:do_compact] = true
    end
    if params.has_key?(:duration)
      options[:add_duration] = true
    end
    if params.has_key?(:mark_end)
      options[:mark_end] = true
    end
    if params.has_key?(:locations)
      options[:add_locations] = true
    end
    if params.has_key?(:staff)
      options[:add_staff] = true
    end
    if params.has_key?(:pupils)
      options[:add_pupils] = true
    end
    if params.has_key?(:periods)
      options[:by_period] = true
    end
    if params[:start_date]
      start_date = Date.parse(params[:start_date])
    end
    if params[:end_date]
      end_date = Date.parse(params[:end_date])
    end
    if params.has_key?(:twelve_hour)
      options[:clock_format] = :twelve_hour
    end
    if params.has_key?(:no_space)
      options[:no_space] = true
    end
    if params.has_key?(:no_end_time)
      options[:end_times] = false
    end
    if params.has_key?(:breaks)
      options[:do_breaks] = true
    end
    if params.has_key?(:suppress_empties)
      options[:suppress_empties] = true
    end
    #
    #  Must check tentative before firm, because tentative will unset
    #  firm, and then someone might want to put it back again.
    #
    if params.has_key?(:tentative)
      options[:show_tentative] = true
      options[:show_firm] = false
    end
    if params.has_key?(:firm)
      options[:show_firm] = true
    end
    if params.has_key?(:notes)
      options[:show_notes] = params[:notes]
      #
      #  Trying to show notes without each event on its own separate
      #  line is just too difficult.
      #
      options[:do_breaks] = true
    end
    if params[:categories]
      #
      #  The requester wants to limit the request to certain categories
      #  of event.  Requests for non-existent categories will result in
      #  no events.
      #
      #  You can't select categories which aren't flagged as allowing
      #  ical downloads.
      #
      category_names = params[:categories].split(",")
    end
    if params[:exclude]
      params[:exclude].split(",").each do |element_id|
        excluded_element = Element.find_by(id: element_id)
        if excluded_element
          excluded_elements << excluded_element
        end
      end
    end
    categories = category_names.collect { |cn|
      Eventcategory.find_by_name(cn)
    }.compact.select {|cc| cc.publish}
    selector = element.commitments_on(startdate: start_date,
                                      enddate: end_date,
                                      eventcategory: categories)
    if options[:show_tentative]
      unless options[:show_firm]
        selector = selector.tentative
      end
    else
      selector = selector.firm
    end
    dbevents = selector.
               preload(event: :eventcategory).
               collect {|c| c.event}.uniq
    #
    #  This next bit is potentially expensive, but won't happen unless
    #  you specify something to exclude.
    #
    excluded_elements.each do |ee|
      exclusion_selector = ee.commitments_on(startdate: start_date,
                                             enddate: end_date,
                                             eventcategory: categories)
      to_remove = exclusion_selector.collect {|c| c.event}.uniq
      dbevents -= to_remove
    end
    @days = []
    start_date.upto(end_date) do |date|
      start_of_day = Time.zone.parse(date.strftime("%Y-%m-%d"))
      end_of_day = Time.zone.parse((date + 1.day).strftime("%Y-%m-%d"))
      day = Day.new(date, options, current_user, element)
      dbevents.select {|dbe| dbe.starts_at < end_of_day &&
                             dbe.ends_at   > start_of_day}.
               select {|dbe| !options[:do_compact] ||
                             !dbe.all_day ||
                             !dbe.compactable? ||
                             dbe.starts_at == start_of_day ||
                             (options[:mark_end] && dbe.ends_at == end_of_day)}.
               sort_by {|dbe| [dbe.eventcategory.pecking_order,
                               dbe.starts_at,
                               dbe.ends_at]}.
               each do |event|
        day << event
      end
      @days << day
    end
    @element = element
    @excluded_elements = excluded_elements
    respond_to do |format|
      format.html
      format.doc
      format.csv
    end
  end

  def authorized?(action = action_name, resource = nil)
    action == 'index'
  end
end
