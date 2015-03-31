class DaysController < ApplicationController

  DEFAULT_CATEGORIES = ["Week letter", "Key date (external)", "Calendar"]

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
    do_compact    = false
    add_duration  = false
    mark_end      = false
    add_locations = false
    clock_format  = :twenty_four_hour
    end_times     = true
    era = Setting.current_era
    start_date   = Date.today
    end_date     = era.ends_on
    category_names = DEFAULT_CATEGORIES
    #
    #  Check for options appended to the URL.
    #
    if params.has_key?(:compact)
      do_compact = true
    end
    if params.has_key?(:duration)
      add_duration = true
    end
    if params.has_key?(:mark_end)
      mark_end = true
    end
    if params.has_key?(:locations)
      add_locations = true
    end
    if params[:start_date]
      start_date = Date.parse(params[:start_date])
    end
    if params[:end_date]
      end_date = Date.parse(params[:end_date])
    end
    if params.has_key?(:twelve_hour)
      clock_format = :twelve_hour
    end
    if params.has_key?(:no_end_time)
      end_times = false
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
    #
    #  There is a slight danger that if the requestor specifies only
    #  invalid categories then we end up with an empty list, which
    #  would result in us sending events from *all* categories.
    #  Prevent this.
    #
    if categories.size == 0
      categories = DEFAULT_CATEGORIES.collect { |cn|
        Eventcategory.find_by_name(cn)
      }.compact.select {|cc| cc.publish}
    end
    #
    #  Want to be able to sort selected events into the order in which
    #  the categories were specified.
    #
    sort_hash = Hash.new
    categories.each_with_index do |category, index|
      sort_hash[category.id] = index
    end
    dbevents = Event.events_on(start_date,
                               end_date,
                               categories)
    @days = []
    start_date.upto(end_date) do |date|
      start_of_day = Time.zone.parse(date.strftime("%Y-%m-%d"))
      end_of_day = Time.zone.parse((date + 1.day).strftime("%Y-%m-%d"))
      day = Day.new(date,
                    add_duration,
                    mark_end,
                    add_locations,
                    clock_format,
                    end_times)
      dbevents.select {|dbe| dbe.starts_at < end_of_day &&
                             dbe.ends_at   > start_of_day}.
               select {|dbe| !do_compact ||
                             !dbe.all_day ||
                             !dbe.compactable? ||
                             dbe.starts_at == start_of_day ||
                             (mark_end && dbe.ends_at == end_of_day)}.
               sort_by {|dbe| [sort_hash[dbe.eventcategory_id],
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
