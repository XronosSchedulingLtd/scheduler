require 'test_helper'

class PropertyTest < ActiveSupport::TestCase

  test "creating a property should create an element" do
    property = FactoryBot.create(:property)
    assert_not_nil property.element
  end

  test "can dictate the UUID" do
    chosen_uuid = "Banana fritters"
    property = FactoryBot.create(:property, preferred_uuid: chosen_uuid)
    assert_equal chosen_uuid, property.element.uuid
  end

  test "can dictate the preferred colour" do
    chosen_colour = "blue"
    property = FactoryBot.create(:property, edit_preferred_colour: chosen_colour)
    assert_equal chosen_colour, property.element.preferred_colour
  end

  test "properties are non-locking by default" do
    property = FactoryBot.create(:property)
    assert_not property.can_lock?
  end

  test "properties can be made locking" do
    property = FactoryBot.create(:property, locking: true)
    assert property.can_lock?
  end

end
