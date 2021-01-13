class AdHocDomainSubject < ApplicationRecord
  belongs_to :ad_hoc_domain
  belongs_to :subject_element, class_name: "Element"

  has_many :ad_hoc_domain_staffs, dependent: :destroy

  validates :subject_element,
    uniqueness: {
      scope: :ad_hoc_domain,
      message: "Can't repeat subject within domain"
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
