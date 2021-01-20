class AdHocDomainSubject < ApplicationRecord
  include Comparable

  belongs_to :ad_hoc_domain
  belongs_to :subject

  has_many :ad_hoc_domain_staffs, dependent: :destroy
  has_many :staffs, through: :ad_hoc_domain_staffs

  has_many :ad_hoc_domain_pupil_courses, through: :ad_hoc_domain_staffs

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
    self.ad_hoc_domain_staffs.select {|ahds| !ahds.new_record?}.count
  end

  def num_real_pupils
    total = 0
    self.ad_hoc_domain_staffs.select {|ahds| !ahds.new_record?}.each do |ahds|
      total += ahds.num_real_pupils
    end
    total
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
