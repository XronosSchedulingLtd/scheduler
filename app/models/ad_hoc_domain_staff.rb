#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class AdHocDomainStaff < ApplicationRecord
  include Comparable
  include Adhoc

  belongs_to :ad_hoc_domain_cycle
  belongs_to :staff

  has_one :rota_template, dependent: :destroy

  has_many :ad_hoc_domain_subject_staffs, dependent: :destroy
  has_many :ad_hoc_domain_subjects, through: :ad_hoc_domain_subject_staffs

  has_many :subjects, through: :ad_hoc_domain_subjects

  has_many :ad_hoc_domain_pupil_courses, through: :ad_hoc_domain_subject_staffs

  validates :staff,
    uniqueness: {
      scope: [:ad_hoc_domain_cycle],
      message: "Can't repeat staff within cycle"
    }

  #
  #  This exists just so we can write to it.
  #
  attr_writer :staff_element_name

  def ad_hoc_domain
    self.ad_hoc_domain_cycle&.ad_hoc_domain
  end

  def can_delete?
    #
    #  Can delete this only if there are no affected pupils.
    #
    true
  end

  def staff_element=(element)
    if element
      if element.entity_type == "Staff"
        self.staff = element.entity
      end
    else
      self.staff = nil
    end
  end

  def staff_element_id=(id)
    self.staff_element = Element.find_by(id: id)
  end

  def staff_name
    if self.staff
      self.staff.name
    else
      ""
    end
  end

  def num_real_pupils
    self.ad_hoc_domain_pupil_courses.size
  end

  def num_middle_pupils
    threshold = self.ad_hoc_domain.missable_threshold
    if threshold == 0
      num_real_pupils
    else
      self.ad_hoc_domain_pupil_courses.select { |pc|
        pc.pupil.year_group < threshold
      }.size
    end
  end

  def num_real_subjects
    self.ad_hoc_domain_subject_staffs.size
  end

  def num_pupils_text
    "#{num_real_pupils} #{"pupil".pluralize(num_real_pupils)}"
  end

  def num_subjects_text
    "#{num_real_subjects} #{"subject".pluralize(num_real_subjects)}"
  end

  def total_mins
    #
    #  The total number of minutes scheduled for this staff member.
    #
    self.ad_hoc_domain_pupil_courses.map(&:minutes).reduce(0, :+)
  end

  def <=>(other)
    if other.instance_of?(AdHocDomainStaff)
      #
      #  We sort by name.  If you want to do a lot then make sure
      #  you preload the Subject records before attempting your
      #  sort.
      #
      if self.staff
        if other.staff
          result = self.staff <=> other.staff
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

  def loading
    self.peers.
         includes(:ad_hoc_domain_pupil_courses).
         map {|peer| peer.single_loading}.
         reduce(0, :+)
  end

  #
  #  All our pupils taking the indicated subject.
  #
  def pupils_for(ahd_subject)
    #
    #  This is intended for use in AdHocDomainCycle listings, and it is
    #  assumed that all relevant records are already in memory, cached by
    #  the controller.  We therefore use select rather than a fresh d/b hit.
    #
    habtm = self.ad_hoc_domain_subject_staffs.find {|l|
      l.ad_hoc_domain_subject == ahd_subject}
    if habtm
      habtm.ad_hoc_domain_pupil_courses
    else
      []
    end
  end

  #
  #  Find all instances of ad_hoc_domain_subject_staff records linking
  #  us to the indicated subject.
  #
  def links_to(ahd_subject)
    self.ad_hoc_domain_subject_staffs.select { |l|
      l.ad_hoc_domain_subject == ahd_subject }
  end

  #
  #  Single place to decide what the name should be.
  #
  def rota_template_name
    "Availability for #{self.staff_name} in #{self.ad_hoc_domain_cycle.name}"
  end

  protected

  #
  #  The loading just for this instance.
  #
  def single_loading
    self.ad_hoc_domain_pupil_courses.inject(0) {|sum, p| sum + p.minutes}
  end

end
