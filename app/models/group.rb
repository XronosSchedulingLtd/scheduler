class Group < ActiveRecord::Base
  belongs_to :visible_group, :polymorphic => true
  has_many :memberships, :dependent => :destroy

  validates :starts_on, :presence => true

  validate :not_backwards

  #
  #  Item can be any kind of entity, or an element.
  #
  def add_member(item, as_of = nil)
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
      #logger.info("Found existing membership.")
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
      #logger.info("No existing membership.")
      #
      #  No existing membership record.  Create one.
      #
      membership = Membership.new
      membership.group = self
      membership.element = element
      membership.starts_on = as_of
      membership.inverse = false
      membership.save!
      #logger.info("Created new membership record.")
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
  def members(given_date = nil, recurse = true, exclude_groups = false)
    if given_date
      # We have been given an explicit date.  If that's outside the range
      # of validity of the group then our effective membership is nobody.
      return [] unless active_on(given_date)
    else
      given_date = Date.today
      unless active_on(given_date)
        if given_date < self.starts_on
          given_date = self.starts_on
        else
          # self.ends_on can't be nil because we have established
          # that given_date falls after it.
          given_date = self.ends_on
        end
      end
    end
    if recurse
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
                                            exclude_groups)
        }.flatten.uniq
      excluded_by_group =
        group_excludes.collect {|membership|
          (exclude_groups ? [] : [membership.element]) +
          membership.element.entity.members(membership.as_at ?
                                            membership.as_at :
                                            given_date,
                                            true,
                                            exclude_groups)
        }.flatten.uniq
      included_atomically =
        atomic_includes.collect {|membership| membership.element}
      excluded_atomically =
        atomic_excludes.collect {|membership| membership.element}
      #
      #  See the Zim documentation for an explanation of these priorities.
      #
      ((included_by_group - excluded_by_group) + included_atomically) - excluded_atomically
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
      }.collect {|m| m.element}
    end
  end

  #
  #  A bit like the members, method above, but provides a list of elements
  #  which are explicitly excluded from membership of this group.
  #
  def outcasts(given_date = nil, recurse = true)
    given_date ||= Date.today
    if active_on(given_date)
      exclusions = self.memberships.exclusions.active_on(given_date)
      excluded_elements =
        exclusions.collect { |membership|
          if membership.element.entity.class == Group
            if recurse
              #  Note that we call members here, and not outcasts.
              [membership.element] +
              membership.element.entity.members(
                membership.as_at ?
                membership.as_at :
                given_date)
            else
              membership.element
            end
          else
            membership.element
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
  def parents_for(element, given_date)
    result = self.element.memberships.inclusions.collect {|membership|
      membership.group.parents_for(element, given_date)
    }.flatten
    if self.member?(element, given_date)
      result = result + [self]
    end
    result.uniq
  end

  # Decide whether the indicated element is a member of the group.
  def member?(item, given_date = nil, recurse = true)
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    self.members(given_date, recurse).include?(element)
  end

  def outcast?(item, given_date = nil, recurse = true)
    if item.instance_of?(Element)
      element = item
    else
      element = item.element
    end
    self.outcasts(given_date, recurse).include?(element)
  end

  def active_on(date)
    self.starts_on <= date &&
    (self.ends_on == nil || self.ends_on >= date)
  end

  private

  def not_backwards
    if ends_on &&
       starts_on &&
       ends_on < starts_on
      errors.add(:ends_on, "must be no earlier than start date")
    end
  end

end
