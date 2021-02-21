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
  include Comparable
  belongs_to :ad_hoc_domain

  has_one :ad_hoc_domain_as_default_cycle,
          class_name: "AdHocDomain",
          foreign_key: :default_cycle_id,
          dependent: :nullify
  has_many :ad_hoc_domain_subjects, dependent: :destroy
  has_many :subjects, through: :ad_hoc_domain_subjects

  has_many :ad_hoc_domain_staffs, dependent: :destroy
  has_many :staffs, through: :ad_hoc_domain_staffs

  has_many :ad_hoc_domain_pupil_courses, through: :ad_hoc_domain_subjects

  validates :name, presence: true
  validates :starts_on, presence: true
  validates :exclusive_end_date, presence: true

  validates_with AdHocDomainCycleValidator

  #
  #  Temporary stores for information about copying from another domain cycle.
  #
  attr_accessor :based_on_id
  attr_writer :copy_what

  #
  #  Slight frig.  When anyone asks from outside what our copy_what
  #  value is, we say 2.  This is the default for the dialogue.  However
  #  we access the real value internally, which is set by the above writer.
  #
  def copy_what
    2
  end

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

  def set_as_default?
    self.ad_hoc_domain.default_cycle == self
  end

  #
  #  Work out the position of this particular subject in our listing,
  #  indexed from 1 (yuk!) to suit CSS.
  #
  def position_of(ahds)
    (self.ad_hoc_domain_subjects.sort.find_index(ahds) || 0) + 1
  end

  def <=>(other)
    if other.instance_of?(AdHocDomainCycle)
      #
      #  We sort by date, first the start date, then the end date.
      #  Missing dates put you at the end of the list.
      #
      if self.starts_on
        if other.starts_on
          result = self.starts_on <=> other.starts_on
          if result == 0
            if self.exclusive_end_date
              if other.exclusive_end_date
                result = self.exclusive_end_date <=> other.exclusive_end_date
                if result == 0
                  #  We must return 0 iff we are the same record.
                  result = self.id <=> other.id
                end
              else
                result = -1
              end
            else
              result = 1
            end
          end
        else
          #
          #  Other is not yet complete.  Put it last.
          #
          result = -1
        end
      else
        #
        #  We are incomplete and go last.
        #
        result = 1
      end
    else
      result = nil
    end
    result
  end

  def populate_from(donor_cycle)
    #
    #  Copy records from the donor cycle, according to our existing
    #  @copy_what instance variable.
    #
    to_copy = @copy_what.to_i
    if to_copy > 0
      ahd_subjects_by_subject_id = Hash.new
      #
      #  We need to copy (duplicate) all the subject and staff records
      #  which are children of the given cycle record, then go for any
      #  pupil records further down.  Linking them up as they were
      #  before.
      #
      donor_cycle.ad_hoc_domain_subjects.each do |ahdsubj|
        self.ad_hoc_domain_subjects << newsubj = ahdsubj.dup
        #
        #  So we can find it to link to staff.
        #
        ahd_subjects_by_subject_id[newsubj.subject_id] = newsubj
      end
      if to_copy > 1
        #
        #  Need staff too.
        #
        donor_cycle.ad_hoc_domain_staffs.each do |ahdstaff|
          self.ad_hoc_domain_staffs << newstaff = ahdstaff.dup
          #
          #  And need to re-create the linking records between
          #  staff and subjects.
          #
          ahdstaff.ad_hoc_domain_subjects.each do |ahdsubj|
            newsubj = ahd_subjects_by_subject_id[ahdsubj.subject_id]
            if newsubj
              newstaff.ad_hoc_domain_subjects << newsubj
            end
          end
          if to_copy > 2
            #
            #  And need pupils too.
            #
            ahdstaff.ad_hoc_domain_pupil_courses.each do |ahdpupil|
              newsubj =
                ahd_subjects_by_subject_id[ahdpupil.ad_hoc_domain_subject.subject_id]
              if newsubj
                newpupil = ahdpupil.dup
                newpupil.ad_hoc_domain_subject = newsubj
                newpupil.ad_hoc_domain_staff = newstaff
                newpupil.save
              end
            end
          end
        end
      end
    end
  end

  def num_real_subjects
    self.ad_hoc_domain_subjects.select {|ahds| !ahds.new_record?}.count
  end

  def num_real_staff
    total = 0
    self.ad_hoc_domain_subjects.select {|ahds| !ahds.new_record?}.each do |ahds|
      total += ahds.num_real_staff
    end
    total
  end

  def num_real_pupils
    total = 0
    self.ad_hoc_domain_subjects.select {|ahds| !ahds.new_record?}.each do |ahds|
      total += ahds.num_real_pupils
    end
    total
  end

end
