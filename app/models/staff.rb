# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Staff < ActiveRecord::Base

  validates :name, presence: true

  DISPLAY_COLUMNS = [:taught_groups, :direct_groups, :indirect_groups]

  include Elemental

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
     self.surname].to_csv
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
    result = self.surname <=> other.surname
    if result == 0
      result = self.forename <=> other.forename
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

end
