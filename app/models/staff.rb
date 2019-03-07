# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Staff < ActiveRecord::Base

  validates :name, presence: true

  DISPLAY_COLUMNS = [:taught_groups, :direct_groups, :indirect_groups]

  include Elemental

  #
  #  Override this method inherited from Elemental.
  #
  def self.a_person?
    true
  end

  belongs_to :datasource
  #
  #  Has only one per year, but in terms of data structues, has many.
  #
  has_many :tutorgrouppersonae

  has_and_belongs_to_many :subjects
  before_destroy { subjects.clear }

  has_and_belongs_to_many :teachinggrouppersonae
  before_destroy { teachinggrouppersonae.clear }

  has_many :groupstaught, through: :teachinggrouppersonae, source: :group 
  has_many :tutorgroups, through: :tutorgrouppersonae, source: :group

  has_many :corresponding_users,
           class_name: "User",
           foreign_key: "corresponding_staff_id",
           dependent: :nullify

  after_destroy :delete_tutorgroups

  self.per_page = 15

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :current, -> { where(current: true) }
  scope :teaching, -> { where(teaches: true) }
  scope :non_teaching, -> { where(teaches: false) }
  scope :does_cover, -> { where(does_cover: true) }
  scope :cover_exempt, -> { where(does_cover: false) }

  #
  #  This could be done as teachinggrouppersonae.collect {|tgp| tgp.group}
  #  but this should be more efficient.
  #

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.initials} - #{self.name}"
  end

  def short_name
    self.initials
  end

  def description
    "Member of staff"
  end

  def tabulate_name(columns)
    if columns == 3
      "<tr><td>#{self.initials}</td><td>#{self.forename}</td><td>#{self.surname}</td></tr>".html_safe
    elsif columns == 2
      "<tr><td>#{self.initials}</td><td>#{self.forename} #{self.surname}</td></tr>".html_safe
    else
      "<tr><td colspan='#{columns}'>#{self.element_name}</td></tr>".html_safe
    end
  end

  def csv_name
    [self.initials,
     self.forename,
     self.surname,
     self.email].to_csv
  end

  #
  #  Deleting a group deletes its persona, but not the other way around
  #  because that gives you a stack overflow.  We therefore have to
  #  do the deletion ourselves rather than relying on a :dependent => :destroy
  #  declaration on the relationship.
  #
  def delete_tutorgroups
    self.tutorgrouppersonae.each do |tgp|
      tgp.group.destroy!
    end
  end

  def self.set_currency
    Staff.active.each do |s|
      s.current = true
      s.save
    end
  end

  def <=>(other)
    result = sort_by_entity_type(other)
    if result == 0
      result = self.surname <=> other.surname
      if result == 0
        result = self.forename <=> other.forename
      end
    end
    result
  end

  #
  #  Returns the corresponding user record, or nil if none exists.
  #
  def corresponding_user
    if self.element &&
       self.element.concerns.me.size > 0
      self.element.concerns.me[0].user
    else
      nil
    end
  end

  #
  #  Users who have bothered to log on can choose to cut down on their
  #  notifications.  Users who haven't bothered get them regardless.
  #
  #
  def invig_weekly_notifications?
    my_user = corresponding_user
    if my_user
      my_user.invig_weekly
    else
      true
    end
  end

  def invig_daily_notifications?
    my_user = corresponding_user
    if my_user
      my_user.invig_daily
    else
      true
    end
  end

  #
  #  A maintenance method to move over information from manually created
  #  staff (existing before an iSAMS import) to the corresponding
  #  record from iSAMS.
  #
  #  Not that this method is not generally robust.  It was written for
  #  the specific case of Dean Close school, where only two members
  #  of staff had any existing commitments at all and only one each.
  #
  #  None had any existing memberships.
  #

  def check_and_transfer(messages)
    messages << "Processing #{self.name}."
    messages << "#{self.element.commitments.count} existing commitments."
    user = self.corresponding_user
    if user
      messages << "Has user record."
    else
      messages << "Has no user record."
    end
    candidates = Staff.where(email: self.email) - [self]
    puts "#{candidates.size} candidates."
    if candidates.size == 1
      new_one = candidates[0]
      #
      #  Hand over our commitments.
      #
      self.element.commitments.each do |c|
        c.element = new_one.element
        c.save!
      end
      #
      #  And our user record.
      #
      if user
        concern = self.element.concerns.me[0]
        concern.element = new_one.element
        concern.save!
      end
      #
      #  The danger we have here is that if we simply destroy our
      #  record, there will be a cached copy of its element in memory
      #  which will lead to other things being destroyed as well,
      #  speficially the commitments which we have just re-assigned.
      #  (The commitment no longer thinks it is connected to the element,
      #  but the cached element will still contain a reference to the
      #  commitment.)
      #
      #  Reload the element first.
      #
      self.element.reload
      self.destroy!
      true
    else
      false
    end
  end

  def self.check_and_transfer
    messages = []
    Staff.where(datasource: nil).each do |staff|
      if staff.check_and_transfer(messages)
        messages << "Processed #{staff.name}."
      else
        messages << "Didn't process #{staff.name}."
      end
    end
    puts messages.join("\n")
    nil
  end
end
