# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Vanillagrouppersona
  #
  #  This exists just to exist.
  #  We require any group which is created to have a persona specified,
  #  but if you specify this one then it won't actually get a linked d/b
  #  record, and there will be no attributes other than the standard ones.
  #
end


class Group < ActiveRecord::Base
  belongs_to :era
  belongs_to :owner, :class_name => :User
  belongs_to :persona, :polymorphic => true, :dependent => :destroy
  #
  #  Since we can't do joins on polymorphic relationships, we need
  #  explicit ones too.  These should really be defined elsewhere, but
  #  I'm not sure how just yet.
  #
  belongs_to :tutorgrouppersona, -> { where(groups: {persona_type: 'Tutorgrouppersona'}) }, foreign_key: :persona_id
  belongs_to :teachinggrouppersona, -> { where(groups: {persona_type: 'Teachinggrouppersona'}) }, foreign_key: :persona_id
  has_many :memberships, :dependent => :destroy

  validates :starts_on, presence: true
  validates :name,      presence: true
  validates :era,       presence: true

  validate :not_backwards
  validate :persona_specified

  scope :current, -> { where(current: true) }

  scope :tutorgroups, -> { where(persona_type: 'Tutorgrouppersona') }
  scope :teachinggroups, -> { where(persona_type: 'Teachinggrouppersona') }
  scope :vanillagroups, -> { where(persona_type: nil) }

  #
  #  This next line is enough to get me burnt at the stake.
  #  Also, whilst very clever it doesn't actually do the thing which I
  #  wanted - I was muddling up to two types of ownership.  The ownerships
  #  which I am manipulating here relate to responsibility - like Rory
  #  used to be responsible for the Amey Theatre.  More than one person
  #  can be responsible for one Entity (via its Element) in this way.
  #
  #  I'm not aware of any groups with this kind of ownership though.  Where
  #  groups have owners it's because said owner created the group.  I suspect
  #  I wrote this line before I crystalised this distinction.
  #
  #  See Ownership in the documentation Wiki for more expansion.  Anyway,
  #  what I really want here is a list of groups which the user created.
  #
  # scope :belonging_to, ->(target_user) { joins(element: {ownerships: :user}).where(users: {id: target_user.id} ) }
  scope :belonging_to, ->(target_user) { where(owner_id: target_user.id) }
  scope :system, -> { where(owner_id: nil) }

  #
  #  Note that this next one makes no attempt to massage dates etc.  It's
  #  up to the client code to do that.  Nor does it check that the group
  #  is actually extant at the indicated date.  It's just intended to find
  #  the groups of which a given element is a direct member on an indicated
  #  date.
  #
  scope :with_member_on, ->(element, as_at) {
    joins(:memberships).where(
      "memberships.element_id = :element_id AND memberships.inverse = FALSE AND memberships.starts_on <= :as_at AND (memberships.ends_on IS NULL OR memberships.ends_on >= :as_at)",
      element_id: element.id,
      as_at: as_at)
  }

  after_initialize :set_flags
  before_create    :create_persona
  after_save       :update_persona

  attr_accessor :persona_class

  include Elemental

  def element_name
    name
  end

  def active
    true
  end

  #
  #  What type is this group?
  #
  def type
    if self.persona_type
      self.persona_type.chomp("grouppersona")
    else
      "Vanilla"
    end
  end

  def method_missing(method_sym, *arguments, &block)
    #
    #  How we behave depends on whether or not we already have
    #  a linked persona record.
    #
    if self.persona
      if self.persona.respond_to?(method_sym)
        if method_sym.to_s =~ /=$/
          @persona_needs_saving = true
        end
        self.persona.send(method_sym, *arguments)
      else
        super
      end
    else
      if self.persona_class && self.persona_class.new.respond_to?(method_sym)
        if method_sym.to_s =~ /=$/
          @persona_hash[method_sym.to_s.chomp("=").to_sym] = arguments.first
        else
          @persona_hash[method_sym]
        end
      else
        super
      end
    end
  end

  def set_flags
    @persona_needs_saving = false
    @persona_hash = {}
  end
  
  def create_persona
    unless self.persona || @persona_class == Vanillagrouppersona
      #
      #  Use the bang version, so if creation of the Persona fails
      #  then the error will propagate back up.
      #
      begin
        self.persona = @persona_class.create!(@persona_hash)
      rescue
        errors[:base] << "Persona: #{$!.to_s}"
        raise $!
      end
    end
  end

  def update_persona
    if self.persona
      if @persona_needs_saving
        begin
          self.persona.save!
          @persona_needs_saving = false
        rescue
          errors[:base] << "Persona: #{$!.to_s}"
          raise $!
        end
      end
    end
  end

#
#================================================================
#
#  Everything after this point is to do with managing membership
#  of the set, rather than getting it to fit in with Rails and
#  doing dynamic programming for personae.
#
#================================================================
#

  #
  #  Item can be any kind of entity, or an element.
  #
  def add_member(item, as_of = nil)
    Rails.logger.info("Entering add_member for #{item.name}")
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    as_of ||= Date.today
    if as_of < self.starts_on
      as_of = self.starts_on
    end
    #
    #  Is this item already an explicit (as opposed to recursive) member
    #  of this group.  Inclusive or exclusive?
    #
    existing_membership = memberships.active_on(as_of).detect {|m|
      m.element_id == element.id
    }
    if existing_membership
      Rails.logger.info("Found existing membership.")
      if existing_membership.inverse
        #
        #  Currently explicitly excluded from the group at this date.
        #  Terminate this exclusion and add an inclusion.  If the exclusion
        #  actually starts on the indicated date then delete it entirely.
        #  otherwise terminate it the day before.
        #
        if existing_membership.starts_on == as_of
          existing_membership.destroy
        else
          existing_membership.ends_on = as_of - 1
          existing_membership.save
        end
        membership = Membership.new
        membership.group = self
        membership.element = element
        membership.starts_on = as_of
        membership.inverse = false
        membership.save!
      else
        #
        #  Already an explicit member.  Do nothing.
        #
      end
    else
      Rails.logger.info("No existing membership.")
      #
      #  No existing membership record.  Create one.
      #
      membership = Membership.new
      membership.group = self
      membership.element = element
      membership.starts_on = as_of
      membership.inverse = false
      membership.save!
      Rails.logger.info("Created new membership record.")
    end
  end

  #
  #  Stop something being a member of a set, by default as of today.
  #  Note that the database records hold the first and last days on
  #  which the item is considered to be a member - that is, they specify
  #  the dates on which an item *was* a member of the set, but if a user
  #  specifies that someone should be removed from a set today, then he would
  #  usually expect the change to be apparent immediately.  We therefore
  #  set the last day of membership to be the day before the date passed to
  #  this function.
  #
  #  Calling this function for an item which is not an explicit member
  #  of this group will do nothing.
  #
  def remove_member(item, as_of = nil)
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    as_of ||= Date.today
    #
    #  Is this item already an explicit (as opposed to recursive) member
    #  of this group.  Inclusive or exclusive?
    #
    existing_membership = memberships.active_on(as_of).detect {|m|
      m.element_id == element.id && !m.inverse
    }
    if existing_membership
      #
      #  The item does indeed seem to be a member of the group on the
      #  specified day.  Two possibilities:
      #
      #  1) The membership starts on that day.  Remove it entirely.
      #     This has the convenient side effect that if someone is added
      #     to a group by accident and then immediately removed, the
      #     membership vanishes without trace.
      #
      #  2) The membership starts earlier than the specified day.  Mark
      #     it as ending on the day before the specified day.
      #
      if existing_membership.starts_on == as_of
        existing_membership.destroy
      else
        existing_membership.ends_on = as_of - 1
        existing_membership.save
      end
    end
  end

  #
  #  Item can be any kind of entity, or an element.
  #
  def add_outcast(item, as_of = nil)
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    as_of ||= Date.today
    #
    #  Is this item already an explicit (as opposed to recursive) member
    #  of this group.  Inclusive or exclusive?
    #
    existing_membership = memberships.active_on(as_of).detect {|m|
      m.element_id == element.id
    }
    if existing_membership
      if existing_membership.inverse
        #
        #  Already an explicit outcast.  Do nothing.
        #
      else
        #
        #  Currently explicitly included in the group at this date.
        #  Terminate this inclusion and add an exclusion.  If the inclusion
        #  actually starts on the indicated date then delete it entirely.
        #  otherwise terminate it the day before.
        #
        if existing_membership.starts_on == as_of
          existing_membership.destroy
        else
          existing_membership.ends_on = as_of - 1
          existing_membership.save
        end
        membership = Membership.new
        membership.group = self
        membership.element = element
        membership.starts_on = as_of
        membership.inverse = true
        membership.save
      end
    else
      #
      #  No existing membership record.  Create one.
      #
      membership = Membership.new
      membership.group = self
      membership.element = element
      membership.starts_on = as_of
      membership.inverse = true
      membership.save
    end
  end

  def remove_outcast(item, as_of = nil)
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    as_of ||= Date.today
    #
    #  Is this item already an explicit (as opposed to recursive) outcast
    #  of this group.
    #
    existing_membership = memberships.active_on(as_of).detect {|m|
      m.element_id == element.id && m.inverse
    }
    if existing_membership
      #
      #  The item does indeed seem to be an outcast of the group on the
      #  specified day.  Two possibilities:
      #
      #  1) The membership starts on that day.  Remove it entirely.
      #     This has the convenient side effect that if someone is added
      #     to a group by accident and then immediately removed, the
      #     membership vanishes without trace.
      #
      #  2) The membership starts earlier than the specified day.  Mark
      #     it as ending on the day before the specified day.
      #
      if existing_membership.starts_on == as_of
        existing_membership.destroy
      else
        existing_membership.ends_on = as_of - 1
        existing_membership.save
      end
    end
  end

  #
  # Returns a list of all the atomic members of this group on the indicated
  # date (see below for processing if no date given).  Recurses down through
  # nested groups (unless asked not to) and takes account of inverse
  # memberships.
  #
  # If no explicit date is given, then we use today's date, provided that
  # falls within the range of dates of validity of the group.  If it falls
  # outside that range then we use either the date of creation of the
  # group (if the group is in the future) or the last date of the group
  # (if it's in the past).  This is because, if someone requests the
  # membership of a historic group ("Who was in the group of boys who went
  # skiing last term?") then they don't expect to be told "no-one", just
  # because the group no longer exists.
  #
  # However, I get steadily more concerned about whether that particular
  # bit of logic should be here.  Perhaps it should be in the presentation
  # code and the code here should confine itself to setting given_date
  # to Date.today, and then returning [] if it's out of range.
  #
  #  I've come to a conclusion - it should *not* be here.  The results
  #  are just too surprising.  It's up to presentation code to specify
  #  a date if it wants to look at the membership of a group some time
  #  in the past, even if the group now no longer exists.  If you're
  #  doing a historic view of some sort, specify the date.
  #
  #  See also the helper method final_members
  #
  #  And after some further thought and experience, I've changed my mind
  #  The logic now is that if you specify a date, that date takes
  #  effect.  If you *don't* specify a date you get today's date, or the
  #  first or last date of the groups existence if its existence period
  #  does not include today.
  #
  #  Note that this method returns *entities* - of whatever type.
  #
  def members(given_date     = nil,
              recurse        = true,
              exclude_groups = false,
              seen           = [])
    unless given_date
      given_date = Date.today
      if given_date < self.starts_on
        given_date = self.starts_on
      elsif self.ends_on != nil && given_date > self.ends_on
        given_date = self.ends_on
      end
    end
    return [] unless active_on(given_date)
    return [] if seen.include?(self.id)
    if recurse 
      seen << self.id
      active_memberships = self.memberships.active_on(given_date)
      excludes, includes = active_memberships.partition {|am| am.inverse}
      group_includes, atomic_includes =
        includes.partition {|m| m.element.entity.class == Group}
      group_excludes, atomic_excludes =
        excludes.partition {|m| m.element.entity.class == Group}
      #
      #  Now build a list of includes and excludes, and subtract one from
      #  the other.
      #
      included_by_group =
        group_includes.collect {|membership|
          (exclude_groups ? [] : [membership.element]) +
          membership.element.entity.members(membership.as_at ?
                                            membership.as_at :
                                            given_date,
                                            true,
                                            exclude_groups,
                                            seen)
        }.flatten.uniq
      excluded_by_group =
        group_excludes.collect {|membership|
          (exclude_groups ? [] : [membership.element]) +
          membership.element.entity.members(membership.as_at ?
                                            membership.as_at :
                                            given_date,
                                            true,
                                            exclude_groups,
                                            seen)
        }.flatten.uniq
      included_atomically =
        atomic_includes.collect {|membership| membership.element.entity}
      excluded_atomically =
        atomic_excludes.collect {|membership| membership.element.entity}
      #
      #  See the Zim documentation for Xronos for an explanation of
      #  these priorities.
      #
      (((included_by_group - excluded_by_group) + included_atomically) - excluded_atomically).uniq
    else
      #
      #  If we're not recursing the processing is exceedingly simple.
      #  You can't have two membership records for the same entity so
      #  all we need to do is return a list of all the things positively
      #  included.  If an inclusion record exists there can't be a
      #  corresponding exclusion record, so we don't need to look
      #  at the exclusion records.
      #
      self.memberships.active_on(given_date).inclusions.select {|m|
        m.element.entity.class != Group || !exclude_groups
      }.collect {|m| m.element.entity}
    end
  end

  #
  #  Just return the membership records which give us explicit inclusions
  #  on the indicated date.
  #
  def inclusions_on(given_date = nil)
    unless given_date
      given_date = Date.today
      if given_date < self.starts_on
        given_date = self.starts_on
      elsif self.ends_on != nil && given_date > self.ends_on
        given_date = self.ends_on
      end
    end
    return [] unless active_on(given_date)
    self.memberships.active_on(given_date).inclusions.includes(:element)
  end

  #
  #  Like members, but if the date falls outside the lifetime of the group
  #  then list the members just before the group ended.
  #
  def final_members(given_date = nil, recurse = true, exclude_groups = false)
    given_date ||= Date.today
    if given_date < self.starts_on
      given_date = self.starts_on
    elsif self.ends_on != nil && given_date > self.ends_on
      given_date = self.ends_on
    end
    members(given_date, recurse, exclude_groups)
  end

  #
  #  A bit like the members, method above, but provides a list of entities
  #  which are explicitly excluded from membership of this group.
  #
  #  Again, we return *entities*, not elements.
  #
  def outcasts(given_date = nil, recurse = true)
    given_date ||= Date.today
    if active_on(given_date)
      exclusions = self.memberships.exclusions.active_on(given_date)
      excluded_elements =
        exclusions.collect { |membership|
          if membership.element.entity.class == Group && recurse
            #  Note that we call members here, and not outcasts.
            [membership.element.entity] +
            membership.element.entity.members(
              membership.as_at ?
              membership.as_at :
              given_date)
          else
            membership.element.entity
          end
        }.flatten.uniq
    else
      []
    end
  end

  #
  #  Start with this group and compile a list of all parent groups which
  #  would claim membership of the indicated element on the indicated date,
  #  by way of this group being a member or sub-member of them.
  #
  #  Take into account group validity dates, membership validity dates,
  #  exclusions and as_at dates.
  #
  #  Note that this group has to check itself to ensure the indicated element
  #  is actually a member, and should include itself in the list of groups
  #  returned if it is.  It is also possible that the indicated element
  #  is not a member of this group on the indicated date, but is a member
  #  of some of its parent groups, by dint of having once been a member
  #  of this group.
  #
  #  Note that this method is intended for internal use by the group
  #  processing code and so returns an array of "Group" objects, and not
  #  the overlying visible groups.
  #
  #
  #  Special processing is need to protect ourselves from someone having
  #  set up a circular heirarchy.
  #
  def parents_for(element, given_date, seen = [])
    result = self.element.memberships.inclusions.collect {|membership|
      if seen.include?(membership.group_id)
        []
      else
        seen << membership.group_id
        membership.group.parents_for(element, given_date, seen)
      end
    }.flatten
    if self.member?(element, given_date)
      result = result + [self]
    end
    result.uniq
  end

  # Decide whether the indicated entity is a member of the group.
  def member?(item, given_date = nil, recurse = true)
    if item.instance_of?(Element)
      entity = item.entity
    else
      entity = item
    end
    self.members(given_date, recurse).include?(entity)
  end

  def outcast?(item, given_date = nil, recurse = true)
    if item.instance_of?(Element)
      entity = item.entity
    else
      entity = item
    end
    self.outcasts(given_date, recurse).include?(entity)
  end

  def active_on(date)
    self.starts_on <= date &&
    (self.ends_on == nil || self.ends_on >= date)
  end

  #
  #  A bit of a maintenance method.  Used to adjust the start date
  #  of a group (and any of its membership records) to a new date.
  #
  def set_start_date(new_starts_on)
    old_starts_on = self.starts_on
    if old_starts_on != new_starts_on
      self.starts_on = new_starts_on
      if self.ends_on != nil &&
         self.ends_on < self.starts_on
        self.ends_on = self.starts_on
      end
      self.save!
    end
    #
    #  Need to check our membership records, even if we haven't changed
    #  our start date.  It might be there was already a rogue (starts
    #  too early) one there.
    #
    self.memberships.each do |membership|
      membership.set_start_date(old_starts_on, new_starts_on)
    end
  end

  #
  #  Note that we are passed the date on which the deletion occurs, but
  #  we store the active dates of the group, inclusive.  Thus we set the
  #  ends_on date to the day before we have been given.  That's the last
  #  date on which the group was active.
  #
  #  If the calling code specifies an end date which is the same as
  #  the start date (or earlier) then things are a bit weird.  It's a
  #  situation which shouldn't really arise, but if it does then the
  #  chances are we really weren't ever wanted at all.
  #
  def ceases_existence(date)
    if self.active_on(date)
      if self.starts_on == date
        #
        #  Our persona should go automatically.
        #
        self.destroy!
      else
        self.members(date, false, false).each do |member|
          self.remove_member(member, date)
        end
        self.ends_on = date - 1.day
        self.save!
      end
    end
  end

  #
  #  A maintenance method to move existing stuff from visible groups.
  #
#  def self.grab_fields_from_visible
#    copied_count = 0
#    Group.all.each do |g|
#      if g.visible_group
#        g.name    = g.visible_group.name
#        g.era_id  = g.visible_group.era_id
#        g.current = g.visible_group.current
#        g.save!
#        copied_count += 1
#      else
#        puts "Group #{g.id} has no visible group."
#      end
#    end
#    puts "Copied #{copied_count} sets of details."
#    nil
#  end

#  def self.grab_element_records
#    grabbed_count = 0
#    Group.all.each do |g|
#      if g.visible_group
#        element = g.visible_group.element
#        element.entity = g
#        element.save!
#        grabbed_count += 1
#      else
#        puts "Group #{g.id} has no visible group."
#      end
#    end
#    puts "Moved #{grabbed_count} element records."
#    nil
#  end

#  def self.move_to_personae
#    moved_count = 0
#    failed_count = 0
#    Group.all.each do |g|
#      if g.persona_type == "Tutorgroup"
#        g.persona_type = "Tutorgrouppersona"
#        g.save!
#        moved_count += 1
#      elsif g.persona_type == "Teachinggroup"
#        g.persona_type = "Teachinggrouppersona"
#        g.save!
#        moved_count += 1
#      else
#        failed_count += 1
#      end
#    end
#    puts "Moved #{moved_count} groups to personae."
#    puts "Couldn't move #{failed_count} groups."
#    nil
#  end

  private

  def not_backwards
    if self.ends_on &&
       self.starts_on &&
       self.ends_on < self.starts_on
      errors.add(:ends_on, "(#{self.ends_on.to_s}) must be no earlier than start date (#{self.starts_on.to_s}). Group #{self.id}")
    end
  end

  def persona_specified
    if !self.id && !self.persona && self.persona_class == nil
      errors.add(:base, "A persona class must be specified")
    end
  end

end
