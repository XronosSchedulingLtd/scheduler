require 'csv'
require 'membershipwithduration'

class ElementsController < ApplicationController

  #
  #  It would be nice to be able to use a line like the following to
  #  generate by action, but unfortunately one of my scopes needs
  #  a parameter.  Hence I have to do it manually.
  #
  #autocomplete :element, :name, :scopes => [:current, :mine_or_system], :full => true

  def autocomplete_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order("LENGTH(elements.name)").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def show
    @element = Element.find(params[:id])
    @memberships =
      Membership::MembershipWithDuration.group_by_duration(
        @element.memberships_by_duration(start_date: nil,
                                         end_date: nil))
  end

  def autocomplete_staff_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              staff.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  # GET /elements/:id/ical
  def ical
    #
    #  We expect to find the element by id, but if that doesn't work then
    #  for reverse compatibility, we'll let emulate what the staffs
    #  controller used to do.
    #
    got_something = false
    prefix = "notset"
    calendar_name = "notset"
    calendar_description = "notset"
    include_cover = true
    include_non_cover = true
    customer_categories = nil
    remove_categories = []
    era = Setting.previous_era || Setting.current_era
    starts_on = era.starts_on
    ends_on = :never
    element_id = params[:id]
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
    if params[:start_date]
      starts_on = Date.parse(params[:start_date])
    end
    if params[:end_date]
      ends_on = Date.parse(params[:end_date])
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
      remove_category_names, customer_category_names =
        params[:categories].split(",").partition{|n| n[0] == "!"}
      #
      #  Calendar events used to be specified by event category,
      #  but now it's a property.  Provide a touch of reverse
      #  compatibility.
      #
      if (element_id == '0') && customer_category_names.include?("Calendar")
        calendar_element = Element.find_by(name: "Calendar")
        if calendar_element
          element_id = calendar_element.id.to_s
        end
      else
        customer_categories = customer_category_names.collect { |ccn|
          Eventcategory.find_by_name(ccn)
        }.compact.select {|cc| cc.publish}
        remove_categories = remove_category_names.collect { |rcn|
          Eventcategory.find_by_name(rcn[1..-1])
        }.compact
        #
        #  There is a slight danger that if the requestor specifies only
        #  invalid categories then we end up with an empty list, which
        #  would result in us sending events from *all* categories.
        #  Prevent this.
        #
        if customer_categories.size == 0
          customer_categories = nil
        end
      end
      #raise customer_categories.inspect
    end
    if element_id == '0'
      #
      #  Request for the breakthrough events.
      #
      categories =
        (customer_categories || Eventcategory.publish.schoolwide) - remove_categories
      if categories.empty?
        categories = Eventcategory.publish.schoolwide
      end
      dbevents = Event.events_on(starts_on,
                                 ends_on,
                                 categories)
      got_something = true
      prefix = "global"
      calendar_name = "School dates"
      calendar_description = "Abingdon school key dates"
    elsif element = Element.find_by_id(element_id)
      categories =
        (customer_categories || Eventcategory.publish) - remove_categories
      if categories.empty?
        categories = Eventcategory.publish
      end
      selector =
        element.commitments_on(startdate:      starts_on,
                               enddate:        ends_on,
                               eventcategory:  categories,
                               effective_date: Setting.current_era.starts_on)
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
      extra_categories = Eventcategory.publish.schoolwide
#      dbevents =
#        (staff.element.events_on(starts_on, ends_on, basic_categories) +
#         Event.events_on(starts_on, ends_on, extra_categories)).uniq
      dbevents =
        (staff.element.
               commitments_on(startdate: starts_on,
                              enddate: ends_on,
                              eventcategory: basic_categories,
                              effective_date: Setting.current_era.starts_on).
               includes(event: {elements: :entity}).collect {|c| c.event} +
         Event.events_on(starts_on, ends_on, extra_categories).
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
              event.location = locations.collect {|l| l.friendly_name}.join(",")
            end
            event.uid = "e#{dbevent.id}@#{Setting.hostname}"
            event.dtstamp = dbevent.created_at
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
