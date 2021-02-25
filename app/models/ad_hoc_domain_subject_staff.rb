#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainSubjectStaff < ApplicationRecord
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

end

