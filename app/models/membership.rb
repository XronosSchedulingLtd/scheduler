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
  scope :continues_until, lambda {|date| where("ends_on IS NULL OR ends_on >= ?", date) }
  scope :active_on, lambda {|date| starts_by(date).continues_until(date) }
  scope :exclusions, -> { where(inverse: true) }
  scope :inclusions, -> { where(inverse: false) }

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

  private

  def not_backwards
    if ends_on &&
       starts_on &&
       ends_on < starts_on
      errors.add(:ends_on, "must be no earlier than start date")
    end
  end

  # Can't have all three of group, element and role the same.
  # This test is cock-eyed - you can too have them the same, just not
  # at the same time.  Work required.
  #
  #  Note that we particularly want to exclude the possibility of
  #  two otherwise identical membership records, one of which has the
  #  inverse flag set and the other of which doesn't.
  #
  def unique
    if Membership.find_by_group_id_and_element_id_and_role_id(
         group_id,
         element_id,
         role_id) != nil
      errors.add(:overall, "Duplicate memberships are not allowed.")
    end
  end

end
