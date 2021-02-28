#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class AdHocDomainSubject < ApplicationRecord
  include Comparable
  include Adhoc

  belongs_to :ad_hoc_domain_cycle
  belongs_to :subject

  has_many :ad_hoc_domain_subject_staffs, dependent: :destroy
  has_many :ad_hoc_domain_staffs, through: :ad_hoc_domain_subject_staffs

  has_many :staffs, through: :ad_hoc_domain_staffs

  has_many :ad_hoc_domain_pupil_courses, through: :ad_hoc_domain_subject_staffs

  validates :subject,
    uniqueness: {
      scope: :ad_hoc_domain_cycle,
      message: "Can't repeat subject within cycle"
    }

  #
  #  This exists just so we can write to it.
  #
  attr_writer :subject_element_name

  def ad_hoc_domain
    self.ad_hoc_domain_cycle&.ad_hoc_domain
  end

  def can_delete?
    #
    #  Can delete this only if there are no affected staff or pupils.
    #
    true
  end

  def subject_element=(element)
    if element
      if element.entity_type == "Subject"
        self.subject = element.entity
      end
    else
      self.subject = nil
    end
  end

  def subject_element_id=(id)
    Rails.logger.debug("subject_element_id= passed #{id}")
    self.subject_element = Element.find_by(id: id)
  end

  #
  #  Safe way of getting the subject name
  #
  def subject_name
    if subject
      subject.name
    else
      ""
    end
  end

  def num_real_staff
    self.ad_hoc_domain_subject_staffs.size
  end

  def num_real_pupils
    self.ad_hoc_domain_pupil_courses.size
  end

  def num_pupils_text
    "#{num_real_pupils} #{"pupil".pluralize(num_real_pupils)}"
  end

  def num_staff_text
    "#{num_real_staff} staff"
  end

  def <=>(other)
    if other.instance_of?(AdHocDomainSubject)
      #
      #  We sort by name.  If you want to do a lot then make sure
      #  you preload the Subject records before attempting your
      #  sort.
      #
      if self.subject
        if other.subject
          result = self.subject <=> other.subject
          if result == 0
            #  We must return 0 iff we are the same record.
            result = self.id <=> other.id
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

end
