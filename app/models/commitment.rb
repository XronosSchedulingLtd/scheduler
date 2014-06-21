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
                          element       = nil)
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
      commitments = []
    else
      if ec
        if res
          #
          #  Have been given both an event category and an element.
          #
          commitments =
            Commitment.find(
              :all,
              :joins => :event,
              :conditions => ["commitments.element_id = ? and events.starts_at < ? and events.ends_at >= ? and events.eventcategory_id = ? and not events.nonexistent",
                              res.id,
                              Time.zone.parse("00:00:00", dateafter),
                              Time.zone.parse("00:00:00", startdate),
                              ec.id])
        else
          #
          #  An event category, but no resource.
          #
          commitments =
            Commitment.find(
              :all,
              :joins => :event,
              :conditions => ["events.starts_at < ? and events.ends_at >= ? and events.eventcategory_id = ? and not events.nonexistent",
                              Time.zone.parse("00:00:00", dateafter),
                              Time.zone.parse("00:00:00", startdate),
                              ec.id])
        end
      else
        if res
          #
          #  Resource specified, but no event category.
          #
          commitments =
            Commitment.find(
              :all,
              :joins => :event,
              :conditions => ["commitments.element_id = ? and events.starts_at < ? and events.ends_at >= ? and not events.nonexistent",
                              res.id,
                              Time.zone.parse("00:00:00", dateafter),
                              Time.zone.parse("00:00:00", startdate)])
        else
          #
          #  Neither specified.
          #
          commitments =
            Commitment.find(
              :all,
              :joins => :event,
              :conditions => ["events.starts_at < ? and events.ends_at >= ? and not events.nonexistent",
                              Time.zone.parse("00:00:00", dateafter),
                              Time.zone.parse("00:00:00", startdate)])
        end
      end
    end
    commitments
  end


end
