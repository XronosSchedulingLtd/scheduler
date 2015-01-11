# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :element
  belongs_to :role              # Optional

  validates :group,     :presence => true
  validates :element,   :presence => true
  validates :starts_on, :presence => true
  
  validate :not_backwards
  validate :unique, :on => :create

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
