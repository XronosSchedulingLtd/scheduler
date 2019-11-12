require 'test_helper'

class LocationaliasTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location)
  end

  test "should require a name" do
    locationalias = Locationalias.new(name: "", location: @location1)
    assert_not locationalias.valid?
  end

  test "should allow a valid locationalias" do
    locationalias = Locationalias.new(name: "Banana", location: @location1)
    assert locationalias.valid?
  end

  test "creating display locationalias should modify name" do
    org_name = @location1.element.name
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    assert_not_equal org_name, @location1.element.name
  end

  test "creating non-display locationalias should not modify name" do
    org_name = @location1.element.name
    locationalias = Locationalias.create(name: "Banana",
                                         display: false,
                                         location: @location1)
    assert_equal org_name, @location1.element.name
  end

  test "modifying alias should modify name" do
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    org_name = @location1.element.name
    locationalias.name = "Fritter"
    locationalias.save
    assert_not_equal org_name, @location1.element.name
  end

  test "deleting alias should modify name" do
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    org_name = @location1.element.name
    locationalias.destroy
    assert_not_equal org_name, @location1.element.name
  end

  test "creating an alias should create a location" do
    locationalias = Locationalias.create(name: "Google",
                                         display: false)
    assert_not_nil locationalias.location
  end

  test "automatic location should have an element" do
    locationalias = Locationalias.create(name: "Google",
                                         display: false)
    assert_not_nil locationalias.location.element
  end

  test "adding location via alias should create only one element" do
    locationalias = Locationalias.create(name: "Google",
                                         display: false)
    location = locationalias.location
    assert_not_nil location
    elements = Element.where(entity_type: "Location").where(entity_id: location.id)
    assert_equal 1, elements.count
  end
end
