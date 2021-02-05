#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class AdHocDomainStaff < ApplicationRecord
  include Comparable

  belongs_to :staff
  belongs_to :ad_hoc_domain_subject

  has_many :ad_hoc_domain_pupil_courses, dependent: :destroy

  validates :staff,
    uniqueness: {
      scope: [:ad_hoc_domain_subject],
      message: "Can't repeat staff within subject"
    }

  #
  #  This exists just so we can write to it.
  #
  attr_writer :staff_element_name

  def ad_hoc_domain
    self.ad_hoc_domain_subject&.ad_hoc_domain_cycle&.ad_hoc_domain
  end

  def peers
    self.ad_hoc_domain.peers_of(self)
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
    self.ad_hoc_domain_pupil_courses.select {|ahdpc| !ahdpc.new_record?}.count
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

  protected

  #
  #  The loading just for this instance.
  #
  def single_loading
    self.ad_hoc_domain_pupil_courses.inject(0) {|sum, p| sum + p.minutes}
  end

end
