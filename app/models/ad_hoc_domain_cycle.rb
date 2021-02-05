#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainCycleValidator < ActiveModel::Validator

  def validate(record)
    #
    #  If either of the date fields is blank it will fail other
    #  validations anyway.  We merely need to check that they are
    #  both compatible.
    #
    if record[:starts_on] && record[:exclusive_end_date]
      unless record[:exclusive_end_date] > record[:starts_on]
        #
        #  Not sure this will work, but we can try it.  The field
        #  visible to users is ends_on, so try to attach the error
        #  to that.
        #
        record.errors[:ends_on] << "cannot be before starts_on"
      end
    end
  end

end

class AdHocDomainCycle < ApplicationRecord
  belongs_to :ad_hoc_domain

  has_one :ad_hoc_domain_as_default_cycle,
          class_name: "AdHocDomain",
          foreign_key: :default_cycle_id,
          dependent: :nullify
  has_many :ad_hoc_domain_subjects, dependent: :destroy
  has_many :subjects, through: :ad_hoc_domain_subjects

  has_many :ad_hoc_domain_staffs, through: :ad_hoc_domain_subjects

  validates :name, presence: true
  validates :starts_on, presence: true
  validates :exclusive_end_date, presence: true

  validates_with AdHocDomainCycleValidator

  #
  #  End dates should always be stored as exclusive end dates, but it's
  #  convenient to end users to provide inclusive ones as well.  These
  #  methods should be used *only* for user interface stuff.
  #
  def ends_on
    if self.exclusive_end_date
      self.exclusive_end_date - 1.day
    else
      nil
    end
  end

  def ends_on=(datestring)
    date = Date.safe_parse(datestring)
    if date
      self.exclusive_end_date = date + 1.day
    else
      self.exclusive_end_date = nil
    end
  end

  #
  #  Find all AdHocDomainStaff records in this AdHocDomainCycle matching
  #  a sample one.
  #
  def peers_of(ahds)
    self.ad_hoc_domain_staffs.where(staff_id: ahds.staff_id)
  end

  #
  #  Work out the position of this particular subject in our listing,
  #  indexed from 1 (yuk!) to suit CSS.
  #
  def position_of(ahds)
    (self.ad_hoc_domain_subjects.sort.find_index(ahds) || 0) + 1
  end

end
