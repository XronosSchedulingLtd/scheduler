# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class PreRequisite < ActiveRecord::Base
  belongs_to :element

  validates :element, presence: true

  scope :pre_creation, -> { where(pre_creation: true) }
  scope :quick_button, -> { where(quick_button: true) }

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
