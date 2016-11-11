# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Element < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  has_many :memberships, :dependent => :destroy
  has_many :commitments, :dependent => :destroy
  has_many :concerns,    :dependent => :destroy
  has_many :freefinders, :dependent => :destroy
  has_many :organised_events,
           :class_name => "Event",
           :foreign_key => :organiser_id,
           :dependent => :nullify
  has_many :excluded_itemreports,
           :class_name => :Itemreport,
           :foreign_key => :excluded_element_id,
           :dependent => :nullify
  has_one :promptnote, :dependent => :destroy
  belongs_to :owner, :class_name => :User

  scope :current, -> { where(current: true) }
  scope :staff, -> { where(entity_type: "Staff") }
  scope :agroup, -> { where(entity_type: "Group") }
  scope :property, -> { where(entity_type: "Property") }
  scope :mine_or_system, ->(current_user) { where("owner_id IS NULL OR owner_id = :user_id", user_id: current_user.id) }
  scope :owned, -> { where(owned: true) }
  scope :disowned, -> { where(owned: false) }

  before_destroy :being_destroyed
  after_save :rename_affected_events

  SORT_ORDER_HASH = {
    "Property" => 1,
    "Subject"  => 2,
    "Staff"    => 3,
    "Pupil"    => 4,
    "Location" => 5,
    "Group"    => 6,
    "Service"  => 7
  }.tap {|h| h.default = 0}

  #
  #  The hint tells us whether the invoking concern is an owning
  #  concern.  If it is, then we are definitely owned.  If it is
  #  not then we might not be owned any more.
  #
  def update_ownedness(hint)
    unless @being_destroyed || self.destroyed?
      if hint
        unless self.owned
          self.owned = true
          self.save!
        end
      else
        if self.owned
          #
          #  It's possible our last remaining owner just went away.
          #  This is the most expensive case to check.
          #
          if self.concerns.owned.count == 0
            self.owned = false
            self.save!
          end
        end
      end
    end
  end

  #
  #  Provide a list of the users who are recorded as "own"ing this element.
  #  That is - they can approve commitments of it.
  #
  def owners
    self.concerns.owned.collect {|c| c.user}
  end

  #
  #  The start of complete re-work of how we find commitments.
  #
  #  The purpose of this method is to find a list of all the groups
  #  to which this element belongs during the indicated interval, as
  #  efficiently as possible.  For each one found, we return a
  #  GroupWithDuration object, giving not only the group, but also the
  #  exact interval for which we were a member.  Dates are all inclusive
  #  because that's how the information is stored in the database.
  #
  #  A start_date or end_date of nil means to go on forever in that
  #  direction.
  #
  #  It is assumed that the dates in the membership records will be
  #  accurate - we don't check the group dates as well.  The membership
  #  records should have been checked against the group dates at time of
  #  creation/update.
  #
  def memberships_by_duration(start_date:, end_date:)
    results = Membership::MWD_Set.new(self)
    self.recurse_mbd(results, start_date, end_date, [])
    results.finalize
    results
  end

  def recurse_mbd(mwd_set, start_date, end_date, seen, level = 1)
#    Rails.logger.debug("Entering recurse_mbd for #{self.name}.")
    selector = self.memberships.inclusions
    if start_date
      if end_date
        selector = selector.active_during(start_date, end_date)
      else
        selector = selector.continues_until(start_date)
      end
    else
      if end_date
        selector = selector.starts_by(end_date)
      end
    end
    selector.preload([:group, :group => :element]).each do |m|
      #
      #  Each group gets its own fresh copy of the "seen" array.
      #  We're only interested in getting rid of loops.  It's
      #  perfectly legitimate to encounter the same group up
      #  two different branches, and we need to take account of
      #  both of them.
      #
      copy_seen = seen.dup
      m.recurse_mbd(mwd_set, start_date, end_date, copy_seen, level)
    end
#    Rails.logger.debug("Leaving recurse_mbd for #{self.name}.")
  end

  #
  #  Used indirectly by the above methods.  Generate a small snippet
  #  of SQL to select commitments for this element.
  #
  def sql_snippet(starting, ending)
    if starting.kind_of?(Time)
      #
      #  Must supply both as times.
      #
      start_time = starting
      end_time = ending
    else
      #
      #  Dates.  Might not get an end date.
      #
      start_time = starting.start_time
      if ending
        end_time = ending.end_time
      else
        end_time = nil
      end
    end
    if end_time
      prefix = "(events.starts_at < '#{end_time.to_s(:db)}' AND "
    else
      prefix = "("
    end
    prefix + "events.ends_at > '#{start_time.to_s(:db)}' AND commitments.element_id = #{self.id})"
  end

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
    puts "Entering groups at #{Time.now.strftime("%H:%M:%S.%3N")}."
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
      #  ******* N.B. *******
      #
      #  Above comment kept for historical documentation reasons.  "as_at"
      #  seems to be on its way out - it's never been used - and we do now
      #  filter to just the active memberships.  It produces a significant
      #  speed improvement.
      #
      self.memberships.
           inclusions.
           active_on(given_date).
           preload(:group).
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
                include_tentative = false)
    if include_tentative
      self.commitments_on(startdate: start_date,
                          enddate: end_date,
                          eventcategory: eventcategory,
                          eventsource: eventsource,
                          and_by_group: and_by_group,
                          include_nonexistent: include_nonexistent).
           preload(:event).
           collect {|c| c.event}.uniq
    else
      self.commitments_on(startdate: start_date,
                          enddate: end_date,
                          eventcategory: eventcategory,
                          eventsource: eventsource,
                          and_by_group: and_by_group,
                          include_nonexistent: include_nonexistent).
           firm.
           preload(:event).
           collect {|c| c.event}.uniq
    end
  end

  #
  #  A slightly specialist method, used by the schedule controller when
  #  requesting events to display for an element.  What you get depends
  #  on the current user.
  #
  def display_events(start_date, end_date, eventcategory, user, concern)
    self.commitments_on(startdate: start_date,
                        enddate: end_date,
                        eventcategory: eventcategory,
                        include_nonexistent: true).
           preload(:event).
           select {|c| concern.owns ||
                       user.admin ||
                       !c.tentative ||
                       c.event.owner_id == user.id }.
           collect {|c| c.event}.uniq
  end

  #
  #  Re-work of the old commitments_on, with exactly the same signature
  #  but using the new more efficient code.  Has to do a bit more of the
  #  work.
  #
  #  Note that we ignore the "effective_date" parameter, which was a
  #  frig needed because the old implementation didn't work properly.
  #  We do work properly.
  #
  def commitments_on(startdate:           nil,
                     enddate:             nil,
                     eventcategory:       nil,
                     eventsource:         nil,
                     owned_by:            nil,
                     include_nonexistent: false,
                     and_by_group:        true,
                     effective_date:      nil)
    if and_by_group
      #
      #  This requires the new code, and a bit of preliminary spadework.
      #
      startdate = startdate ? startdate.to_date : Date.today
      #
      #  Change of convention for enddate.
      #
      if enddate == nil
        enddate = startdate
      elsif enddate == :never
        enddate = nil
      else
        enddate = enddate.to_date
      end
      #
      #  Now the actual retrieval is done in two stages.
      #
      mwd_set = self.memberships_by_duration(start_date: startdate,
                                             end_date: enddate)
      Commitment.commitments_for_element_and_mwds(
        element:             self,
        starting:            startdate,
        ending:              enddate,
        mwd_set:             mwd_set,
        eventcategory:       eventcategory,
        eventsource:         eventsource,
        owned_by:            owned_by,
        include_nonexistent: include_nonexistent)
    else
      #
      #  The old code is quite capable of coping with this.
      #
      Commitment.commitments_on(startdate:           startdate,
                                enddate:             enddate,
                                eventcategory:       eventcategory,
                                eventsource:         eventsource,
                                resource:            [self],
                                owned_by:            owned_by,
                                include_nonexistent: include_nonexistent)
    end
  end

  def commitments_during(start_time:,
                         end_time:,
                         eventcategory:       nil,
                         eventsource:         nil,
                         owned_by:            nil,
                         include_nonexistent: false,
                         and_by_group:        true)
    if and_by_group
      #
      #  The MWD stuff needs dates.
      #
      startdate = start_time.to_date
      enddate = end_time.to_date
      #
      #  Now the actual retrieval is done in two stages.
      #
      mwd_set = self.memberships_by_duration(start_date: startdate,
                                             end_date: enddate)
      Commitment.commitments_for_element_and_mwds(
        element:             self,
        starting:            start_time,
        ending:              end_time,
        mwd_set:             mwd_set,
        eventcategory:       eventcategory,
        eventsource:         eventsource,
        owned_by:            owned_by,
        include_nonexistent: include_nonexistent)
    else
      #
      #  The old code is quite capable of coping with this.
      #
      Commitment.commitments_during(
        start_time:          start_time,
        end_time:            end_time,
        eventcategory:       eventcategory,
        eventsource:         eventsource,
        resource:            self,
        owned_by:            owned_by,
        include_nonexistent: include_nonexistent)
    end
  end


  def old_commitments_during(start_time:          nil,
                         end_time:            nil,
                         eventcategory:       nil,
                         eventsource:         nil,
                         owned_by:            nil,
                         include_nonexistent: false,
                         and_by_group:        true)
    puts "Entering commitments_during at #{Time.now.strftime("%H:%M:%S.%3N")}."
    if and_by_group
      if start_time != nil
        start_date = start_time.to_date
      end
      my_groups = self.groups(start_date)
    else
      my_groups = []
    end
    puts "Got groups at #{Time.now.strftime("%H:%M:%S.%3N")}."
    result = Commitment.commitments_during(start_time:          start_time,
                                  end_time:            end_time,
                                  eventcategory:       eventcategory,
                                  eventsource:         eventsource,
                                  resource:            [self] + my_groups,
                                  owned_by:            owned_by,
                                  include_nonexistent: include_nonexistent)
    puts "Fetched commitments at #{Time.now.strftime("%H:%M:%S.%3N")}."
    result
  end

  #
  #  Provide a short description of the kind of entity which we
  #  represent, allowing the entity itself potentially to add more.
  #
  def kind_of_entity
    "#{self.entity_type}#{self.entity.more_type_info}"
  end

  def indefinite_kind_of_entity
    body = self.kind_of_entity.downcase
    if /^[AEIOU]/i =~ body
      "<p>An #{body}</p>".html_safe
    else
      "<p>A #{body}</p>".html_safe
    end
  end

  def entity_description
    if entity.respond_to?(:description_line)
      entity.description_line
    else
      indefinite_kind_of_entity
    end
  end

  def show_historic_panels?
    entity.show_historic_panels?
  end

  def short_name
    entity.short_name
  end

  def description
    entity.description
  end

  def tabulate_name(columns)
    entity.tabulate_name(columns)
  end

  def csv_name
    entity.csv_name
  end

  def owned?
    self.owned
  end

  #
  #  We sort elements first by their type (order specified at head of
  #  file) and then by their own native sorting method.
  #
  def <=>(other)
    result =
      SORT_ORDER_HASH[self.entity_type] <=> SORT_ORDER_HASH[other.entity_type]
    if result == 0
      result = self.entity <=> other.entity
    end
    result
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

  protected

  def being_destroyed
    @being_destroyed = true
  end

end
