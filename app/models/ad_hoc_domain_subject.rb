class AdHocDomainSubject < ApplicationRecord
  belongs_to :ad_hoc_domain
  belongs_to :subject

  has_many :ad_hoc_domain_staffs, dependent: :destroy

  validates :subject,
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

  def subject_element=(element)
    Rails.logger.debug("subject_id= passed #{element}")
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

end
