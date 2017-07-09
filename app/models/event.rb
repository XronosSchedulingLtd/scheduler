# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
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
          elsif record.ends_at.to_date == record.starts_at.to_date
            #
            #  This should have been prevented earlier, but fix anyway.
            #
            record.ends_at = record.starts_at.to_date + 1.day
          end
        else
          #
          #  Don't complain - just fix it.
          #
          record.ends_at = record.starts_at.to_date + 1.day
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

class CategoryValidator < ActiveModel::Validator
  def validate(record)
    #
    #  We don't fuss about there being no event category - that's taken
    #  care of elsewhere - but we do need to make sure it's still a
    #  permitted one.
    #
    if record.eventcategory
      if record.eventcategory.deprecated
        record.errors[:eventcategory_id] << "#{record.eventcategory.name} is deprecated."
      end
    end
  end
end

class CommitmentSet < Array
  attr_reader :commitment_type

  def initialize(commitment_type)
    @commitment_type = commitment_type
  end

  def element_names
    self.collect {|c| c.element.name}
  end

  def label_text
    #
    #  Early on I failed to set up a special case, so my app thinks
    #  that the plural of Staff is Staffs.  I can't now change this
    #  without renaming database tables etc, so I need to special
    #  case it here.
    #
    if self.size == 1 || self.commitment_type == "Staff"
      self.commitment_type
    else
      self.commitment_type.pluralize
    end
  end
end

class Event < ActiveRecord::Base

  include ActiveModel::Validations

  belongs_to :eventcategory
  belongs_to :eventsource
  has_many :commitments, :dependent => :destroy
  has_many :requests, :dependent => :destroy
  has_many :firm_commitments, -> { where.not(tentative: true) }, class_name: "Commitment"
  has_many :tentative_commitments, -> { where(tentative: true) }, class_name: "Commitment"
  has_many :elements, :through => :firm_commitments
  #
  #  This next one took a bit of crafting.  It is used to optimize
  #  fetching the directly associated staff elements on events when
  #  it is desired to list staff too in the main display.
  #
  #  Note that to get the benefit, you need to make sure your pre-load
  #  and subsequent access to the items match.  If you pre-load with
  #  this, but access them through event.elements (above) you don't
  #  get any benefit.
  #
  has_many :staff_elements, -> { where(elements: {entity_type: "Staff"}) }, class_name: "Element", :source => :element, :through => :firm_commitments
  has_many :notes, as: :parent, :dependent => :destroy
  has_many :attachments, as: :parent, :dependent => :destroy

  belongs_to :owner, :class_name => :User

  belongs_to :organiser, :class_name => :Element

  belongs_to :proto_event

  validates :body, presence: true
  validates :eventcategory, presence: true
  validates :eventsource, presence: true
  validates :starts_at, presence: true
  validates_with DurationValidator
  #
  #  It's too confusing for users to be forced to change the category
  #  before they can do any other edits.  We still won't offer them
  #  deprecated categories, but for now they can still update events
  #  which have them.
  #
#  validates_with CategoryValidator

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
  #
  #  And these are for specifying events which are over before a given
  #  date, or start after a given date.
  #
  scope :before, lambda {|date| where("ends_at < ?", date) }
  scope :after, lambda {|date| where("starts_at > ?", date + 1.day) }
  scope :eventcategory_id, lambda {|id| where("eventcategory_id = ?", id) }
  scope :eventsource_id, lambda {|id| where("eventsource_id = ?", id) }
  scope :on, lambda {|date| where("starts_at >= ? and ends_at < ?",
                                  date, date + 1.day)}
  scope :source_id, lambda {|id| where("source_id = ?", id) }
  scope :source_hash, lambda {|id| where("source_hash = ?", id) }
  scope :atomic, lambda { where("compound = false") }
  scope :compound, lambda { where("compound = true") }
  scope :all_day, lambda { where("all_day = true") }
  scope :involving, lambda {|element| joins(:commitments).where("commitments.element_id = ?", element.id)}
  #
  #  On this next one, note the "distinct" modifier at the end.  This
  #  ensures that if an event involves more than one of the indicated
  #  elements then it will be returned only once.
  #
  #  If you really want it to be returned N times, then tag ".distinct(false)"
  #  on the end, which incredibly will undo the above modifier.
  #
  scope :involving_one_of, lambda {|elements| joins(:commitments).where(commitments: { element_id: elements.collect {|e| e.id}}).distinct}
  scope :excluding_category, lambda {|ec| where("eventcategory_id != ?", ec.id) }
  scope :complete, lambda { where(complete: true) }
  scope :incomplete, lambda { where.not(complete: true) }
  scope :has_clashes, lambda { where(has_clashes: true) }

  before_destroy :being_destroyed

  #
  #  We are being asked to check whether we are complete or not.  The
  #  hint indicates whether or not the calling commitment is tentative.
  #  If it is tentative, then we can't be complete.  If it's not
  #  tentative, then we might be complete.
  #
  def update_from_commitments(commitment_tentative, commitment_constraining)
    unless @being_destroyed || self.destroyed?
      do_save = false
      if commitment_tentative
        if self.complete
          self.complete = false
          do_save = true
        end
      else
        unless self.complete
          #
          #  It's possible our last remaining tentative commitment either
          #  went away or became non-tentative.
          #  This is the most expensive case to check.
          #
          if self.commitments.tentative.count == 0
            self.complete = true
            do_save = true
          end
        end
      end
      if commitment_constraining
        unless self.constrained
          self.constrained = true
          do_save = true
        end
      else
        if self.constrained
          if self.commitments.constraining.count == 0
            self.constrained = false
            do_save = true
          end
        end
      end
      if do_save
        self.save!
      end
    end
  end

  #
  #  Colour parameter can be "r", "y" or "g".  We're looking for
  #  the worst of these from all our requests.
  #
  #  "r" trumps "y" trumps "g" trumps blank.
  #
  def update_from_request(colour)
    #
    #  Not full functionality yet.
    #
    if self.flagcolour != colour
      self.flagcolour = colour
      self.save!
    end
  end

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

  def precommit_element_id
    @precommit_element_id
  end

  def precommit_element_id=(value)
    @precommit_element_id = value
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

  def start_date_text
    self.starts_at.strftime("%a #{self.starts_at.day.ordinalize} %b")
  end

  def jump_date_text
    self.starts_at.to_date.strftime("%Y-%m-%d")
  end

  #
  #  Returns the last date of this event.  Processing differs depending
  #  on whether or not this is an all-day event.
  #
  def end_date
    if self.all_day
      self.ends_at.to_date - 1.day
    else
      self.ends_at.to_date
    end
  end

  def ends_at_text
    if all_day
      ends_at ? (ends_at.to_date - 1.day).strftime("%d/%m/%Y") : ""
    else
      ends_at ? ends_at.strftime("%d/%m/%Y %H:%M") : ""
    end
  end

  def ends_at_text=(value)
    Rails.logger.debug("Setting ends_at to #{value}")
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

  def created_at_text
    self.created_at ? self.created_at.strftime("%d/%m/%Y %H:%M") : ""
  end

  def updated_at_text
    self.updated_at ? self.updated_at.strftime("%d/%m/%Y %H:%M") : ""
  end

  #
  #  For a timed event, ends when it starts.
  #  For an all day event, lasts just the one day.
  #
  def minimal_duration?
    if self.all_day
      self.starts_at + 1.day == self.ends_at
    else
      self.starts_at == self.ends_at
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
  #  A couple of dummy methods to allow an organiser name to be
  #  included in our forms.
  #
  def organiser_name
    self.organiser ? self.organiser.name : ""
  end
  
  def organiser_name=(on)
    @organiser_name = on
  end
 
  def owners_initials
    if self.owner
      self.owner.initials
    else
      "SYS"
    end
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
  #  Assemble all the commitments to this event which this user is allowed
  #  to see.  Preload the corresponding elements.
  #
  def commitments_for(user)
    by_type = Hash.new
    approvables = Array.new
    all_commitments =
      self.commitments.preload(:element).to_a   # to_a to force the d/b hit.
    all_commitments.each do |c|
      #
      #  If a commitment is as the result of a request, and the current
      #  user is an administrator of requests, don't show the commitment
      #  in the general grouping.
      #
      #  Currently works only for exam invigilations.  Will need refining
      #  when requests start being used for other purposes too.
      #
      unless user && user.exams? && c.request_id
        if user && user.can_approve?(c) &&
           (c.tentative || c.rejected || c.constraining)
          approvables << c
        else
          by_type[c.element.entity_type] ||=
            CommitmentSet.new(c.element.entity_type)
          by_type[c.element.entity_type] << c
        end
      end
    end
    if user
      #
      #  Not yet separating out the ones which this user can approve.
      #
      [[by_type["Staff"],
        by_type["Pupil"],
        by_type["Group"],
        by_type["Subject"],
        by_type["Location"],
        by_type["Service"],
        by_type["Property"]].compact, approvables]
    else
      #
      #  The general public get to see just Staff, Locations and Groups.
      #
      [[by_type["Staff"],
        by_type["Group"],
        by_type["Location"]].compact, []]
    end
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

  #
  #  Get just one location name, or an empty string if there isn't one.
  #
  def location_name
    all_locations = self.locations
    if all_locations.size > 0
      all_locations[0].friendly_name
    else
      ""
    end
  end

  def pupils(and_by_group = false)
    if and_by_group
      self.all_atomic_resources.select {|r| r.instance_of?(Pupil)}
    else
      self.resources.select {|r| r.instance_of?(Pupil)}
    end
  end

  def pupil_year_groups(and_by_group = false, in_era = Setting.current_era)
    self.pupils(and_by_group).collect {|p| p.year_group(in_era)}.uniq
  end

  def staff(and_by_group = false)
    if and_by_group
      self.all_atomic_resources.select {|r| r.instance_of?(Staff)}
    else
      self.resources.select {|r| r.instance_of?(Staff)}
    end
  end

  #
  #  Try for a potentially optimised way of doing it.
  #  If the client does a preload() on staff_elements and the
  #  corresponding entities, then these should already be in memory.
  #
  #  element.commitments_on(...).preload(event: {staff_elements: :entity})
  #
  #  does the job.
  #
  def staff_entities
    staff_elements.collect {|e| e.entity}
  end

  def groups
    self.resources.select {|r| r.instance_of?(Group)}
  end

  def properties
    self.resources.select {|r| r.instance_of?(Property)}
  end

  def all_notes_for(user)
    self.commitments.collect { |commitment|
      commitment.notes.visible_to(user).to_a
    }.flatten +
    self.notes.visible_to(user).to_a
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
                     include_nonexistent = false,
                     organised_by  = nil)
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
    if enddate == :never
      dateafter = :never
    else
      dateafter = enddate   ? enddate.to_date + 1 : startdate + 1
    end
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
    if organised_by
      duffparameter = true unless organised_by.instance_of?(Element)
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
      unless dateafter == :never
        query_string_parts << "starts_at < :dateafter"
        query_hash[:dateafter] = Time.zone.parse("00:00:00", dateafter)
      end
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
      if organised_by
        query_string_parts << "organiser_id = :organiser_id"
        query_hash[:organiser_id] = organised_by.id
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

  #
  #  Is this event covered at all?
  #
  def covered?
    self.commitments.covering_commitment.count > 0
  end

  #
  #  Lose a property if the event currently has it.
  #
  def lose_property(property)
    self.commitments.each do |c|
      if c.element_id == property.element.id
        c.destroy
      end
    end
  end

  #
  #  Add a property if the event does not already have it.
  #
  def add_property(property)
    unless self.involves?(property)
      c = Commitment.new
      c.event = self
      c.element = property.element
      c.save!
    end
  end


  def involves?(item, even_tentative = false)
    if item.instance_of?(Element)
      resource = item
    else
      resource = item.element
    end
    if even_tentative
      selector = self.commitments
    else
      selector = self.commitments.firm
    end
#    Rails.logger.debug("Checking for commitments to #{resource.id}")
#    Rails.logger.debug("Have commitments to:")
#    selector.each do |c|
#      Rails.logger.debug("Element id #{c.element_id}")
#    end
    !!selector.detect {|c| c.element_id == resource.id }
  end

  def involves_any?(list, even_tentative = false)
#    Rails.logger.debug("Entering involves_any? to check:")
#    list.each do |element|
#      Rails.logger.debug("Element id #{element.id}")
#    end
    if list.detect {|item| self.involves?(item, even_tentative)}
      true
    else
      false
    end
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
                      end_time     = true,
                      no_space     = false)
    if end_time
      self.starts_at.interval_str(self.ends_at,
                                  clock_format == :twelve_hour,
                                  no_space)
    else
      self.starts_at.interval_str(nil,
                                  clock_format == :twelve_hour,
                                  no_space)
    end
  end

  #
  #  Produce either the event's duration, or the string "all day"
  #  for an all day event.  If the event's end time is the same as
  #  the start time, then print it just once.
  #
  def duration_or_all_day_string
    if self.all_day
      "all day"
    else
      self.starts_at.interval_str(self.ends_at)
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

  #
  #  A bit of a helper method for forms.  Usually we only allow the selection
  #  of categories which are not marked as deprecated, but that really
  #  confuses end users if this event already is in a deprecated category.
  #  In that one particular case, allow that category to appear (but still
  #  don't allow it to be selected).
  #
  #  Also, don't show privileged categories to non-privileged users.
  #
  def suitable_categories(user)
    if self.eventcategory
      self.eventcategory.categories_for(user)
    else
      Eventcategory.categories_for(user)
    end
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

  def self.count_commitments
    total_resources = 0
    Event.find_each do |e|
      total_resources += e.all_atomic_resources.count
    end
    puts "Total resources attached to events - #{total_resources}."
    nil
  end

  private

  def become_all_day
#    Rails.logger.debug("Becoming all_day.")
    #
    #  Was a timed event - now an all day event.  Set the start time
    #  to be midnight at the start of the day containing the start time.
    #  Set the end time to be midnight at the end of the day containing
    #  the end time, unless the end time is already midnight in which
    #  case leave it alone.
    #
    self.starts_at = self.starts_at.to_date
    unless self.ends_at.midnight?
      self.ends_at = self.ends_at.to_date + 1.day
    end
  end

  def become_timed
    Rails.logger.debug("Becoming timed, with starts_at = #{self.starts_at} and ends_at = #{self.ends_at}.")
    #
    #  Was an all day event, but now am not.
    #  Used to do some messing about with setting times to 08:00, but
    #  that's now relatively unnecessary because multi-day timed
    #  events are displayed differently.
    #
    if @ends_at_text_value
      Rails.logger.debug("@ends_at_text_value = #{@ends_at_text_value}")
      #
      #  We have earlier adjusted our ends_at value on the basis that this
      #  is an all day event.  Undo that adjustment, because we now know
      #  it isn't.
      #
      self.ends_at = @ends_at_text_value
      Rails.logger.debug("self.ends_at is now #{self.ends_at}")
      #
      #  Adjust this as if we were still un-timed.
      #
      if self.ends_at.midnight?
        Rails.logger.debug("Adjusting")
        self.ends_at = self.ends_at + 1.day
      end
    end
#    Rails.logger.debug("Now timed, with starts_at = #{self.starts_at} and ends_at = #{self.ends_at}.")
  end

  protected

  def being_destroyed
    @being_destroyed = true
  end

end
