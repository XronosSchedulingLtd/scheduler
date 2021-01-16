# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Element < ApplicationRecord
  belongs_to :entity, :polymorphic => true
  has_many :memberships, :dependent => :destroy
  has_many :commitments, :dependent => :destroy
  has_many :requests, :dependent => :destroy
  has_many :requested_events, through: :requests, source: :event
  has_many :proto_commitments, :dependent => :destroy
  has_many :proto_requests, :dependent => :destroy
  has_many :exam_cycles_as_default_group,
           :class_name => 'ExamCycle',
           :foreign_key => :default_group_element_id,
           :dependent => :nullify
  has_many :exam_cycles_as_selector,
           :class_name => 'ExamCycle',
           :foreign_key => :selector_element_id,
           :dependent => :nullify
  has_many :concerns,    :dependent => :destroy
  has_many :freefinders, :dependent => :destroy
  has_one  :prep_element_setting,
           class_name: "Setting",
           foreign_key: :prep_property_element_id,
           dependent: :nullify
  #
  #  Interesting question about what happens to journal entries if
  #  the element goes away.  Elements aren't meant to go away
  #
  has_many :journal_entries, :dependent => :nullify
  has_many :organised_events,
           :class_name => "Event",
           :foreign_key => :organiser_id,
           :dependent => :nullify
  has_many :excluded_itemreports,
           :class_name => :Itemreport,
           :foreign_key => :excluded_element_id,
           :dependent => :nullify
  has_one :promptnote, :dependent => :destroy
  belongs_to :owner, class_name: :User, optional: true
  belongs_to :user_form, optional: true

  #
  #  This is actually a constraint in the database too, but by specifying
  #  it here we can catch errors earlier.
  #
  #  It's quite incredibly unlikely that we will actually generated duplicate
  #  uuids, but it's just possible that client code might copy one
  #  between records.
  #
  validates :uuid, uniqueness: true

  scope :current, -> { where(current: true) }
  scope :not_current, -> { where.not(current: true) }
  scope :add_directly, -> { where(add_directly: true) }
  scope :viewable, -> { where(viewable: true) }
  scope :staff, -> { where(entity_type: "Staff") }
  scope :person, -> { where(entity_type: "Pupil").or(Element.where(entity_type: "Staff")) }
  scope :agroup, -> { where(entity_type: "Group") }
#  scope :aresourcegroup, -> {
#    joins(:groups).where(entity_type: 'Group').where(groups: {persona_type: 'Resourcegrouppersona'})
#  }
  #
  #  This next one does in fact work, but is no longer needed because
  #  I'm doing it a different way.  Retained here for documentary
  #  reasons, and in case anything similar is needed in the future.
  #
  scope :aresourcegroup, -> {
    joins( "INNER JOIN `groups` ON `elements`.`entity_id` = `groups`.`id`").
    where( entity_type: 'Group').
    where( groups: {persona_type: 'Resourcegrouppersona'})
  }
  scope :property, -> { where(entity_type: "Property") }
  scope :location, -> { where(entity_type: "Location") }
  scope :subject, -> { where(entity_type: "Subject") }
  scope :mine_or_system, ->(current_user) { where("elements.owner_id IS NULL OR elements.owner_id = :user_id", user_id: current_user.id) }
  scope :mine, ->(current_user) { where(owner_id: current_user.id) }
  scope :owned, -> { where(owned: true) }
  scope :disowned, -> { where(owned: false) }
  scope :with_form, -> { where.not(user_form: nil) }

  before_create :add_uuid
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
  #  Each entity has a class method (and an instance method) to tell
  #  us whether it is a person or not.  If though one writes:
  #
  #  element.entity.class.a_person?
  #
  #  then ActiveRecord will fetch the entity record from the database,
  #  even though it doesn't actually need it - it already knows the
  #  class but doesn't look that far ahead.
  #
  #  Instead, we use a hash so we can determine the answer to the question
  #  without a database hit.
  #
  PERSONALITY_HASH = {
    "Property" => Property.a_person?,
    "Subject"  => Subject.a_person?,
    "Staff"    => Staff.a_person?,
    "Pupil"    => Pupil.a_person?,
    "Location" => Location.a_person?,
    "Group"    => Group.a_person?,
    "Service"  => Service.a_person?
  }.tap {|h| h.default = false }

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
  #  We delegate this to our entity.
  #
  def can_lock?
    self.entity && self.entity.can_lock?
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
  def groups(given_date = nil, recurse = true)
#    puts "Entering groups at #{Time.now.strftime("%H:%M:%S.%3N")}."
    given_date ||= Date.today
    if recurse
      gids = memberships_by_duration(
        start_date: given_date,
        end_date: given_date).group_list.collect {
          |g| g.id
        }
      if gids.empty?
        Group.none
      else
        Group.where(id: gids)
      end
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

  #
  #  This method is intended merely for testing the above method.  It
  #  is not an efficient way of testing membership.
  #
  def member_of?(group, date)
    self.groups(date).include?(group)
  end

  def a_person?
    PERSONALITY_HASH[self.entity_type]
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
                         excluded_category:   nil,
                         eventsource:         nil,
                         owned_by:            nil,
                         include_nonexistent: false,
                         and_by_group:        true,
                         cache:               nil)
    if and_by_group
      #
      #  The MWD stuff needs dates.
      #
      startdate = start_time.to_date
      enddate = end_time.to_date
      #
      #  Now the actual retrieval is done in two stages.
      #
      if cache
        mwd_set = cache.find(self, startdate, enddate)
        unless mwd_set
          mwd_set = self.memberships_by_duration(start_date: startdate,
                                                 end_date: enddate)
          cache.store(mwd_set, self, startdate, enddate)
        end
      else
        mwd_set = self.memberships_by_duration(start_date: startdate,
                                               end_date: enddate)
      end
      Commitment.commitments_for_element_and_mwds(
        element:             self,
        starting:            start_time,
        ending:              end_time,
        mwd_set:             mwd_set,
        eventcategory:       eventcategory,
        excluded_category:   excluded_category,
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
        excluded_category:   excluded_category,
        eventsource:         eventsource,
        resource:            self,
        owned_by:            owned_by,
        include_nonexistent: include_nonexistent)
    end
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

  def initials
    if entity.respond_to?(:initials)
      entity.initials
    else
      "n/a"
    end
  end

  #
  #  This one tests whether the next one should be called.
  #
  def extra_panels?
    entity.extra_panels?
  end

  def extra_panels(index)
    entity.extra_panels(index)
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

  #
  #  Can this element's entity do more than one cover at a time without
  #  generating a warning?
  #
  def multicover?
    if entity.respond_to?(:multicover)
      entity.multicover
    else
      false
    end
  end

  def can_have_requests?
    entity.can_have_requests?
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
    if @dont_rename
      @dont_rename = false
    else
      self.commitments.names_event.each do |c|
        if c.event.body != self.name
          c.event.body = self.name
          c.event.save!
        end
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

  #
  #  Client code is not allowed to modify uuid.
  #
  def uuid=(value)
  end

  #
  #  But in special circumstances it can at creation time request
  #  a particular uuid
  #
  def preferred_uuid=(value)
    @preferred_uuid = value
  end

  #
  #  This method is called as the element record is about to be
  #  created in the database.
  #
  def add_uuid
    #
    #  In theory we shouldn't get here if the record isn't valid, but...
    #
    if self.valid?
      #
      #  It is possible that the entity has its own idea about what
      #  our UUID should be.  If so, accept that, at least to begin
      #  with.
      #
      #  Note that this processing is not used in normal live code.
      #  It is solely for use in seeding the demonstration system.
      #
      if @preferred_uuid
        write_attribute(:uuid, @preferred_uuid)
      else
        generate_uuid
      end
      #
      #  This seems really stupid, but surely we should have some
      #  code to cope with the possibility of a clash?
      #
      #  I don't want a loop in case of a coding error which means
      #  it turns into an endless loop.
      #
      #  If after a second attempt our record is still invalid
      #  (meaning the uuid is still clashing with one already in
      #  the database) then the create!() (invoked from elemental.rb)
      #  will throw an error and the creation of the underlying
      #  element will be rolled back.  On the other hand, if you're
      #  that unlucky you're not going to live much longer anyway.
      #
      #  Note that by this point, the automatic Rails record validation
      #  has already been performed, and won't be performed again.
      #  The only thing which is going to stop the save succeeding
      #  is an actual constraint on the database - which is there.
      #
      unless self.valid?
        generate_uuid
      end
    end
  end

  def self.generate_uuids
    self.find_each do |element|
      if element.uuid.blank?
        element.generate_initial_uuid
        element.save!
      end
    end
    nil
  end

  #
  #  This one is public, but won't overwrite an existing uuid.
  #
  def generate_initial_uuid
    if self.uuid.blank?
      generate_uuid
      @dont_rename = true
    end
  end

  #
  #  We count pending commitments only if they have no outstanding forms.
  #
  #  A note on performance.
  #
  #  On a system with 58 pending future requests and about 1.7 million
  #  existing commitments, we started to see a big slowdown in this
  #  method, particularly in the requests part.  What we were doing was to
  #  preload the matching commitments, thus avoiding 58 individual
  #  counts (1 per request) to see how many commitments there were.  In all
  #  it took about 1700ms.
  #
  #    preload(:user_form_response, :commitments).
  #
  #  Surprisingly, just removing the preload achieved a big speed up.
  #  Instead of the single call to load all matching commitments for the
  #  58 requests, we started doing 58 separate COUNT calls and it took
  #  only 100-200ms in total.
  #
  #  I then added a cached_count field to the request records so that
  #  these d/b calls were no longer needed.  The incremental improvement
  #  was surprisingly small, but it's neater.
  #
  def permissions_pending
    unless @permissions_pending
      @permissions_pending = 
        self.commitments.
             preload(:user_form_response).
             future.
             requested.
             select {|c| c.no_forms_outstanding?  }.
             count +
        self.requests.
             preload(:user_form_response).
             future.
             select {|r| r.no_forms_outstanding?  }.
             inject(0) {|memo, r|
               memo + r.num_outstanding
             }
    end
    @permissions_pending
  end

  #
  #  Dummy methods for user form editing.
  #
  def user_form_name
    user_form ? user_form.name : ""
  end

  def user_form_name=(name)
    #
    #  Do nothing
    #
  end

  def aresourcegroup?
    self.entity_type == 'Group' &&
    self.entity.type == 'Resource'
  end

  #
  #  This element is to absorb all the commitments and memberships
  #  of the other indicated element, leaving it bereft of both.
  #
  #  Returns an array of 4 values.
  #
  #  * How many commitments the other element had.
  #  * How many were transferred.
  #  * How many memberships the other element had.
  #  * How many were transferred.
  #
  #  After calling this function, it's a good idea for the calling
  #  code to reload its copy of other_element, particularly if it
  #  intends to destroy it.  Otherwise the cached copy in memory
  #  may well cause some of the transferred things to be destroyed too.
  #
  def absorb(other_element)
    commitment_count = other_element.commitments.count
    commitments_transferred = 0
    other_element.commitments.each do |commitment|
      if self.commitments.detect {|c| c.event_id == commitment.event_id}
        commitment.destroy
      else
        commitment.element = self
        commitment.save!
        commitments_transferred += 1
        self.reload
      end
    end
    membership_count = other_element.memberships.count
    memberships_transferred = 0
    other_element.memberships.each do |membership|
      #
      #  This test is slightly too naive, because it takes no account
      #  of chronology.
      #
      if self.memberships.detect {|m| m.group_id == membership.group_id}
        membership.destroy
      else
        membership.element = self
        membership.save!
        memberships_transferred += 1
        self.reload
      end
    end
    return commitment_count,
           commitments_transferred,
           membership_count,
           memberships_transferred
  end

  #
  #  Not sure yet whether this will be just a maintenance method,
  #  or called automatically when our entity is updated.  It
  #  depends on how long it takes to run.
  #
  #  The idea is that it runs when the entity's "can_lock" field
  #  is updated.  The code assumes that it *has* been changed.
  #  That is - if it is true now then it was false before, and
  #  vice versa.
  #
  def update_potentially_locked_events
    #
    #  Only firm commitments (:uncontrolled or :confirmed) can
    #  influence locked-ness, so they're the only ones we need
    #  to check.
    #
    #  We preload the eventcategory because if we later save the
    #  event then a callback needs to find the eventcategory.
    #
    #  Likewise the eventsource, although I'm not sure why that's
    #  needed.  If we don't pre-load it, they all get loaded individually
    #  later.
    #
    self.commitments.
         firm.
         includes(event: [:eventcategory, :eventsource]).
         find_each do |commitment|
      commitment.event.update_lockedness(self.can_lock?)
    end
  end

  protected

  def being_destroyed
    @being_destroyed = true
  end

  #
  #  This one generates a uuid regardless.
  #
  def generate_uuid
    write_attribute(:uuid, SecureRandom.uuid)
  end

end
