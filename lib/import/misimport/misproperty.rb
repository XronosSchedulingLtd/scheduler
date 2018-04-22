class MIS_Property
  attr_reader :element_id

  def initialize(property)
    @element_id = property.element.id
  end
end
