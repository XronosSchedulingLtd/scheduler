class AdHocDomainPupilCourse < ApplicationRecord
  belongs_to :pupil
  belongs_to :ad_hoc_domain_staff

  validates :pupil,
    uniqueness: {
      scope: [:ad_hoc_domain_staff],
      message: "Can't repeat pupil within staff"
    }
  #
  #  This exists just so we can write to it.
  #
  attr_writer :pupil_element_name

  def pupil_element=(element)
    if element
      if element.entity_type == "Staff"
        self.pupil = element.entity
      end
    else
      self.pupil = nil
    end
  end

  def pupil_element_id=(id)
    self.pupil_element = Element.find_by(id: id)
  end

end
