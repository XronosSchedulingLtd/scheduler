#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class AdHocDomain < ApplicationRecord
  belongs_to :eventsource
  belongs_to :eventcategory
  belongs_to :datasource, optional: true

#  belongs_to :connected_property_element, class_name: "Element", optional: true

  belongs_to :connected_property, class_name: "Property", optional: true

  has_and_belongs_to_many :controllers,
                          class_name: "User",
                          join_table: :ad_hoc_domain_controllers
  belongs_to :default_day_shape, class_name: "RotaTemplate", optional: true

  has_many :ad_hoc_domain_cycles, dependent: :destroy

  has_many :ad_hoc_domain_subjects, through: :ad_hoc_domain_cycles
  has_many :subjects, through: :ad_hoc_domain_subjects

  has_many :ad_hoc_domain_staffs, through: :ad_hoc_domain_subjects
  has_many :staffs, through: :ad_hoc_domain_staffs

  belongs_to :default_cycle, class_name: "AdHocDomainCycle", optional: true

  validates :name, presence: true

  attr_accessor :new_controller_name, :new_controller_id

  def controller_list
    self.controllers.sort.collect { |u| u.name}.join(", ")
  end

  def eventsource_name
    eventsource ? eventsource.name : ""
  end

  def eventcategory_name
    eventcategory ? eventcategory.name : ""
  end

  def connected_property_element_name
    connected_property&.element ? connected_property.element.name : ""
  end

  def connected_property_element_name=(new_name)
    # Do nothing
  end

  def connected_property_element=(element)
    if element
      if element.entity_type == "Property"
        self.connected_property = element.entity
      end
    else
      self.connected_property = nil
    end
  end

  def connected_property_element_id=(id)
    self.connected_property_element = Element.find_by(id: id)
  end

  def connected_property_element_id
    connected_property&.element ? connected_property.element.id : ""
  end

end
