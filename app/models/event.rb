class DurationValidator < ActiveModel::Validator
  def validate(record)
    if record.starts_at
      if record.all_day
        #
        #  Note that my date fields might contain a time, but we just ignore
        #  it.  We suppress it when providing text to edit, and we don't
        #  send it to FullCalendar at all.
        #
        if record.ends_at
          if record.ends_at < record.starts_at
            record.errors[:ends_at] << "The end date cannot be before the start date."
          end
        else
          #
          #  Don't complain - just fix it.
          #
          record.ends_at = record.starts_at
        end
      else
        if record.ends_at
          #
          #  An event with duration.
          #
          if record.ends_at < record.starts_at
            record.errors[:ends_at] << "Event has negative duration."
          end
        else
          record.ends_at = record.starts_at
        end
      end
    else
      record.errors[:starts_at] << "Every event must have a start date."
    end
  end
end

class Event < ActiveRecord::Base

  include ActiveModel::Validations

  belongs_to :eventcategory
  belongs_to :eventsource
  has_many :commitments, :dependent => :destroy
  has_many :elements, :through => :commitments

  validates :body, presence: true
  validates :eventcategory, presence: true
  validates :eventsource, presence: true
  validates :starts_at, presence: true
  validates_with DurationValidator

  #
  #  These may look slightly surprising.  We use them to specify
  #  events FROM date UNTIL date, and it seems at first sight that
  #  we're using the wrong date fields.  Think about it the other
  #  way around though - we *don't* want events that end before our
  #  start date, or start after our end date.  All others we want.
  #
  scope :beginning, lambda {|date| where("ends_at >= ?", date) }
  scope :until, lambda {|date| where("starts_at < ?", date) }
  scope :source_id, lambda {|id| where("eventsource_id = ?", id) }

  #
  #  For pagination.
  #
  self.per_page = 15

  def starts_at_text
    if all_day
      starts_at ? starts_at.strftime("%d/%m/%Y") : ""
    else
      starts_at ? starts_at.strftime("%d/%m/%Y %H:%M") : ""
    end
  end

  def ends_at_text
    if all_day
      ends_at ? ends_at.strftime("%d/%m/%Y") : ""
    else
      ends_at ? ends_at.strftime("%d/%m/%Y %H:%M") : ""
    end
  end

  def starts_at_for_fc
    if all_day
      starts_at.to_date.rfc822
    else
      starts_at.rfc822
    end
  end

  def ends_at_for_fc
    if all_day
      if ends_at
        (ends_at.to_date + 1.day).rfc822
      else
        (starts_at.to_date + 1.day).rfc822
      end
    else
      if ends_at == nil || starts_at == ends_at
        nil
      else
        ends_at.rfc822
      end
    end
  end

  def set_timing(new_start, new_all_day)
    current_duration = ends_at - starts_at
    new_starts_at = Time.zone.parse(new_start)
    if all_day
      if new_all_day
        #
        #  Remaining an all_day event.  Just change the start time and
        #  leave the duration alone.
        #
        self.starts_at = new_starts_at.to_date
        self.ends_at   = starts_at + current_duration
      else
        #
        #  Was an all_day event, but becoming a timed event.  Since there
        #  is no way of indicating the required duration with a single
        #  drag, we start with a nil duration.  The user can change this
        #  with another drag if required.
        #
        self.starts_at = new_starts_at
        self.ends_at   = new_starts_at
        self.all_day   = false
      end
    else
      if new_all_day
        #
        #  Moving from being a timed event to being an all_day event.
        #  Assume a duration of 1 day for now.
        #
        self.starts_at = new_starts_at.to_date
        self.ends_at   = self.starts_at
        self.all_day   = true
      else
        #
        #  Remaining a timed event.
        #
        self.starts_at = new_starts_at
        self.ends_at   = starts_at + current_duration
      end
    end
  end

  #
  #  Only a tiny bit different from writing directly to ends_at, but
  #  as the data are coming from FC, we need to take account of all day
  #  events.
  #
  def new_end=(new_value)
    new_ends_at = Time.zone.parse(new_value)
    if all_day
      self.ends_at = new_ends_at - 1.day
    else
      self.ends_at = new_ends_at
    end
  end

  #
  #  Can the current user edit this event?
  #
  def can_edit?
    #
    #  This algorithm needs to be made slightly more sophisticated.
    #
    if starts_at.hour < 12
      true
    else
      false
    end
  end

  #
  #  What resources are involved in this event?
  #
  def resources
    self.elements.collect {|e| e.entity}
  end

  # Returns an array of events for the indicated category, resource
  # and dates.
  # If no date is given, return today's events.
  # The dates passed in are *inclusive* so we need to adjust slightly.
  #
  #  This method is intended to be the core one which does all the
  #  work.  Similarly named methods in other models should call this
  #  one rather than re-implementing the same functionality.
  #
  #  eventcategories and resources can be passed either as a string,
  #  naming the item, or as the item itself.  Passing anything else
  #  will cause an empty array to be returned - because we can't find
  #  any events matching the specified criteria.  Likewise, passing
  #  a name which doesn't match an existing eventcategory or resource
  #  will result in an empty array.
  #
  #  For the resource you can also pass any object which is a type of
  #  resource.
  #
  def self.events_on(startdate     = nil,
                     enddate       = nil,
                     eventcategory = nil,
                     eventsource   = nil,
                     resource      = nil,
                     include_nonexistent = false)
    duffparameter = false
    #
    #  Might be passed startdate and enddate as:
    #
    #    A Date
    #    A String
    #    A Time
    #    A TimeWithZone
    #
    #  Fortunately, all of these provide a to_date action.
    #
    startdate = startdate ? startdate.to_date   : Date.today
    dateafter = enddate   ? enddate.to_date + 1 : startdate + 1
    ec = nil
    if eventcategory
      if eventcategory.instance_of?(String)
        ec = Eventcategory.find_by_name(eventcategory)
      elsif eventcategory.instance_of?(Eventcategory)
        ec = eventcategory
      end
      duffparameter = true unless ec
    end
    es = nil
    if eventsource
      if eventsource.instance_of?(String)
        es = Eventsource.find_by_name(eventsource)
      elsif eventsource.instance_of?(Eventsource)
        es = eventsource
      end
      duffparameter = true unless es
    end
    res = nil
    if resource
      if resource.instance_of?(String)
        res = Element.find_by_name(resource)
      elsif resource.instance_of?(Element)
        res = resource
      elsif resource.respond_to?(:element) &&
            resource.element.instance_of?(Element)
        res = resource.element
      end
      duffparameter = true unless res
    end
    if duffparameter
      []
    else
      query_hash = {}
      query_string_parts = []
      #
      #  We have to specify a start and end date.  The way the dates are
      #  used here may look a trifle odd, but think about it the other
      #  way around.  We *don't* want events which end before the beginning
      #  of our date range, or those which start after the end of our
      #  date range.  The selection for events to exclude would therefore
      #  be:
      #
      #    If starts_at >= dateafter || ends_at < startdate
      #
      #  and if you negate that then by De Morgan's law you get:
      #
      #    If starts_at < dateafter && ends_at >= startdate
      #
      query_string_parts << "starts_at < :dateafter"
      query_hash[:dateafter] = Time.zone.parse("00:00:00", dateafter)
      query_string_parts << "ends_at >= :startdate"
      query_hash[:startdate] = Time.zone.parse("00:00:00", startdate)
      if ec
        query_string_parts << "eventcategory_id = :eventcategory_id"
        query_hash[:eventcategory_id] = ec.id
      end
      if es
        query_string_parts << "eventsource_id = :eventsource_id"
        query_hash[:eventsource_id] = es.id
      end
      if res
        query_string_parts << "commitments.element_id = :element_id"
        query_hash[:element_id] = res.id
      end
      unless include_nonexistent
        query_string_parts << "not non_existent"
      end
      #
      #  And now for the actual database hit.  Do we need a join?
      #
      if res
        eventer = Event.joins(:commitments)
      else
        eventer = Event
      end
      eventer.where(query_string_parts.join(" and "), query_hash)
    end
  end

  def as_json(options = {})
    {
      :id        => "#{id}",
      :title     => body,
      :start     => starts_at_for_fc,
      :end       => ends_at_for_fc,
      :allDay    => all_day,
      :recurring => false,
      :editable  => can_edit?
    }
  end

  #
  #  This is a method to assist with the display of events which span more
  #  than two days, but which aren't flagged as being all_day.  That is,
  #  they might start at 09:00 on Monday and end at 15:00 on Friday.  Arguably
  #  such events have probably been entered into the calendar wrongly, and
  #  would be better entered as a recurring event, rather than as one long
  #  one, but they still display rather strangely.  By default, FullCalendar
  #  shows them as a continuous stripe, running through all the intermediate
  #  days and cluttering up the display.  I feel they would better shown
  #  with their actual start and finish times on the first and last days,
  #  but as if they were all_day events on all the intermediate days.
  #
  #  Note that this method will create 3 new events for each such event,
  #  but they don't get saved to the database.  They thus don't need to
  #  pass validation.
  #
  def self.split_multi_day_events(events)
    output_events = []
    events.each do |event|
      if event.all_day ||
         event.starts_at.to_date + 2.days > event.ends_at.to_date
        output_events << event
      else
        #
        #  An event to break up a bit.
        #
        part1 = Event.new
        part1.starts_at = event.starts_at
        part1.ends_at   = event.starts_at.to_date + 1.day
        part1.all_day   = false
        part1.body      = event.body
        output_events << part1
        part2 = Event.new
        part2.starts_at = event.starts_at.to_date + 1.day
        part2.ends_at   = event.ends_at.to_date - 1.day
        part2.all_day   = true
        part2.body      = event.body
        output_events << part2
        part3 = Event.new
        part3.starts_at = event.ends_at.to_date
        part3.ends_at   = event.ends_at
        part3.all_day   = false
        part3.body      = event.body
        output_events << part3
      end
    end
    output_events
  end
end
