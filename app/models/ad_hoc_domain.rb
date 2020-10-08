class AdHocDomain < ApplicationRecord
  belongs_to :eventsource
  belongs_to :eventcategory
  belongs_to :datasource, optional: true
  belongs_to :connected_property_element, class_name: "Element", optional: true
  has_and_belongs_to_many :controllers,
                          class_name: "User",
                          join_table: :ad_hoc_domain_controllers
  belongs_to :default_day_shape, class_name: "RotaTemplate", optional: true

  has_and_belongs_to_many :subject_elements,
                          class_name: "Element",
                          association_foreign_key: :subject_element_id,
                          join_table: :ad_hoc_domain_subjects

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
    connected_property_element ? connected_property_element.name : ""
  end

  def connected_property_element_name=(new_name)
    # Do nothing
  end

end
