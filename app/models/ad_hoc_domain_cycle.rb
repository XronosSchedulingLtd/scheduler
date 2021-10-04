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
  include Adhoc
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

  has_many :ad_hoc_domain_allocations, dependent: :destroy

  has_many :ad_hoc_domain_subject_staffs, through: :ad_hoc_domain_subjects

  validates :name, presence: true
  validates :starts_on, presence: true
  validates :exclusive_end_date, presence: true

  validates_with AdHocDomainCycleValidator

  enum update_status: [
    :idle,
    :queued,
    :processing,
    :completed,
    :failed
  ]

  belongs_to :active_allocation,
    class_name: "AdHocDomainAllocation",
    optional: true

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
  #  Work out the position of this particular subject or staff in our listing,
  #  indexed from 1 (yuk!) to suit CSS.
  #
  def position_of(ahds)
    case ahds
    when AdHocDomainSubject
      (self.ad_hoc_domain_subjects.sort.find_index(ahds) || 0) + 1
    when AdHocDomainStaff
      (self.ad_hoc_domain_staffs.sort.find_index(ahds) || 0) + 1
    end
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
      ahd_new_subjects_by_old_id = Hash.new
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
        ahd_new_subjects_by_old_id[ahdsubj.id] = newsubj
      end
      if to_copy > 1
        #
        #  Need staff too.
        #
        donor_cycle.ad_hoc_domain_staffs.each do |ahdstaff|
          self.ad_hoc_domain_staffs << newstaff = ahdstaff.dup
          if ahdstaff.rota_template
            #
            #  Need our own copy of this.
            #
            newstaff.rota_template =
              ahdstaff.rota_template.do_clone(newstaff.rota_template_name)
          end
          #
          #  And need to re-create the linking records between
          #  staff and subjects.
          #
          ahdstaff.ad_hoc_domain_subject_staffs.each do |ahdss|
            #
            #  Each time there was an old record we need a new
            #  one.
            #
            newsubj = ahd_new_subjects_by_old_id[ahdss.ad_hoc_domain_subject_id]
            if newsubj
              newahdss = newstaff.ad_hoc_domain_subject_staffs.create({
                ad_hoc_domain_subject: newsubj})
              if to_copy > 2
                ahdss.ad_hoc_domain_pupil_courses.each do |ahdpc|
                  newpupil = ahdpc.dup
                  newpupil.ad_hoc_domain_subject_staff = newahdss
                  newpupil.save
                end
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

  #
  #  Calculate how many weeks this cycle covers.  This gets slightly
  #  interesting because it's possible for a cycle to start or end
  #  mid-week, in which case we still count it.  Quite what will happen
  #  in terms of ad hoc lessons is a bit up in the air if a teacher
  #  is available for only half a week, but not sure how we can improve
  #  the calculation.
  #
  def num_weeks
    sundate = self.starts_on - self.starts_on.wday.days
    duration = (self.exclusive_end_date - sundate).to_i
    #
    #  duration = 1 => result 1
    #  duration = 7 => result 1
    #  duration = 8 => result 2
    #  etc.
    #
    (duration + 6) / 7
  end

  #  A function to note that an update is being queued.  It checks
  #  the status and does a locking update of the record.
  #
  def note_queued(allocation)
    result = false
    if can_queue_update?
      self.update_status     = :queued
      self.active_allocation = allocation
      self.queued_at         = Time.zone.now
      self.started_at        = nil
      self.finished_at       = nil
      self.num_created       = 0
      self.num_deleted       = 0
      self.num_amended       = 0
      #
      #  Saving this may result in an error.
      #
      begin
        result = self.save
      rescue ActiveRecord::StaleObjectError
        #
        #  Don't actually need to do anything.
        #  result is already false.
        #
      end
    end
    return result
  end

  #
  #  These too might conceivably get a StaleObjectError, but it shouldn't
  #  happen in the course of normal processing.  If it does, then try again.
  #
  def persistently_do
    done = false
    attempts = 0
    while !done && attempts < 5
      begin
        yield
        done = true
      rescue ActiveRecord::StaleObjectError
        attempts += 1
        self.reload
      end
    end
  end

  def note_started
    persistently_do {
      self.update_status = :processing
      self.started_at = Time.zone.now
      self.save
    }
  end

  def note_finished
    persistently_do {
      self.update_status = :completed
      self.finished_at = Time.zone.now
      self.save
    }
  end

  def note_failed
    persistently_do {
      self.update_status = :failed
      self.finished_at = Time.zone.now
      self.save
    }
  end

  def update_counts(created, deleted, amended)
    persistently_do {
      self.num_created = created
      self.num_deleted = deleted
      self.num_amended = amended
      self.save
    }
  end

  private

  def can_queue_update?
    #
    #  We can queue something as long as we don't have anything
    #  queued or processing.
    #
    self.idle? || self.completed? || self.failed?
  end

  #
end
