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
      by_period:        false,
      clock_format:     :twenty_four_hour,
      end_times:        true,
      do_breaks:        false,
      suppress_empties: false
    }
    era = Setting.next_era || Setting.current_era
    start_date   = Date.today
    end_date     = era.ends_on
    category_names = DEFAULT_CATEGORIES
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
    #  If nothing valid was specified, then default to the calendar.
    #
    unless element
      element = Element.find_by(name: "Calendar")
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
    if params.has_key?(:no_end_time)
      options[:end_times] = false
    end
    if params.has_key?(:breaks)
      options[:do_breaks] = true
    end
    if params.has_key?(:suppress_empties)
      options[:suppress_empties] = true
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
    categories = category_names.collect { |cn|
      Eventcategory.find_by_name(cn)
    }.compact.select {|cc| cc.publish}
    dbevents = element.events_on(start_date,
                                 end_date,
                                 categories)
    @days = []
    start_date.upto(end_date) do |date|
      start_of_day = Time.zone.parse(date.strftime("%Y-%m-%d"))
      end_of_day = Time.zone.parse((date + 1.day).strftime("%Y-%m-%d"))
      day = Day.new(date, options)
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
