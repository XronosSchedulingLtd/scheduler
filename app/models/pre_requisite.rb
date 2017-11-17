class PreRequisite < ActiveRecord::Base
  belongs_to :element

  validates :element, presence: true

  def field_id
    "element-#{self.element_id}"
  end

  def label_text
    if self.label.blank?
      self.element.short_name
    else
      self.label
    end
  end

  def element_name
    element ? element.name : ""
  end

  def element_name=(name)
    #
    #  Do nothing.
    #
  end
end