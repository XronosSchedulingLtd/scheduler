class AdHocDomainStaff < ApplicationRecord
  belongs_to :staff
  belongs_to :ad_hoc_domain_subject

  validates :staff,
    uniqueness: {
      scope: [:ad_hoc_domain_subject],
      message: "Can't repeat staff within subject"
    }
  #
  #  This exists just so we can write to it.
  #
  attr_writer :staff_element_name

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

end
