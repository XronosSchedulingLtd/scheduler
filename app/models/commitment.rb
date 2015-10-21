# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Commitment < ActiveRecord::Base

  belongs_to :event
  belongs_to :element

  validates_presence_of :event, :element
  validates_associated  :event,   :message => "Event does not exist"
  validates_associated  :element, :message => "Element does not exist"

  validates :element_id, uniqueness: { scope: [:event_id, :covering_id] }

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

  scope :covering_commitment, lambda { where("covering_id IS NOT NULL") }
  scope :non_covering_commitment, lambda { where("covering_id IS NULL") }
  scope :covered_commitment, -> { joins(:covered) }
  scope :uncovered_commitment, -> { joins("left outer join `commitments` `covereds_commitments` ON `covereds_commitments`.`covering_id` = `commitments`.`id`").where("covereds_commitments.id IS NULL") }
  scope :firm, -> { where(:tentative => false) }
  scope :tentative, -> { where(:tentative => true) }
  scope :not_rejected, -> { where(:rejected => false) }
  scope :constraining, -> { where(:constraining => true) }

  #
  #  Call-backs.
  #
  after_save    :update_event_after_save
  after_destroy :update_event_after_destroy

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

  #
  #  Override the default setter.
  #
  def tentative=(new_value)
    if self.tentative && !new_value
      self.constraining = true
      self.rejected = false
    elsif !self.tentative && new_value
      self.constraining = false
    end
    super(new_value)
  end

  #
  #  Approve this commitment if it wasn't already, and save it to
  #  the d/b.
  #
  def approve_and_save!
    self.tentative = false
    self.save!
  end

  def reject_and_save!
    self.tentative = true
    self.rejected  = true
    self.save!
  end

  #
  #  Clone an existing commitment and save to d/b.
  #  Note that you *must* provide at least one modifier or the save
  #  will fail.  Commitments must be unique.
  #
  def clone_and_save(modifiers)
    new_self = self.dup
    modifiers.each do |key, value|
      new_self.send("#{key}=", value)
    end
    new_self.save!
    new_self
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


  def self.start_time_from_date(start_date)
    Time.zone.parse("00:00:00", startdate)
  end

  def self.end_time_from_date(end_date)
    if end_date
      Time.zone.parse("00:00:00", end_date + 1.day)
    else
      :never
    end
  end

  #
  #  This is intended for use explicitly by the results of calling
  #  memberships_by_duration on the element model.
  #
  #  Note that we're getting quite close to the d/b here, and so we
  #  use the same convention as the d/b to indicate "going on forever".
  #  If you want to go on forever, pass an enddate of nil.
  #
  #  Higher level code uses a slightly different convention, with
  #  :never to go on forever and nil meaning "the same as the start
  #  date".  Client code should be calling the higher level code and
  #  not this method directly.
  #
  def self.commitments_for_element_and_mwds(element:,
                                            start_date:,
                                            end_date:,
                                            mwd_set:,
                                            eventcategory:       nil,
                                            eventsource:         nil,
                                            owned_by:            nil,
                                            include_nonexistent: false)
    duffparameter = false
    #
    #  One or more event categories.
    #
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
    #
    #  One or more event sources.
    #
    ess = []
    if eventsource
      if eventsource.respond_to?(:each)
        esa = eventsource
      else
        esa = [eventsource]
      end
      esa.each do |es|
        if es.instance_of?(String)
          es = Eventsource.find_by_name(es)
        end
        if es.instance_of?(Eventsource)
          ess << es
        else
          duffparameter = true
        end
      end
    end
    owners = []
    if owned_by
      if owned_by.respond_to?(:each)
        owner_array = owned_by
      else
        owner_array = [owned_by]
      end
      owner_array.each do |owner|
        if owner.instance_of?(User)
          owners << owner
        else
          duffparameter = true
        end
      end
    end
    if duffparameter
      Commitment.none
    else
      query_hash = {}
      query_string_parts = []
      if ecs.size > 0
        if ecs.size == 1
          query_string_parts << "events.eventcategory_id = :eventcategory_id"
          query_hash[:eventcategory_id] = ecs[0].id
        else
          #
          #  Aiming for "(events.event_category_id = :ec1 OR
          #               events.event_category_id = :ec2)"
          #
          query_string_parts << "(#{
            ecs.collect {|ec|
              "events.eventcategory_id = :ec#{ec.id}"
            }.join(" or ")
          })"
          ecs.each do |ec|
            query_hash[:"ec#{ec.id}"] = ec.id
          end
        end
      end
      if ess.size > 0
        if ess.size == 1
          query_string_parts << "events.eventsource_id = :eventsource_id"
          query_hash[:eventsource_id] = ess[0].id
        else
          query_string_parts << "(#{
            ess.collect {|es|
              "events.eventsource_id = :es#{es.id}"
            }.join(" or ")
          })"
          ess.each do |es|
            query_hash[:"es#{es.id}"] = es.id
          end
        end
      end
      if owners.size > 0
        if owners.size == 1
          query_string_parts << "events.owner_id = :owner_id"
          query_hash[:owner_id] = owners[0].id
        else
          query_string_parts << "(#{
            owners.collect {|owner|
              "events.owner_id = :owner#{owner.id}"
            }.join(" or ")
          })"
          owners.each do |owner|
            query_hash[:"owner#{owner.id}"] = owner.id
          end
        end
      end
      unless include_nonexistent
        query_string_parts << "not events.non_existent"
      end
      text_snippet = element.sql_snippet(start_date, end_date)
      unless mwd_set.empty?
        text_snippet = text_snippet + " OR " + mwd_set.to_sql
      end
      #
      #  It's possible my query_hash is empty, but AR doesn't seem to
      #  mind that.  It becomes a null restriction.
      #
      Commitment.joins(:event).
                 where(query_string_parts.join(" and "), query_hash).
                 where(text_snippet)
#      if mwd_set.empty?
#        Commitment.joins(:event).where(element.sql_snippet(start_date, end_date))
#      else
#        Commitment.joins(:event).
#                   where(element.sql_snippet(start_date, end_date) +
#                         " OR " + mwd_set.to_sql)
#      end
    end
  end


  #
  #  Very similar to the events_on method provided by the event model,
  #
  #  Has however been modified to use keyword arguments, as introduced
  #  in Ruby 2.0
  #
  def self.commitments_on(startdate:           nil,
                          enddate:             nil,
                          eventcategory:       nil,
                          eventsource:         nil,
                          resource:            nil,
                          owned_by:            nil,
                          include_nonexistent: false)
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
    #
    #  Now we need midnight at the start of these two dates, expressed
    #  as a Time, to pass to the method that does the actual work.
    #
    start_time = Time.zone.parse("00:00:00", startdate)
    if dateafter == :never
      end_time   = :never
    else
      end_time   = Time.zone.parse("00:00:00", dateafter)
    end
    self.commitments_during(start_time:          start_time,
                            end_time:            end_time,
                            eventcategory:       eventcategory,
                            eventsource:         eventsource,
                            resource:            resource,
                            owned_by:            owned_by,
                            include_nonexistent: include_nonexistent)
  end


  def self.commitments_during(start_time:          nil,
                              end_time:            nil,
                              eventcategory:       nil,
                              eventsource:         nil,
                              resource:            nil,
                              owned_by:            nil,
                              include_nonexistent: false)
    duffparameter = false
    start_time = Time.zone.now unless start_time
    end_time   = start_time unless end_time
    #
    #  One or more event categories.
    #
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
    #
    #  One or more event sources.
    #
    ess = []
    if eventsource
      if eventsource.respond_to?(:each)
        esa = eventsource
      else
        esa = [eventsource]
      end
      esa.each do |es|
        if es.instance_of?(String)
          es = Eventsource.find_by_name(es)
        end
        if es.instance_of?(Eventsource)
          ess << es
        else
          duffparameter = true
        end
      end
    end
    elements = []
    if resource
      if resource.respond_to?(:each)
        resource_array = resource
      else
        resource_array = [resource]
      end
      resource_array.each do |res|
        if res.instance_of?(String)
          res = Element.find_by_name(res)
        elsif res.respond_to?(:element) &&
              res.element.instance_of?(Element)
          res = res.element
        end
        if res.instance_of?(Element)
          elements << res
        else
          duffparameter = true
        end
      end
    end
    owners = []
    if owned_by
      if owned_by.respond_to?(:each)
        owner_array = owned_by
      else
        owner_array = [owned_by]
      end
      owner_array.each do |owner|
        if owner.instance_of?(User)
          owners << owner
        else
          duffparameter = true
        end
      end
    end
    if duffparameter
      Commitment.none
    else
      query_hash = {}
      query_string_parts = []
      #
      #  For an explanation of why the conditions are like this, see
      #  either the Event model, or the journal for 27/10/2014.
      #
      unless end_time == :never
        query_string_parts << "events.starts_at < :end_time"
        query_hash[:end_time] = end_time
      end
      query_string_parts << "events.ends_at > :start_time"
      query_hash[:start_time] = start_time
      if ecs.size > 0
        if ecs.size == 1
          query_string_parts << "events.eventcategory_id = :eventcategory_id"
          query_hash[:eventcategory_id] = ecs[0].id
        else
          #
          #  Aiming for "(events.event_category_id = :ec1 OR
          #               events.event_category_id = :ec2)"
          #
          query_string_parts << "(#{
            ecs.collect {|ec|
              "events.eventcategory_id = :ec#{ec.id}"
            }.join(" or ")
          })"
          ecs.each do |ec|
            query_hash[:"ec#{ec.id}"] = ec.id
          end
        end
      end
      if ess.size > 0
        if ess.size == 1
          query_string_parts << "events.eventsource_id = :eventsource_id"
          query_hash[:eventsource_id] = ess[0].id
        else
          query_string_parts << "(#{
            ess.collect {|es|
              "events.eventsource_id = :es#{es.id}"
            }.join(" or ")
          })"
          ess.each do |es|
            query_hash[:"es#{es.id}"] = es.id
          end
        end
      end
      if elements.size > 0
        if elements.size == 1
          query_string_parts << "element_id = :element_id"
          query_hash[:element_id] = elements[0].id
        else
          query_string_parts << "(#{
            elements.collect {|element|
              "element_id = :element#{element.id}"
            }.join(" or ")
          })"
          elements.each do |element|
            query_hash[:"element#{element.id}"] = element.id
          end
        end
      end
      if owners.size > 0
        if owners.size == 1
          query_string_parts << "events.owner_id = :owner_id"
          query_hash[:owner_id] = owners[0].id
        else
          query_string_parts << "(#{
            owners.collect {|owner|
              "events.owner_id = :owner#{owner.id}"
            }.join(" or ")
          })"
          owners.each do |owner|
            query_hash[:"owner#{owner.id}"] = owner.id
          end
        end
      end
      unless include_nonexistent
        query_string_parts << "not events.non_existent"
      end
      Commitment.joins(:event).
                 where(query_string_parts.join(" and "), query_hash)
    end
  end

#  def self.set_names_event_flags
#    flags_set = 0
#    Commitment.preload(:element).commitments_on("2013-09-01", "2015-08-31", "Lesson", "SchoolBase").each do |c|
      #
      #  A lesson loaded from SchoolBase, therefore named after the
      #  teaching group.
      #
#      if c.element.entity.class == Group &&
#         c.element.entity.name == c.event.body &&
#         !c.names_event
#        c.names_event = true
#        c.save!
#        flags_set += 1
#      end
#    end
#    puts "Set #{flags_set} flags."
#  end

  protected

  def update_event_after_save
    if self.event
      self.event.update_from_commitments(self.tentative, self.constraining)
    end
  end

  def update_event_after_destroy
    if self.event
      self.event.update_from_commitments(false, false)
    end
  end

end
