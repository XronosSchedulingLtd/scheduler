# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

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

  belongs_to :owner, :class_name => :User

  belongs_to :organiser, :class_name => :Element

  validates :body, presence: true
  validates :eventcategory, presence: true
  validates :eventsource, presence: true
  validates :starts_at, presence: true
  validates_with DurationValidator

  @@duty_category         = nil
  @@invigilation_category = nil
  @@lesson_category       = nil
  @@weekletter_category   = nil

  #
  #  These may look slightly surprising.  We use them to specify
  #  events FROM date UNTIL date, and it seems at first sight that
  #  we're using the wrong date fields.  Think about it the other
  #  way around though - we *don't* want events that end before our
  #  start date, or start after our end date.  All others we want.
  #
  scope :beginning, lambda {|date| where("ends_at >= ?", date) }
  scope :until, lambda {|date| where("starts_at < ?", date) }
  scope :eventcategory_id, lambda {|id| where("eventcategory_id = ?", id) }
  scope :eventsource_id, lambda {|id| where("eventsource_id = ?", id) }
  scope :on, lambda {|date| where("starts_at >= ? and ends_at < ?",
                                  date, date + 1.day)}
  scope :source_id, lambda {|id| where("source_id = ?", id) }
  scope :source_hash, lambda {|id| where("source_hash = ?", id) }
  scope :atomic, lambda { where("compound = false") }
  scope :compound, lambda { where("compound = true") }
  scope :all_day, lambda { where("all_day = true") }

  #
  #  For pagination.
  #
  self.per_page = 15

  def all_day_field
    self.all_day
  end

  def all_day_field=(value)
    org_value = self.all_day
#    puts "org_value.class = #{org_value.class}"
#    puts "all_day_field receiving #{value} (#{value.class})"
    self.all_day = value
    new_value = self.all_day
#    puts "new_value.class = #{new_value.class}"
    if org_value && !new_value
      become_timed
    elsif new_value && !org_value
      become_all_day
    end
  end

  def starts_at_text
    if all_day
      starts_at ? starts_at.strftime("%d/%m/%Y") : ""
    else
      starts_at ? starts_at.strftime("%d/%m/%Y %H:%M") : ""
    end
  end

  def starts_at_text=(value)
    self.starts_at = value
  end

  def ends_at_text
    if all_day
      ends_at ? (ends_at.to_date - 1.day).strftime("%d/%m/%Y") : ""
    else
      ends_at ? ends_at.strftime("%d/%m/%Y %H:%M") : ""
    end
  end

  def ends_at_text=(value)
#    Rails.logger.debug("Setting ends_at to #{value}")
    self.ends_at = value
    #
    #  May need this again later.
    #
    @ends_at_text_value = value
    if all_day
      #
      #  People expect to give the day on which the event ends, but we
      #  want to store the time at which it ends, which is 00:00:00 on
      #  the following day.
      #
      self.ends_at = self.ends_at.to_date + 1.day
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
        ends_at.to_date.rfc822
      else
        starts_at.to_date.rfc822
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
    current_days = ends_at.to_date - starts_at.to_date
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
        #  A minimum duration of 1 day, but if the event previously straddled
        #  more than one day, then keep them all in.
        #
        #  Problem with the above - FC seems to assume that the event
        #  will be just one day, and doesn't re-request the data to find
        #  out.  I could force an event reload, but it seems simpler
        #  just to go with FC's idea.  It's an easy additional drag to
        #  change the duration.
        #
        #Rails.logger.debug "current duration #{current_duration} (#{current_duration.class})"
        #Rails.logger.debug "current days #{current_days} (#{current_days.class})"
        self.starts_at = new_starts_at.to_date
        #self.ends_at   = self.starts_at + (current_days.to_i + 1).days
        self.ends_at   = self.starts_at + 1.day
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
  #  Actually, now no different from writing to ends_at
  #
  def new_end=(new_value)
    self.ends_at = Time.zone.parse(new_value)
  end

  #
  #  What resources are directly involved in this event?
  #
  def resources
    self.elements.collect {|e| e.entity}
  end

  def all_atomic_resources
    found = Array.new
    self.elements.each do |e|
      if e.entity.instance_of?(Group)
        found += e.entity.members(self.starts_at.to_date,
                                  true,
                                  true)
      else
        found << e.entity
      end
    end
    found.uniq
  end

  #
  #  These need enhancing to take account of the fact that particular
  #  types of resource might be involved in an event by dint of being
  #  members of a group.  Pupils especially, but it could apply to anything.
  #
  #  Enhancement now done.
  #
  def locations(and_by_group = false)
    if and_by_group
      self.all_atomic_resources.select {|r| r.instance_of?(Location)}
    else
      self.resources.select {|r| r.instance_of?(Location)}
    end
  end

  def pupils(and_by_group = false)
    if and_by_group
      self.all_atomic_resources.select {|r| r.instance_of?(Pupil)}
    else
      self.resources.select {|r| r.instance_of?(Pupil)}
    end
  end

  def staff(and_by_group = false)
    if and_by_group
      self.all_atomic_resources.select {|r| r.instance_of?(Staff)}
    else
      self.resources.select {|r| r.instance_of?(Staff)}
    end
  end

  def groups
    self.resources.select {|r| r.instance_of?(Group)}
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
  #  Most events have an owner_id of nil, however passing an owned_by
  #  value of nil here does not restrict us to just those events.  If
  #  we specify an explicit owner then the search is restricted to just
  #  the events of that owner, but if we specify no owner (owned_by = nil)
  #  then we want *all* events, regardless of ownership.
  #
  def self.events_on(startdate     = nil,
                     enddate       = nil,
                     eventcategory = nil,
                     eventsource   = nil,
                     resource      = nil,
                     owned_by      = nil,
                     include_nonexistent = false)
    # Rails.logger.debug("Entering Event#events_on")
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
    ecs = []
    if eventcategory
      #
      #  We allow a single eventcategory, or an array.
      #  (Or something that behaves like an array.)
      #
      if eventcategory.respond_to?(:each)
        eca = eventcategory
      else
        eca = [eventcategory]
      end
      eca.each do |ec|
        if ec.instance_of?(String)
          ec = Eventcategory.find_by_name(ec)
        end
        if ec.instance_of?(Eventcategory)
          ecs << ec
        else
          duffparameter = true
        end
      end
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
    if owned_by
      duffparameter = true unless owned_by.instance_of?(User)
    end
    if duffparameter
      # Rails.logger.debug("Event#events_on hit a duff parameter.")
      Event.none
    else
      # Rails.logger.debug("Assembling the d/b query.")
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
      #    If starts_at >= dateafter || ends_at <= startdate
      #
      #  and if you negate that then by De Morgan's law you get:
      #
      #    If starts_at < dateafter && ends_at > startdate
      #
      query_string_parts << "starts_at < :dateafter"
      query_hash[:dateafter] = Time.zone.parse("00:00:00", dateafter)
      query_string_parts << "ends_at > :startdate"
      query_hash[:startdate] = Time.zone.parse("00:00:00", startdate)
      if ecs.size > 0
        if ecs.size == 1
          query_string_parts << "eventcategory_id = :eventcategory_id"
          query_hash[:eventcategory_id] = ecs[0].id
        else
          #
          #  Aiming for "(event_category_id = :eci1 OR event_category_id = :ec2)"
          #
          query_string_parts << "(#{
            ecs.collect {|ec|
              "eventcategory_id = :ec#{ec.id}"
            }.join(" or ")
          })"
          ecs.each do |ec|
            query_hash[:"ec#{ec.id}"] = ec.id
          end
        end
      end
      if es
        query_string_parts << "eventsource_id = :eventsource_id"
        query_hash[:eventsource_id] = es.id
      end
      if res
        query_string_parts << "commitments.element_id = :element_id"
        query_hash[:element_id] = res.id
      end
      if owned_by
        query_string_parts << "owner_id = :owner_id"
        query_hash[:owner_id] = owned_by.id
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
      # Rails.logger.debug("Executing the query")
      eventer.where(query_string_parts.join(" and "), query_hash)
    end
  end

  def colour
    if eventcategory.id == Event.lesson_category.id
      "#225599"
    elsif eventcategory.id == Event.invigilation_category.id
      "red"
    elsif eventcategory.id == Event.weekletter_category.id
      "pink"
    else
      "green"
    end
  end

  # Is the indicated resource providing cover for this event?
  def covered_by?(item)
    if item.instance_of?(Element)
      resource = item
    else
      resource = item.element
    end
    result = false
    self.commitments.each do |commitment|
      if commitment.element_id == resource.id &&
         commitment.covering
        result = true
      end
    end
    result
  end

  def involves?(item)
    if item.instance_of?(Element)
      resource = item
    else
      resource = item.element
    end
    !!self.commitments.detect {|c| c.element == resource}
  end

  #
  #  Produce a string for the event's duration.  With just a start time we
  #  get:
  #
  #    "10:00"
  #
  #  and with an end time as well we would get:
  #
  #    "10:00-11:00"
  #
  def duration_string(clock_format = :twenty_four_hour,
                      end_time     = :true)
    if clock_format == :twenty_four_hour
      format_string = "%H:%M"
    else
      format_string = "%-l:%M %P"
    end
    if (starts_at == ends_at) || !end_time
      starts_at.strftime(format_string)
    else
      "#{starts_at.strftime(format_string)}-#{ends_at.strftime(format_string)}"
    end
  end

  #
  #  Some of the body texts are being entered with trailing spaces, or
  #  with or without full stops, and even in some cases ending in " . "
  #  Clean it up.
  #
  def tidied_body(with_dot = false)
    "#{self.body.chomp(" ").chomp(".").chomp(" ")}#{with_dot ? "." : ""}"
  end

  def short_end_date_str
    if self.all_day
      ends_at = self.ends_at - 1.day
    else
      ends_at = self.ends_at
    end
    ends_at.strftime("#{ends_at.day.ordinalize} %B")
  end

#  def to_csv(add_duration = false, date = nil)
#    if self.all_day
#      ["", 
#       (add_duration &&
#        (self.ends_at > self.starts_at + 1.day) &&
#        (self.ends_at > date + 1.day)) ?
#       "#{self.tidied_body} (to #{self.short_end_date_str})" :
#       self.tidied_body,
#       self.locations.collect {|l| l.name}.join(",")].to_csv
#    else
#      [" #{self.duration_string}",
#       self.tidied_body,
#       self.locations.collect {|l| l.name}.join(",")].to_csv
#    end
#  end

  #
  #  Default to sorting events by time.  If two events start at precisely
  #  the same time, then the shorter is shown first.
  #
  def <=>(other)
    if self.starts_at == other.starts_at
      self.ends_at <=> other.ends_at
    else
      self.starts_at <=> other.starts_at
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
      :editable  => can_edit?,
      :color     => colour
    }
  end

  #
  #  I would naturally call this method "clone" but that name is already
  #  taken and has a well-defined meaning.  I don't want to risk unintended
  #  side effects by overriding it.
  #
  #  Note that because we want to add commitments to this event during
  #  the cloning process, we have to save it to the database.
  #
  def clone_and_save(modifiers)
    new_self = self.dup
    #
    #  Any modifiers to apply?
    #
    modifiers.each do |key, value|
      new_self.send("#{key}=", value)
    end
    new_self.save!
    #
    #  Commitments don't get copied by dup.
    #
    self.commitments.each do |commitment|
      #
      #  And we don't want to clone cover commitments.
      #
      unless commitment.covering
        commitment.clone_and_save(event: new_self)
      end
    end
    new_self
  end

  def compactable?
    self.eventcategory.compactable
  end

  def self.duty_category
    @@duty_category ||= Eventcategory.find_by_name("Duty")
  end

  def self.invigilation_category
    @@invigilation_category ||= Eventcategory.find_by_name("Invigilation")
  end

  def self.lesson_category
    @@lesson_category ||= Eventcategory.find_by_name("Lesson")
  end

  def self.weekletter_category
    @@weekletter_category ||= Eventcategory.find_by_name("Week letter")
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

  #
  #  Adjust all existing all day events to follow the new convention of
  #  ending at 00:00:00 on the *next* day - the first day after the event.
  #
  def self.adjust_all_day_events
    count = 0
    Event.all_day.each do |e|
      e.ends_at = e.ends_at.to_date + 1.day
      e.save!
      count += 1
    end
    puts "Adjusted #{count} all day events."
    nil
  end

  private

  def become_all_day
#    Rails.logger.debug("Becoming all_day.")
    #
    #  Was a timed event - now an all day event.  Set the start time
    #  to be midnight at the start of the day containing the start time.
    #  Set the end time to be midnight at the end of the day containing
    #  the end time.
    #
    self.starts_at = self.starts_at.to_date
    self.ends_at = self.ends_at.to_date + 1.day
  end

  def become_timed
#    Rails.logger.debug("Becoming timed, with starts_at = #{self.starts_at} and ends_at = #{self.ends_at}.")
    #
    #  Was an all day event, but now am not.  If the start time
    #  is midnight, then set it to be 08:00 so the event doesn't
    #  disappear from the calendar.  If the user has selected a new
    #  start time as well, then respect it.
    #
    #  If the end time is midnight 24 hours later, set it to be the
    #  same as the start time.  If it is more than 24 hours later, but
    #  a multiple of 24 hours, then set it to be 08:00 on the erstwhile
    #  last day of the event.
    #
    if @ends_at_text_value
      #
      #  We have earlier adjusted our ends_at value on the basis that this
      #  is an all day event.  Undo that adjustment, because we now know
      #  it isn't.
      #
      self.ends_at = @ends_at_text_value
      #
      #  Adjust this as if we were still un-timed.
      #
      if self.ends_at.to_date == self.ends_at
        self.ends_at = self.ends_at + 1.day
      end
    end
    if self.starts_at == self.starts_at.to_date
      if self.ends_at == self.starts_at.to_date + 1.day
        self.ends_at = self.starts_at + 8.hours
      elsif self.ends_at == self.ends_at.to_date
        self.ends_at = self.ends_at - 16.hours
      end
      self.starts_at = self.starts_at + 8.hours
    elsif self.ends_at == self.ends_at.to_date
      #
      #  User seems to have specified a new start time, but left the
      #  end time as just a date.  If it's the end of the same day as the
      #  start time, then adjust it to be the same as the start time.
      #
      if self.ends_at == self.starts_at.to_date + 1.day
        self.ends_at = self.starts_at
      end
    end
#    Rails.logger.debug("Now timed, with starts_at = #{self.starts_at} and ends_at = #{self.ends_at}.")
  end

end
