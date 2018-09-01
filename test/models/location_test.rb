require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  setup do
    @location1 = locations(:roomone)
    @aliasedroom = locations(:aliasedroom)
  end

  test "creating an active location should create an element" do
    location = Location.create(name: "Googol", active: true)
    assert_not_nil location.element
  end

  test "creating an inactive location should not create an element" do
    location = Location.create(name: "Googol", active: false)
    assert_nil location.element
  end

  test "modifying location name should change element name" do
    org_name = @location1.element.name
    @location1.name = "Banana"
    @location1.save
    assert_not_equal org_name, @location1.element.name
  end

  test "saving location should modify element name" do
    #
    #  The location already has a display alias, but the element name
    #  (as set up through fixtures) does not reflect this.
    #
    org_name = @aliasedroom.element.name
    @aliasedroom.save
    assert_not_equal org_name, @aliasedroom.element.name
  end
end
