# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Staff < ApplicationRecord

  validates :name, presence: true

  DISPLAY_COLUMNS = [:taught_groups, :direct_groups, :indirect_groups]

  include Elemental

  #
  #  Override this method inherited from Elemental.
  #
  def self.a_person?
    true
  end

  belongs_to :datasource, optional: true
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
    #
    #  Note that if the corresponding_users array is empty then this
    #  will return nil, which is what we want.
    #
    self.corresponding_users[0]
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
  #  staff (existing before an MIS import) to the corresponding
  #  record from the MIS.
  #
  #  This method is called for each staff record which has *not*
  #  come from an MIS.  It looks for another record with the same
  #  e-mail address which *has* come from the MIS.
  #
  #  If it finds one then it copies all its
  #
  #  * Memberships
  #  * Commitments
  #
  #  to the MIS-derived one, and then self-destructs.
  #
  #  It will work only if there is exactly one matching staff
  #  record.
  #
  #  A really weird circumstance has arisen.  Sometimes we have
  #  two identical staff members, both of which have been entered
  #  manually.  That's just silly, but it happens.  Try to cope
  #  with that too.
  #
  #  Don't attempt to transfer user records.  If we delete
  #  the staff member connected to a user, then the next time they
  #  log in they will be linked in again.
  #

  def check_and_transfer(messages)
    unless self.email.blank?
      candidates = Staff.where(email: self.email, active: true) - [self]
      if candidates.size == 1
        #
        #  It seems we have a good one.
        #
        recipient = candidates[0]
        messages << "Merging #{self.name}"
        commitment_count, commitments_transferred,
        membership_count, memberships_transferred =
          recipient.element.absorb(self.element)
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
        messages << "Transferred #{commitments_transferred} commitments out of #{commitment_count}"
        messages << "Transferred #{memberships_transferred} memberships out of #{membership_count}"
      end
    end
  end

  def self.check_and_transfer
    messages = []
    Staff.where(datasource: nil, active: true).each do |staff|
      staff.check_and_transfer(messages)
    end
    puts messages.join("\n")
    nil
  end
end
