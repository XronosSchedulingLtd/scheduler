class AdHocDomainStaff < ApplicationRecord
  belongs_to :ad_hoc_domain
  belongs_to :staff_element, class_name: "Element"
  belongs_to :ad_hoc_domain_subject

  validates :staff_element,
    uniqueness: {
      scope: [:ad_hoc_domain, :ad_hoc_domain_subject],
      message: "Can't repeat staff within domain and subject"
    }
  #
  #  This exists just so we can write to it.
  #
  attr_writer :subject_element_name

  def can_delete?
    #
    #  Can delete this only if there are no affected staff or pupils.
    #
    true
  end

end
