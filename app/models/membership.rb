# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Membership < ActiveRecord::Base

  class MembershipWithDuration

    attr_reader :membership, :start_date, :end_date, :level

    def initialize(membership, start_date, end_date, level)
      @membership = membership
      @start_date = start_date
      @end_date   = end_date
      @level      = level
    end

    def to_partial_path
      "membershipwd"
    end

    def <=>(other)
      #
      #  We sort first by start date, then by end date.
      #
      if self.start_date == other.start_date
        if self.end_date == other.end_date
          0
        else
          if self.end_date
            if other.end_date
              self.end_date <=> other.end_date
            else
              #
              #  He doesn't have an end date.  We come first.
              #
              -1
            end
          else
            #
            #  We don't have an end date so we come second.
            #
            1
          end
        end
      else
        if self.start_date
          if other.start_date
            self.start_date <=> other.start_date
          else
            1
          end
        else
          -1
        end
      end
    end

    def start_text
      if self.start_date
        start_date.strftime("%d/%m/%Y")
      else
        ""
      end
    end

    def end_text
      if self.end_date
        end_date.strftime("%d/%m/%Y")
      else
        ""
      end
    end

    def start_time_utc
      time = Time.zone.parse("00:00:00", self.start_date)
      time.utc.strftime("%Y-%m-%d %H:%M:%S")
    end

    def end_time_utc
      time = Time.zone.parse("00:00:00", self.end_date + 1.day)
      time.utc.strftime("%Y-%m-%d %H:%M:%S")
    end

    #
    #  Does this mwd overlap with another one?  Note that each must have
    #  a start date, but might not have an end date.
    #
    def overlaps(other)
      if self.end_date
        if other.end_date
          self.start_date <= other.end_date &&
          self.end_date >= other.start_date
        else
          self.end_date >= other.start_date
        end
      else
        if other.end_date
          self.start_date <= other.end_date
        else
          true
        end
      end
    end

    #
    #  Does our interval cover the whole of the other mwd's interval?
    #
    def encompasses(other)
      if self.end_date
        if other.end_date
          self.start_date <= other.start_date &&
          self.end_date >= other.end_date
        else
          false
        end
      else
        self.start_date <= other.start_date
      end
    end

    #
    #  Does our interval lie completely inside another's interval, leaving
    #  a bit over at each end?
    #
    def splits(other)
      if self.end_date
        self.start_date > other.start_date &&
        (other.end_date == nil || self.end_date < other.end_date)
      else
        false
      end
    end

    #
    #  Adjust the duration of our mwd to exclude the period indicated
    #  by the other.  We've already checked that the other doesn't
    #  split us, or completely encompass us.
    #
    def adjust_duration(other)
      if self.start_date < other.start_date
        @end_date = other.start_date - 1.day
      else
        if other.end_date == nil
          Rails.logger.debug("Error: other has no end_date.")
        else
          @start_date = other.end_date + 1.day
        end
      end
    end

    #
    #  We have already established that one of our mwds is going to split
    #  another. Do the split by adjusting our own end date and returning
    #  a new mwd for the other part.
    #
    def do_split(other)
      old_end_date = @end_date
      @end_date = other.start_date - 1.day
      MembershipWithDuration.new(@membership,
                                 other.end_date + 1.day,
                                 old_end_date,
                                 @level)
    end

  end

  #
  #  Class to store a set of MembershipWithDuration objects and manipulate
  #  them.
  #
  class MWD_Set

    attr_reader :grouped_mwds

    def initialize(client_element)
      @client_element = client_element
      @mwds = Array.new
      @mwds_by_element_id = Hash.new
      @grouped_mwds = Array.new
    end

    def add_mwd(membership, start_date, end_date, level)
#      Rails.logger.debug("Adding mwd")
      mwd = MembershipWithDuration.new(membership, start_date, end_date, level)
      @mwds << mwd
      if @mwds_by_element_id[membership.group.element.id]
        @mwds_by_element_id[membership.group.element.id] << mwd
      else
        @mwds_by_element_id[membership.group.element.id] = [mwd]
      end
#      Rails.logger.debug("Finished adding mwd")
    end

    #
    #  Handle any exclusions which there are in the set.
    #
    #  Note that it is possible to set up a deadly embrace of exclusions,
    #  in which case the result is undefined.  Just don't do it.
    #
    def process_exclusions
      to_destroy = Array.new
      new_mwds = Array.new
      @mwds.each do |mwd|
        mwd.membership.group.memberships.eager_load(:element).exclusions.each do |exclusion|
#        mwd.membership.group.memberships.exclusions.each do |exclusion|
#          Rails.logger.debug("Found an exclusion")
          #
          #  Need to remember to check against the original parent element
          #  as well as against our stored groups.
          #
          if exclusion.element.id == @client_element.id
            exclusion_mwds = [MembershipWithDuration.new(exclusion,
                                                         exclusion.starts_on,
                                                         exclusion.ends_on,
                                                         0)]
          else
            exclusion_mwds = @mwds_by_element_id[exclusion.element.id]
          end
          if exclusion_mwds
            exclusion_mwds.each do |exclusion_mwd|
              if exclusion_mwd.overlaps(mwd)
                #
                #  One of our entries is over-riding another one.  Need to
                #  adjust intelligently based on duration.  As a worst case,
                #  our entry might need splitting in two.
                #
                if exclusion_mwd.encompasses(mwd)
                  to_destroy << mwd
                else
                  #
                  #  Overlaps, but doesn't completely cover it.  We're going
                  #  to need to adjust our duration, and possibly even
                  #  split in two.
                  #
                  if exclusion_mwd.splits(mwd)
                    #
                    #  Hard case.
                    #
                    new_mwds << mwd.do_split(exclusion_mwd)
                  else
                    #
                    #  Simply need to adjust the duration of this mwd.
                    #
                    mwd.adjust_duration(exclusion_mwd)
                  end
                end
              end
            end
          end
        end
      end
      to_destroy.uniq.each do |mwd|
        mwd_array = @mwds_by_element_id[mwd.membership.group.element.id]
        if mwd_array
          mwd_array = mwd_array - [mwd]
        end
      end
      @mwds = (@mwds - to_destroy) + new_mwds
      new_mwds.each do |mwd|
        if @mwds_by_element_id[mwd.membership.group.element.id]
          @mwds_by_element_id[mwd.membership.group.element.id] << mwd
        else
          @mwds_by_element_id[mwd.membership.group.element.id] = [mwd]
        end
      end
    end

    #
    #  Take a collection of MembershipWithDurations and group them by duration.
    #  Any two with the same duration go in the same group.  Note that it
    #  is common for any given element to have many groups with exactly the
    #  same duration, so this is a potentially useful optimisation.
    #
    def group_by_duration
      previous_start = 0
      previous_end = 0
      the_lot = Array.new
      current_batch = Array.new
      @mwds.sort.each do |mwd|
        if mwd.start_date == previous_start &&
           mwd.end_date == previous_end
          current_batch << mwd
        else
          unless current_batch.empty?
            @grouped_mwds << current_batch
          end
          current_batch = Array.new
          previous_start = mwd.start_date
          previous_end   = mwd.end_date
          current_batch << mwd
        end
      end
      unless current_batch.empty?
        @grouped_mwds << current_batch
      end
    end

    #
    #  Call this after you've added all the mwds to sort them and handle
    #  any exclusions.
    #
    def finalize
#      Rails.logger.debug("Finalizing MWD_Set.")
      self.process_exclusions
#      Rails.logger.debug("Done the exclusions.")
      self.group_by_duration
#      Rails.logger.debug("Finished finalizing.")
    end

    def to_partial_path
      "mwdset"
    end

    #
    #  Turn this whole set into a snippet of SQL to be added to a
    #  larger query.
    #
    def to_sql
      @grouped_mwds.collect { |group|
        "(events.ends_at > '#{group[0].start_time_utc}'#{
          group[0].end_date ? " AND events.starts_at < '#{group[0].end_time_utc}'" : ""
        } AND commitments.element_id IN (#{group.collect {|mwb| mwb.membership.group.element.id}.join(",") }))"
      }.join(" OR ")
    end

    def empty?
      @grouped_mwds.size == 0
    end

  end

  #
  #  Start of the Membership class proper
  #

  belongs_to :group
  belongs_to :element
  belongs_to :role              # Optional

  validates :group,     :presence => true
  validates :element,   :presence => true
  validates :starts_on, :presence => true
  
  validate :not_backwards
  

  scope :starts_by, lambda {|date| where("starts_on <= ?", date) }
  scope :starts_after, lambda {|date| where("starts_on > ?", date) }
  scope :continues_until, lambda {|date| where("ends_on IS NULL OR ends_on >= ?", date) }
  scope :active_on, lambda {|date| starts_by(date).continues_until(date) }
  scope :active_during, ->(start_date, end_date) {
                             starts_by(end_date).continues_until(start_date)
                           }
  scope :exclusions, -> { where(inverse: true) }
  scope :inclusions, -> { where(inverse: false) }
  scope :by_element, ->(element) { where("element_id = ?", element.id) }
  scope :of_group,   ->(group)   { where("group_id = ?", group.id) }

  #
  #  Can I also have a method with the same name?  It appears I can.
  #
  def active_on(date)
    self.starts_on <= date &&
    (self.ends_on == nil || self.ends_on >= date)
  end

  def self.is_member?(group, element, role = nil, on = nil)
  end

  # Provides the name of our group, if any.
  def group_name
    group ? group.name : ""
  end

  # Provides the name of our element, if any.
  def element_name
    element ? element.name : ""
  end

  # Provides the name of our role, if any.
  def role_name
    role ? role.name : ""
  end

  #  Dummy methods
  def group_name=(newname)
  end

  def element_name=(newname)
  end

  def role_name=(newname)
  end

  #
  #  Called when our parent group has changed its start date.  Adjust ours
  #  to match.  If we previously started exactly on the groups start date
  #  then we carry on doing that.  Otherwise, if we started before the new
  #  start date then we adjust to starting on it, and if we started after
  #  the new start date then we stay where we were.
  #
  #  Might need to adjust our end date to match.  It's possible we will
  #  cease to exist entirely.
  #
  #
  def set_start_date(old_group_start, new_group_start)
    if self.starts_on > new_group_start
      #
      #  We start later than the new group start.  No action needed, unless
      #  we used to start exactly on the old group start.
      #
      if self.starts_on == old_group_start
        self.starts_on = new_group_start
        self.save!
      end
    elsif self.starts_on < new_group_start
      self.starts_on = new_group_start
      if self.ends_on == nil || self.ends_on >= self.starts_on
        self.save!
      else
        #
        #  Our new start date is now after our end date.
        #  Self-destruct.
        #
        self.destroy!
      end
    end
  end

  #
  #  For finding all the groups which an element belongs to as efficiently
  #  as possible.
  #
  #  The anti-loop check here is slightly naive.  It will reject a second
  #  discovery of the same group, even though that might actually be a valid
  #  case - e.g. because something belongs twice consecutively in the indicated
  #  period.  We should really only reject duplicates if we find the
  #  same group twice in the same branch of the tree - indicating a loop.
  #  TODO: Fix this later.
  #
  def recurse_mbd(mwd_set, start_date, end_date, seen, level)
#    Rails.logger.debug("Entering membership.recurse_mbd")
#    Rails.logger.debug("Seen #{seen.to_s}")
    if seen.include?(self.group_id)
#      Rails.logger.debug("so not bothering")
    end
    seen << self.group_id
    #
    #  May need to adjust the start and end date in the light of our own.
    #  We must have a start date of our own; we might not have an end date.
    #
    unless start_date &&
           start_date >= self.starts_on
      start_date = self.starts_on
    end
    if self.ends_on
      unless end_date &&
             end_date <= self.ends_on
        end_date = self.ends_on
      end
    end
    #
    #  Is it possible that the two could cross?  It shouldn't be,
    #  because our partner method is supposed to have selected only
    #  memberships with overlap with the indicated interval.
    #
    if start_date && end_date && start_date > end_date
      raise "Ouch!"
    end
    #
    #  We now know the membership dates for our parent group.  Record
    #  that and move on.
    #
    mwd_set.add_mwd(self, start_date, end_date, level)
    self.group.element.recurse_mbd(mwd_set,
                                   start_date,
                                   end_date,
                                   seen,
                                   level + 1)
#    Rails.logger.debug("Leaving membership.recurse_mbd.")
  end

  private

  def not_backwards
    if self.ends_on &&
       self.starts_on &&
       self.ends_on < self.starts_on
      errors.add(:ends_on, "must be no earlier than start date")
    end
  end

  #
  #  Note that we particularly want to exclude the possibility of
  #  two otherwise identical membership records, one of which has the
  #  inverse flag set and the other of which doesn't.
  #
  #  It's not our job to do the manipulation to achieve this (done
  #  by the controller); it's just our job to make sure it doesn't
  #  happen.
  #
  def unique
    if self.ends_on
      clashes = Membership.by_element(self.element).
                           of_group(self.group).
                           active_during(self.starts_on, self.ends_on)
    else
      clashes = Membership.by_element(self.element).
                           of_group(self.group).
                           continues_until(self.starts_on)
    end
    if clashes.size > 0
      errors.add(:overall, "Duplicate memberships are not allowed.")
    end
  end

end
