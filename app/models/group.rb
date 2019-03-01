# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class Group < ActiveRecord::Base
  belongs_to :era
  belongs_to :owner, :class_name => :User
  belongs_to :persona, :polymorphic => true, :dependent => :destroy
  belongs_to :datasource
  #
  #  Since we can't do joins on polymorphic relationships, we need
  #  explicit ones too.  These should really be defined elsewhere, but
  #  I'm not sure how just yet.
  #
  belongs_to :tutorgrouppersona, -> { where(groups: {persona_type: 'Tutorgrouppersona'}).includes(:group) }, foreign_key: :persona_id
  belongs_to :teachinggrouppersona, -> { where(groups: {persona_type: 'Teachinggrouppersona'}).includes(:group) }, foreign_key: :persona_id
  belongs_to :taggrouppersona, -> { where(groups: {persona_type: 'Taggrouppersona'}).includes(:group) }, foreign_key: :persona_id
  belongs_to :otherhalfgrouppersona, -> { where(groups: {persona_type: 'Otherhalfgrouppersona'}).includes(:group) }, foreign_key: :persona_id

  has_many :memberships, :dependent => :destroy

  validates :starts_on, presence: true
  validates :name,      presence: true
  validates :era,       presence: true

  validate :not_backwards
  validate :persona_specified

  scope :current, -> { where(current: true) }
  scope :historical, -> { where.not(current: true) }

  scope :resourcegroups, -> { where(persona_type: 'Resourcegrouppersona') }
  scope :tutorgroups, -> { where(persona_type: 'Tutorgrouppersona') }
  scope :teachinggroups, -> { where(persona_type: 'Teachinggrouppersona') }
  scope :taggroups, -> { where(persona_type: 'Taggrouppersona') }
  scope :otherhalfgroups, -> { where(persona_type: 'Otherhalfgrouppersona') }
  scope :vanillagroups, -> { where(persona_type: nil) }
  scope :owned, -> { where.not(owner_id: nil) }

  scope :ofera, ->(era) { where(era_id: era.id) }

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
  scope :has_owner, -> { where.not(owner_id: nil) }

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

  before_create    :create_persona
  after_save       :update_persona

  attr_reader :persona_class

  DISPLAY_COLUMNS = [:members, :direct_groups, :indirect_groups]

  include Elemental

  self.per_page = 15

  def persona_class=(new_class)
    if new_class.instance_of?(String)
      case new_class
      when "Resourcegrouppersona"
        @persona_class = Resourcegrouppersona
      else
        @persona_class = Vanillagrouppersona
      end
    else
      @persona_class = new_class
    end
  end

  def element_name
    name
  end

  def description(capitalize = true)
    "#{self.type(capitalize)} group"
  end

  def description_line
    case self.type
    when "Teaching"
      text = "A teaching set"
      if self.persona.staffs.size > 0
        text = text + " - taught by #{self.persona.staffs.collect {|s| s.initials}.join(",")} -"
      end
    when "Tutor"
      text = "A #{Setting.tutorgroups_name.downcase} - #{Setting.tutor_name.downcase}, #{self.persona.staff.name} -"
    when "Otherhalf"
      text = "An Other Half group"
    when "Tag"
      text = "A custom group"
    when "Vanilla"
      text = "A general group"
    else
      text = "A group"
    end
    text = text + " with #{self.members.count} members."
  end

  def more_type_info
    " (#{description})"
  end

  def show_historic_panels?
    false
  end

  def extra_panels?
    true
  end

  def add_directly?
    if self.persona && self.persona.respond_to?(:add_directly?)
      self.persona.add_directly?
    else
      true
    end
  end

  def can_have_requests?
    if self.persona && self.persona.respond_to?(:can_have_requests?)
      self.persona.can_have_requests?
    else
      false
    end
  end

  def column_of(mwds, title)
    column = DisplayPanel::GeneralDisplayColumn.new(title)
    mwds.sort.each do |gmwd|
      entry =
        DisplayPanel::GDCEntry.new(
          "From #{gmwd.start_date.to_formatted_s(:dmy)}#{
            if gmwd.end_date
              " to #{gmwd.end_date.to_formatted_s(:dmy)}"
            else
              ""
            end }")
      gmwd.collect {|mwd| mwd.membership.element}.sort.each do |element|
        entry << DisplayPanel::GDCRow.for_member(element.entity)
      end
      column << entry
    end
    column
  end


  def extra_panels(index)
    panel = DisplayPanel.new(index, "Memberships", false)
    mwds = Membership::MWD_Set.new(nil)   # Mustn't call exclusion processing
    self.memberships.each do |m|
      mwds.add_mwd(m, m.starts_on, m.ends_on, 1)
    end
    mwds.group_by_duration
    #
    panel.add_general_column(
      column_of(mwds.current_grouped_mwds,
                "Current"))
    panel.add_general_column(
      column_of(mwds.past_grouped_mwds,
                "Past"))
    panel.add_general_column(
      column_of(mwds.future_grouped_mwds,
                "Future"))
    [panel]
  end

  def active
    true
  end

  def entitys_owner_id
    #
    #  If we are flagged as being a public group, then we pretend not
    #  to have an owner_id.  This will then mean that our element appears
    #  in public searches.
    #
    self.make_public ? nil : self.owner_id
  end

  def owner_initials
    if self.owner
      self.owner.initials
    else
      "SYS"
    end
  end

  def public?
    self.make_public || self.owner_id == nil
  end

  def membership_empty?
    self.members(nil, false).empty?
  end

  #
  #  Returns this group's atomic membership if relevant - that is, if
  #  this group itself contains any other groups.  Returns nil otherwise.
  #
  def atomic_membership
    if self.inclusions_on.select {|m| m.element.entity_type == "Group"}.size > 0
      self.members(nil, true, true)
    else
      nil
    end
  end

  #
  #  What type is this group?
  #
  #  Or will this group be?  We need to cope when we are freshly
  #  created and not yet saved to the database.
  #
  def type(capitalize = true)
    persona_class_name = nil
    if self.persona_type
      persona_class_name = self.persona_type
    elsif self.persona_class
      persona_class_name = self.persona_class.to_s
    end
    if persona_class_name
      result = persona_class_name.chomp("grouppersona")
    else
      result = "Vanilla"
    end
    if capitalize
      result
    else
      result.downcase
    end
  end

  #
  #  Where to find a partial to display general information about this
  #  elemental item.
  #
  def general_partial
    "groups/general"
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
      if self.persona_class &&
         (temporary_persona = self.persona_class.new).respond_to?(method_sym)
        if method_sym.to_s =~ /=$/
          @persona_hash[method_sym.to_s.chomp("=").to_sym] = arguments.first
        else
          @persona_hash[method_sym]
          #
          #  The calling code might quite like to have its query answered
          #  now.  All we can provide is a default value, but it might
          #  be useful.
          #
          temporary_persona.send(method_sym, *arguments)
        end
      else
        super
      end
    end
  end

  def respond_to?(method_sym, include_private = false)
    if super
      true
    else
      #
      #  Do we have a persona which can do the necessary for us?
      #
      if self.persona
        self.persona.respond_to?(method_sym, include_private)
      else
        #
        #  Would it be able to handle it once it exists?
        #
        if self.persona_class &&
           self.persona_class.new.respond_to?(method_sym, include_private)
          true
        else
          false
        end
      end
    end
  end

  def initialize(*args)
    @persona_needs_saving = false
    @persona_hash = {}
    super
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
  #  This really depends on the persona.
  #
  def user_editable?
    if self.persona
      self.persona.user_editable?
    else
      true
    end
  end

  #
  #  Export the immediate membership of this group as a CSV file.
  #  If there are any explicit exclusions, report those too.
  #
  def to_csv
    result = [self.name].to_csv
    exclusions, inclusions = self.memberships_on.partition{|m| m.inverse}
    inclusions.collect {|i| i.element}.sort.each do |element|
      result += ["", element.name].to_csv
    end
    unless exclusions.empty?
      result += ["but excluding"].to_csv
      exclusions.collect {|e| e.element}.sort.each do |element|
        result += ["", element.name].to_csv
      end
    end
    result
  end

  #
  #  Clone this group, giving the new group exactly the same membership
  #  in the same way, but everything starts today.
  #
  #  Note that this currently works only for Vanilla groups.
  #
  #  Has to save to the database in order to clone the membership.
  #
  def do_clone
    if self.persona_type
      raise "Cloning is supported only for Vanilla groups."
    else
      new_group = Vanillagroup.new
      new_group.starts_on   = Date.today
      new_group.ends_on     = nil
      new_group.name        = "Copy of #{self.name}"
      new_group.era         = self.era
      new_group.current     = self.current
      new_group.owner       = self.owner
      new_group.make_public = self.make_public
      new_group.save!
      new_group.reload
      #
      #  And now for the membership.
      #
      self.memberships_on.each do |membership|
        new_membership = Membership.new
        new_membership.group     = new_group
        new_membership.element   = membership.element
        new_membership.starts_on = Date.today
        new_membership.ends_on   = nil
        new_membership.inverse   = membership.inverse
        new_membership.save!
      end
      #
      #  Finished.
      #
      new_group
    end
  end

  #
  #  Flatten this group.  That is, convert any memberships which are
  #  currently achieved via groups to direct memberships.  The final
  #  atomic membership will end up the same as it is today, but all
  #  the intervening groups will be gone.
  #
  def flatten
    original_membership = self.members(nil, true, true)
    #
    #  Get rid of any memberships of this group which directly reference
    #  groups, and any exclusions.
    #
    today = Date.today
    self.memberships_on.
         select {|m| m.inverse ||
                     m.element.entity_type == "Group"}.each do |membership|
      if membership.starts_on == today
        membership.destroy
      else
        membership.ends_on = today - 1.day
        membership.save
      end
    end
    #
    #  And now we need to add back in anyone who has been lost.
    #
    self.reload
    resulting_membership = self.members(nil, true, true)
    (original_membership - resulting_membership).each do |entity|
      self.add_member(entity)
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
  #  Returns true if the member was added, and false if not.
  #  Note that, if the entity is already a member then false
  #  will be returned.  false means "nothing changed".
  #
  def add_member(item, as_of = nil)
    # Rails.logger.info("Entering add_member for #{item.name}")
    if item.nil?
      Rails.logger.info('Nil item passed to add_member')
      return false
    end
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
      if element == nil
        Rails.logger.info("Attempt to add inactive entity to group.")
        return false
      end
    end
    as_of ||= Date.today
    if as_of < self.starts_on
      as_of = self.starts_on
    end
    #
    #  Can't have memberships starting after the life of the group
    #  has ended.
    #
    if self.ends_on && as_of > self.ends_on
      Rails.logger.info("Attempt to add entity to group after it has ended.")
      return false
    end
    result = false
    #
    #  Is this item already an explicit (as opposed to recursive) member
    #  of this group.  Inclusive or exclusive?
    #
    existing_membership = memberships.active_on(as_of).detect {|m|
      m.element_id == element.id
    }
    if existing_membership
      # Rails.logger.info("Found existing membership.")
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
        #
        #  If the group has an end date, the membership should have the
        #  same end date.  If it doesn't then the membership shouldn't.
        #  This next line achieves both of these.
        #
        membership.ends_on   = self.ends_on
        membership.inverse = false
        membership.save!
        result = true
      else
        #
        #  Already an explicit member.  Do nothing.
        #
      end
    else
      # Rails.logger.info("No existing membership.")
      #
      #  No existing membership record for the specified date.
      #
      #  It is however possible that there is a future membership record,
      #  which would clash with any new one which we tried to create.
      #  Check for that too.
      #
      #  TODO: Also check for future exclusions.
      #
      future_memberships =
        memberships.starts_after(as_of).by_element(element).inclusions
      if future_memberships.size == 0
        membership = Membership.new
        membership.group = self
        membership.element = element
        membership.starts_on = as_of
        membership.ends_on   = self.ends_on
        membership.inverse = false
        membership.save!
        # Rails.logger.info("Created new membership record.")
      else
        # Rails.logger.info("Adjusting membership start back in time.")
        selected = future_memberships.sort_by {|m| m.starts_on}.first
        # Rails.logger.info("From #{selected.starts_on} to #{as_of}")
        selected.starts_on = as_of
        selected.save!
      end
      result = true
    end
    result
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
      if element == nil
        Rails.logger.info("Attempt to remove inactive entity from group.")
        return
      end
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
    Rails.logger.debug("Attempting to add an outcast.")
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
        membership.ends_on   = self.ends_on
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
      membership.ends_on   = self.ends_on
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
      active_memberships =
        self.memberships.
             includes(element: :entity).
             active_on(given_date)
      excludes, includes = active_memberships.partition {|am| am.inverse}
      group_includes, atomic_includes =
        includes.partition {|m| m.element.entity_type == "Group"}
      group_excludes, atomic_excludes =
        excludes.partition {|m| m.element.entity_type == "Group"}
      #
      #  Now build a list of includes and excludes, and subtract one from
      #  the other.
      #
      included_by_group =
        group_includes.collect {|membership|
          (exclude_groups ? [] : [membership.element.entity]) +
          membership.element.entity.members(given_date,
                                            true,
                                            exclude_groups,
                                            seen)
        }.flatten.uniq
      excluded_by_group =
        group_excludes.collect {|membership|
          (exclude_groups ? [] : [membership.element.entity]) +
          membership.element.entity.members(given_date,
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
      self.memberships.
           includes(element: :entity).
           active_on(given_date).
           inclusions.
           select {|m|
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
  #  And similarly, but for all membership records.
  #
  def memberships_on(given_date = nil)
    unless given_date
      given_date = Date.today
      if given_date < self.starts_on
        given_date = self.starts_on
      elsif self.ends_on != nil && given_date > self.ends_on
        given_date = self.ends_on
      end
    end
    return [] unless active_on(given_date)
    self.memberships.active_on(given_date).includes(:element)
  end

  #
  #  Returns an array of all the groups which influence the membership of
  #  this group on the indicated day.  Works recursively.
  #
  def influencing_groups(given_date = nil, seen = [])
    #
    #  Avoid a loop.
    #
    if seen.include?(self.id)
      []
    else
      seen << self.id
      group_members =
        self.memberships_on(given_date).
             select {|m| m.element.entity_type == "Group"}.
             collect {|m| m.element.entity}
      [self] +
      (group_members.collect {|group|
         group.influencing_groups(given_date, seen)}).flatten.sort
    end
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
            membership.element.entity.members(given_date)
          else
            membership.element.entity
          end
        }.flatten.uniq
    else
      []
    end
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
  def ceases_existence(date = nil)
    date ||= Date.today
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
        if self.ends_on < Date.today
          #
          #  By default, this method uses today as the date to end,
          #  and sets the ends_on to 1 day less, and so we set current
          #  to false.
          #
          #  However, it is possible to call this method with a date in
          #  the future.  In that case, we don't want it to become
          #  immediately "not current".  The overnight cron job will
          #  do the necessary at the time.
          #
          self.current = false
        end
        self.save!
      end
    else
      if self.starts_on > date
        #
        #  Being asked to delete ourselves before we've even started.
        #
        self.destroy!
      elsif self.current
        #
        #  We have established that we are outside our dates of
        #  existence (the active_on() call above) and yet we
        #  are flagged as current.  This happens when a group
        #  was created with an ends_on date, and we've just rolled
        #  past it.  A batch job runs nightly to adjust these things,
        #  but we can fix it here too.
        #
        self.current = false
        self.save!
      end
    end
  end

  #
  #  Bring back a group which has previously been marked as over and
  #  done with.
  #
  #  Could add a "with_members" parameter, which would re-instate
  #  the members who were members on the day the group ended.  Not
  #  needed for now though - the group comes back as empty.
  #
  def reincarnate(with_members = false)
    if self.ends_on
      old_ends_on = self.ends_on
      self.ends_on = nil
      self.current = true
      self.save!
      if with_members
        self.reload
        #
        #  Anything which was a member on the previous last day of
        #  existence gets to be a member again.  Any exclusions get
        #  re-instated too.
        #
        self.memberships.
             active_on(old_ends_on).
             each do |m|
          m.ends_on = nil
          m.save!
        end
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

  #
  #  Another maintenance method to move private groups to the perpetual
  #  era.
  #
  def self.move_to_perpetual
    count = 0
    Group.where("owner_id IS NOT NULL").each do |group|
      group.era = Setting.perpetual_era
      group.save!
      count += 1
    end
    puts "Moved #{count} groups to the perpetual era."
    nil
  end

  #
  #  A method to take groups which currently have no owner and give them
  #  to a user, marking them as public as they go.
  #
  def give_to(user)
    self.owner = user
    self.make_public = true
    self.save
  end

  def self.managed_groups_to(user)
    messages = []
    ["Senior Leadership Team",
     "Academic Committee",
     "Communications Committee",
     "Environment Committee",
     "Food Committee",
     "Other Half Committee",
     "Pastoral Committee",
     "Societies and Services Committee",
     "Works Committee",
     "Health and Safety Committee",
     "Sports Committee",
     "Housemasters",
     "HoDs"].each do |group_name|
      g = Group.find_by(name: group_name)
      if g
        if g.owner
          messages << "Group #{group_name} is already owned by #{g.owner.name}."
        else
          g.give_to(user)
        end
      else
        messages << "Unable to find #{group_name}."
      end
    end
    messages.each do |m|
      puts m
    end
    nil
  end

  #
  #  A pair of maintenance methods to go through all groups, making sure
  #  none of the memberships outlasts its parent group.
  #
  def trim_memberships
    if self.ends_on
      trimmed = 0
      self.memberships.each do |m|
        if m.ends_on == nil ||
           m.ends_on > self.ends_on
          m.ends_on = self.ends_on
          m.save!
          trimmed += 1
        end
      end
      trimmed
    else
      0
    end
  end

  def self.trim_memberships
    trimmed = 0
    Group.all.each do |group|
      trimmed += group.trim_memberships
    end
    puts "#{trimmed} memberships trimmed."
    nil
  end

  #
  #  Groups can move into and out of being current.  They can be created
  #  with an end date, and thus cease to be current, or they can be created
  #  in advance and only become current when we reach their start date.
  #
  #  This method should be run once a day (by means of a rake task) to update
  #  the "current" flag as appropriate.
  #
  def self.adjust_currency_flags(ondate = Date.today)
    Group.all.each do |group|
      if group.active_on(ondate)
        unless group.current
          Rails.logger.info("Setting group #{group.name} to current.")
          group.current = true
          group.save
        end
      else
        if group.current
          Rails.logger.info("Setting group #{group.name} to no longer current.")
          group.current = false
          group.save
        end
      end
    end
    nil
  end

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
