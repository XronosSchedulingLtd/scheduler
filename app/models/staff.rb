# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Staff < ActiveRecord::Base

  validates :name, presence: true

  include Elemental

  #
  #  Has only one per year, but in terms of data structues, has many.
  #
  has_many :tutorgrouppersonae

  after_destroy :delete_tutorgroups

  self.per_page = 15

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :current, -> { where(current: true) }
  scope :teaches, -> { where(teaches: true) }
  scope :non_teaching, -> { where(teaches: false) }
  scope :does_cover, -> { where(does_cover: true) }
  scope :cover_exempt, -> { where(does_cover: false) }


  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.initials} - #{self.name}"
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
end
