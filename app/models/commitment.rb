# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Commitment < ActiveRecord::Base

  belongs_to :event
  belongs_to :element

  validates_presence_of :event, :element
  validates_associated  :event,   :message => "Event does not exist"
  validates_associated  :element, :message => "Element does not exist"

  validates :element_id, uniqueness: { scope: :event_id }

  # Note naming here.  If this commitment is covering another commitment
  # then we point at it.  Code can read:
  #
  #  if commitment.covering
  #
  # If this commitment is being covered then the coverer should point at
  # us.  Code can read:
  #
  #  if commitment.covered
  #
  belongs_to :covering, :class_name => 'Commitment'

  # If this commitment is being covered and this commitment gets deleted
  # then the covering commitment should be deleted too.
  has_one    :covered,
             :class_name  => 'Commitment',
	     :foreign_key => :covering_id,
	     :dependent   => :destroy

  scope :by, lambda {|entity| where("element_id = ?", entity.element.id) }
  scope :to, lambda {|event| where("event_id = ?", event.id) }

  scope :names_event, lambda { where("names_event = true") }

  #
  #  This isn't a real field in the d/b.  It exists to allow a name
  #  to be typed in the dialogue for creating a commitment record.
  #
  def element_name
    @element_name 
  end

  def element_name=(en)
    @element_name = en
  end

  def self.cover_commitments(after = nil)
    after ||= Date.today
    #
    #  This should surely be a scope?
    #
    Commitment.find(:all,
                    :joins => :event,
                    :conditions => ["commitments.covering_id IS NOT NULL and events.starts_at > ?",
                                    after])
  end

  #
  #  Very similar to the events_on method provided by the event model,
  #
  def self.commitments_on(startdate     = nil,
                          enddate       = nil,
                          eventcategory = nil,
                          eventsource   = nil,
                          element       = nil,
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
    if element
      if element.instance_of?(String)
        res = Element.find_by_name(element)
      elsif element.instance_of?(Element)
        res = element
      elsif element.respond_to?(:element) &&
            resource.element.instance_of?(Element)
        res = element.element
      end
      duffparameter = true unless res
    end
    if duffparameter
      []
    else
      query_hash = {}
      query_string_parts = []
      query_string_parts << "events.starts_at < :dateafter"
      query_hash[:dateafter] = Time.zone.parse("00:00:00", dateafter)
      query_string_parts << "events.ends_at >= :startdate"
      query_hash[:startdate] = Time.zone.parse("00:00:00", startdate)
      if ec
        query_string_parts << "events.eventcategory_id = :eventcategory_id"
        query_hash[:eventcategory_id] = ec.id
      end
      if es
        query_string_parts << "events.eventsource_id = :eventsource_id"
        query_hash[:eventsource_id] = es.id
      end
      if res
        query_string_parts << "element_id = :element_id"
        query_hash[:element_id] = res.id
      end
      unless include_nonexistent
        query_string_parts << "not events.non_existent"
      end
      Commitment.joins(:event).where(query_string_parts.join(" and "),
                                      query_hash)
    end
  end

  def self.set_names_event_flags
    flags_set = 0
    Commitment.preload(:element).commitments_on("2013-09-01", "2015-08-31", "Lesson", "SchoolBase").each do |c|
      #
      #  A lesson loaded from SchoolBase, therefore named after the
      #  teaching group.
      #
      if c.element.entity.class == Group &&
         c.element.entity.name == c.event.body &&
         !c.names_event
        c.names_event = true
        c.save!
        flags_set += 1
      end
    end
    puts "Set #{flags_set} flags."
  end

end
