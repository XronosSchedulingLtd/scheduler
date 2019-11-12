require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location)
    @inactive_location = FactoryBot.create(:location, active: false)
  end

  test "creating an active location should create an element" do
    location = Location.create(name: "Googol", active: true)
    assert_not_nil location.element
  end

  test "creating an inactive location should not create an element" do
    location = Location.create(name: "Googol", active: false)
    assert_nil location.element
  end

  test "changing location to active should create element" do
    assert_nil @inactive_location.element
    @inactive_location.active = true
    @inactive_location.save!
    assert_not_nil @inactive_location.element
  end

  test "modifying location name should change element name" do
    org_name = @location1.element.name
    @location1.name = "Banana"
    @location1.save
    assert_not_equal org_name, @location1.element.name
  end

  test "number of invigilators defaults to one" do
    assert_equal 1, @location1.num_invigilators
  end

  test "must have a number of invigilators" do
    location = Location.create(name: "Googol", num_invigilators: nil)
    assert_not location.valid?
  end
end
