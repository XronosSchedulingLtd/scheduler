#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PropertyTest < ActiveSupport::TestCase

  setup do
    @valid_params = {
      name: "A property"
    }
  end

  test "can create a property" do
    property = Property.new(@valid_params)
    assert property.valid?
  end

  test "name is required" do
    property = Property.new(@valid_params.except(:name))
    assert_not property.valid?
  end

  test "name must be unique" do
    property1 = Property.create(@valid_params)
    assert property1.valid?
    property2 = Property.create(@valid_params)
    assert_not property2.valid?
  end

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
