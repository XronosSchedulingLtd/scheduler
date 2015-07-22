# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Element < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  has_many :memberships, :dependent => :destroy
  has_many :commitments, :dependent => :destroy
  has_many :ownerships,  :dependent => :destroy
  has_many :interests,   :dependent => :destroy
  has_many :concerns,    :dependent => :destroy
  has_many :organised_events,
           :class_name => "Event",
           :foreign_key => :organiser_id,
           :dependent => :nullify

  belongs_to :owner, :class_name => :User

  scope :current, -> { where(current: true) }
  scope :staff, -> { where(entity_type: "Staff") }
  scope :mine_or_system, ->(current_user) { where("owner_id IS NULL OR owner_id = :user_id", user_id: current_user.id) }
  after_save :rename_affected_events

  #
  #  This method is much like the "members" method in the Group model,
  #  except the other way around.  It provides a list of all the groups
  #  of which this element is a member on the indicated date.  If no
  #  date is given then use today's date.
  #
  #  Different processing however is required to handle inverses.  We need
  #  to work up to the groups of which we are potentially a member, then
  #  check we're not excluded from there by an inverse membership record.
  #
  #  If recursion is required then we have to select *all* groups of which
  #  we are a member, and not just those for the indicated date.  This is
  #  because recursion may specify a different date to think about.
  #
  def groups(given_date = nil, recurse = true)
    given_date ||= Date.today
    if recurse
      #
      #  With recursion, life gets a bit more entertaining.  We need to
      #  find all groups of which we might be a potential member (working
      #  up the tree until we find groups which aren't members of anything)
      #  then check which ones of these we are actually a member of on
      #  the indicated date.  The latter step could be done by a sledgehammer
      #  approach (call member?) for each of the relevant groups, but that
      #  might be a bit inefficient.  I'm hoping to do it as we reverse
      #  down the recursion tree.
      #
      #  When working our way up the tree we have to include *all*
      #  memberships, regardless of apparently active date because there
      #  might be an as_at date in one of the membership records which
      #  affects things on the way back down.
      #
      #  E.g. Able was a member of the group A back in June, but isn't now.
      #  Group A is a member of group B, with an as_at date of 15th June.
      #  Able is therefore a member of B, even though he isn't currently
      #  a member of A.
      #
      #  If we terminated the search on discovering that Able is not currently
      #  a member of A, we wouldn't discover that Able is in fact currently
      #  a member of B.
      #
      #  There is on the other hand no point in looking at exclusions on
      #  the way up the tree.  We look at inclusions on the way up,
      #  because without an inclusion of some sort the exclusion is irrelevant,
      #  then look at both on the way back down.
      #
      self.memberships.
           inclusions.
           collect {|membership| 
        membership.group.parents_for(self, given_date)
      }.flatten.uniq
    else
      #
      #  If recursion is not required then we just return a list of the
      #  groups of which this element is an immediate member.
      #
      #  DONE: if we are not recursing, this could be better implemented
      #        as a scope, or at least by use of scopes.
      #
      #self.memberships.active_on(given_date).inclusions.collect {|m| m.group}
      Group.with_member_on(self, given_date)
    end
  end

  def events_on(start_date = nil,
                end_date = nil,
                eventcategory = nil,
                eventsource = nil,
                and_by_group = true,
                include_nonexistent = false,
                seen = [])
    #
    #  If this element is a group then we should find its events (including
    #  those supplied by parent groups) once and only once.
    #
    if self.entity_type == "Group"
      if seen.include?(self.id)
        return []
      else
        seen << self.id
      end
    end
    # Rails.logger.debug("Entering Element#events_on")
    direct_events = Event.events_on(start_date,
                                    end_date,
                                    eventcategory,
                                    eventsource,
                                    self,
                                    nil,
                                    include_nonexistent)
    # Rails.logger.debug("Fetched #{direct_events.size} direct events")
    indirect_events = []
    if and_by_group && self.memberships.size > 0
      #
      # TODO: Need to fix this code to take account of *when* the
      # memberships are in effect.  Ideally, should adjust if the
      # membership changes in the course of the indicated time interval.
      #
      #  Potentially it would be enough to check the start end end dates
      #  of the interval.  If the groups of which we are a member are
      #  the same for both, then the chances are they stay the same for
      #  the whole interval.  If not then we need to do more work.
      #
      #  Note that the logic for sanitizing dates here is just slightly
      #  different from that in the Event#events_on method.  This is
      #  because events have a date and time and so the end marker needs
      #  to be the start of the following day.  Memberships have just
      #  a start and end date, so the end marker can be the last required
      #  date.
      #
      # Rails.logger.debug("Starting on indirect events")
      start_date = start_date ? start_date.to_date : Date.today
      end_date   = end_date ? end_date.to_date : start_date
      self.memberships.inclusions.active_during(start_date, end_date).each do |m|
        indirect_events =
          indirect_events + m.group.element.events_on(start_date,
                                                      end_date,
                                                      eventcategory,
                                                      eventsource,
                                                      and_by_group,
                                                      include_nonexistent,
                                                      seen)
      end
      # Rails.logger.debug("Finished indirect events")
    end
    (direct_events + indirect_events).uniq
  end

  def commitments_on(startdate:           nil,
                     enddate:             nil,
                     eventcategory:       nil,
                     eventsource:         nil,
                     owned_by:            nil,
                     include_nonexistent: false,
                     and_by_group:        true)
    my_groups = []
    if and_by_group
      #
      #  This is not a full implementation of what is needed, but it
      #  gives a good approximation for now.  For a discussion of possible
      #  approaches, see notes for 11th Jan, 2014
      #
      if startdate == nil
        if enddate == nil
          #
          #  We are defaulting to today, so get groups for today
          #
          my_groups = self.groups
        else
          if enddate == :never
            my_groups = self.groups
            end_date = :never
          else
            end_date = enddate.to_date
            if end_date < Date.today
              #
              #  End date is in the past, so I think that nothing is
              #  going to be returned anyway, but just in case...
              #
              my_groups = self.groups(end_date)
            else
              my_groups = self.groups
            end
          end
        end
      else
        start_date = startdate.to_date
        if start_date > Date.today
          #
          #  Start date in the future.
          #
          my_groups = self.groups(start_date)
        else
          #
          #  Start date in the past
          #
          if enddate == nil
            #
            #  Just the one day required.
            #
            my_groups = self.groups(start_date)
          elsif enddate == :never
            my_groups = self.groups
            end_date = :never
          else
            end_date = enddate.to_date
            if end_date < Date.today
              my_groups = self.groups(end_date)
            else
              #
              #  This is the most common case.  Start date and end
              #  date both specified, and the current date falls
              #  between them.
              #
              my_groups = self.groups
            end
          end
        end
      end
    end
    Commitment.commitments_on(startdate:           startdate,
                              enddate:             enddate,
                              eventcategory:       eventcategory,
                              eventsource:         eventsource,
                              resource:            [self] + my_groups,
                              owned_by:            owned_by,
                              include_nonexistent: include_nonexistent)
  end

  def commitments_during(start_time:          nil,
                         end_time:            nil,
                         eventcategory:       nil,
                         eventsource:         nil,
                         owned_by:            nil,
                         include_nonexistent: false,
                         and_by_group:        true)
    if and_by_group
      if start_time != nil
        start_date = start_time.to_date
      end
      my_groups = self.groups(start_date)
    else
      my_groups = []
    end
    Commitment.commitments_during(start_time:          start_time,
                                  end_time:            end_time,
                                  eventcategory:       eventcategory,
                                  eventsource:         eventsource,
                                  resource:            [self] + my_groups,
                                  owned_by:            owned_by,
                                  include_nonexistent: include_nonexistent)
  end

  def short_name
    entity.short_name
  end

  def rename_affected_events
    self.commitments.names_event.each do |c|
      if c.event.body != self.name
        c.event.body = self.name
        c.event.save!
      end
    end
  end

  def self.copy_current
    currents_updated_count = 0
    Element.all.each do |element|
      if element.current != element.entity.current
        element.current = element.entity.current
        element.save!
        currents_updated_count += 1
      end
    end
    puts "Updated #{currents_updated_count} current flags."
    nil
  end

end
