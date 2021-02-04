class AdHocDomainPupilCourse < ApplicationRecord
  include Comparable

  belongs_to :pupil
  belongs_to :ad_hoc_domain_staff

  validates :pupil,
    uniqueness: {
      scope: [:ad_hoc_domain_staff],
      message: "Can't repeat pupil within staff"
    }
  validates :minutes,
    numericality: {
      only_integer: true,
      greater_than: 0
    }
  #
  #  This exists just so we can write to it.
  #
  attr_writer :pupil_element_name

  def pupil_element=(element)
    if element
      if element.entity_type == "Pupil"
        self.pupil = element.entity
      end
    else
      self.pupil = nil
    end
  end

  def pupil_element_id=(id)
    self.pupil_element = Element.find_by(id: id)
  end

  def pupil_name
    if self.pupil
      #
      #  Tempting to use self.pupil.element_name here because it
      #  involves one fewer models, but that method actually works
      #  out what the name should be, which in turn involves several
      #  d/b hits.  The element record on the other hand has it as
      #  a simple data field.  If doing a lot, pre-load all the elements
      #  too.
      #
      self.pupil.element.name
    else
      ""
    end
  end

  def <=>(other)
    if other.instance_of?(AdHocDomainPupilCourse)
      #
      if self.pupil
        if other.pupil
          result = self.pupil <=> other.pupil
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

  def owner_id
    self.ad_hoc_domain_staff.id
  end
end
