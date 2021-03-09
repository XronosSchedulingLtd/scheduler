#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainSubjectStaff < ApplicationRecord
  include Comparable

  belongs_to :ad_hoc_domain_subject
  belongs_to :ad_hoc_domain_staff

  has_many :ad_hoc_domain_pupil_courses, dependent: :destroy
  
  validates :ad_hoc_domain_staff,
    uniqueness: {
      scope: [:ad_hoc_domain_subject],
      message: "Can't repeat staff within subject"
    }

  def num_real_pupils
    self.ad_hoc_domain_pupil_courses.size
  end

  def <=>(other)
    if other.instance_of?(AdHocDomainSubjectStaff)
      #
      #  We delegate the sorting to our AdHocDomainSubject and
      #  AdHocDomainStaff records, sorting by subject and then
      #  by staff.
      #
      if self.ad_hoc_domain_subject && self.ad_hoc_domain_staff
        if other.ad_hoc_domain_subject && other.ad_hoc_domain_staff
          result = self.ad_hoc_domain_subject <=> other.ad_hoc_domain_subject
          if result == 0
            result = self.ad_hoc_domain_staff <=> other.ad_hoc_domain_staff
            if result == 0
              #  We must return 0 iff we are the same record.
              result = self.id <=> other.id
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

  def total_mins
    #
    #  The total number of minutes scheduled for this staff and subject.
    #
    self.ad_hoc_domain_pupil_courses.map(&:minutes).reduce(0, :+)
  end

end

