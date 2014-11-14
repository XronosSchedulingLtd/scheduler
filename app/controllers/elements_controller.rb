class ElementsController < ApplicationController

  #
  #  It would be nice to be able to use a line like the following to
  #  generate by action, but unfortunately one of my scopes needs
  #  a parameter.  Hence I have to do it manually.
  #
  #autocomplete :element, :name, :scopes => [:current, :mine_or_system], :full => true

  def autocomplete_element_name
    term = params[:term]
    elements =
      Element.current.mine_or_system(current_user).where('name LIKE ?', "%#{term}%").order(:name).all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  # GET /elements/:id/ical
  def ical
    #
    #  We expect to find the element by id, but if that doesn't work then
    #  for reverse compatibility, we'll let the staffs controller have a
    #  go at it.
    #
    got_something = false
    prefix = "notset"
    calendar_name = "notset"
    calendar_description = "notset"
    include_cover = true
    include_non_cover = true
    customer_categories = nil
    era = Setting.current_era
    #raise params.inspect
    if params.has_key?(:cover)
      #
      #  The requestor wants only cover events.
      #
      include_non_cover = false
    elsif params.has_key?(:"!cover")
      #
      #  The requestor wants to exclude cover events.
      #
      include_cover = false
    end
#    Rails.logger.debug("include_cover = #{include_cover}.  include_non_cover = #{include_non_cover}.")
    if params[:categories]
      #
      #  The requester wants to limit the request to certain categories
      #  of event.  Requests for non-existent categories will result in
      #  no events.
      #
      #  You can't select categories which aren't flagged as allowing
      #  ical downloads.
      #
      customer_category_names = params[:categories].split(",")
      customer_categories = customer_category_names.collect { |ccn|
        Eventcategory.find_by_name(ccn)
      }.compact.select {|cc| cc.publish}
      #
      #  There is a slight danger that if the requestor specifies only
      #  invalid categories then we end up with an empty list, which
      #  would result in us sending events from *all* categories.
      #  Prevent this.
      #
      if customer_categories.size == 0
        customer_categories = nil
      end
      #raise customer_categories.inspect
    end
    if params[:id] == '0'
      #
      #  Request for the breakthrough events.
      #
      categories = customer_categories || Eventcategory.publish
      dbevents = Event.events_on(era.starts_on,
                                 era.ends_on,
                                 categories)
      got_something = true
      prefix = "global"
      calendar_name = "School dates"
      calendar_description = "Abingdon school key dates"
    elsif element = Element.find_by_id(params[:id])
      #
      #  Not sure how I ended up with this name, but "publish" means it gets
      #  included in ical downloads, and "for_users" means it is relevant,
      #  even if the user is not explicitly involved.
      #
      categories = customer_categories || Eventcategory.publish
      selector = element.commitments_on(startdate:     era.starts_on,
                                        enddate:       era.ends_on,
                                        eventcategory: categories)
      if include_cover && !include_non_cover
        selector = selector.covering_commitment
      elsif include_non_cover && !include_cover
        selector = selector.non_covering_commitment
      end
      #
      #  This preload does seem to speed things up just a touch.
      #
#      dbevents =
#        selector.preload(:event).collect {|c| c.event}
      #
      #  This next one should theoretically do much better, but although
      #  it preloads all the required items, the Active Record code then
      #  seems to fetch them again from the database instead of using
      #  them as intended.  Needs further investigation.
      #
#      dbevents =
#        selector.includes(event: {commitments: {element: :entity}}).collect {|c| c.event}
      #
      #  Solved it.  I was trying to do too much work for Active Record.
      #  By explicitly loading the commitments and then the corresponding
      #  elements, I hid from AR the fact that it had now got the elements
      #  for the event.  My definition of an event includes the concept
      #  of a corresponding element (through the commitment) and that's
      #  how I subsequently access it, so that's how I need to load it.
      #
      dbevents =
        selector.includes(event: {elements: :entity}).collect {|c| c.event}
      got_something = true
      prefix = "E#{element.id}E"
      if include_non_cover
        calendar_name = element.short_name
      else
        calendar_name = "#{element.short_name}'s cover"
      end
      calendar_description = "#{element.name}'s events"
    elsif staff = Staff.find_by_initials(params[:id].upcase)
      #
      #  Fall back to old style processing.  Options are ignored.
      #
      basic_categories = Eventcategory.publish
      extra_categories = Eventcategory.publish.for_users
#      dbevents =
#        (staff.element.events_on(era.starts_on, era.ends_on, basic_categories) +
#         Event.events_on(era.starts_on, era.ends_on, extra_categories)).uniq
      dbevents =
        (staff.element.
               commitments_on(startdate: era.starts_on,
                              enddate: era.ends_on,
                              eventcategory: basic_categories).
               includes(event: {elements: :entity}).collect {|c| c.event} +
         Event.events_on(era.starts_on, era.ends_on, extra_categories).
               includes(elements: :entity)).
         uniq
      got_something = true
      prefix = staff.initials
      calendar_name = staff.initials
      calendar_description = "#{staff.name}'s timetable"
    end
    if got_something
      tf = Tempfile.new(["#{prefix}", ".ics"])
      RiCal.Calendar do |cal|
        cal.add_x_property("X-WR-CALNAME", calendar_name)
        cal.add_x_property("X-WR-CALDESC", calendar_description)
        dbevents.each do |dbevent|
          cal.event do |event|
            event.summary = dbevent.body
            if dbevent.all_day
              event.dtstart = dbevent.starts_at.to_date
              event.dtend   = dbevent.ends_at.to_date
            else
              event.dtstart = dbevent.starts_at
              event.dtend   = dbevent.ends_at
            end
            locations = dbevent.locations
            if locations.size > 0
              event.location = locations.collect {|l| l.name}.join(",")
            end
          end
        end
      end.export(tf)
      tf.close
      send_file(tf.path, :type => "application/ics")
    else
      redirect_to "/"
    end
  end

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?) ||
    action == 'ical'
  end
end
