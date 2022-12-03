#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PropertyTest < ActiveSupport::TestCase

  setup do
    @entity_class = Property
    @valid_params = {
      name: "A property"
    }
  end

  include CommonEntityTests

  test 'name must be unique' do
    property1 = Property.create(@valid_params)
    assert property1.valid?
    property2 = Property.create(@valid_params)
    assert_not property2.valid?
  end

  test 'properties can be made locking' do
    property = FactoryBot.create(:property, locking: true)
    assert property.can_lock?
  end

  test "property can be linked to ad hoc domain" do
    ahd = FactoryBot.create(:ad_hoc_domain)
    property = FactoryBot.create(:property)
    property.ad_hoc_domains << ahd
    ahd.reload
    assert_not_nil ahd.connected_property
    #
    #  And deleting the property should nullify the connection.
    #
    property.destroy
    ahd.reload
    assert_nil ahd.connected_property
  end

  test "can set and change a preferred colour" do
    property = Property.create(
      @valid_params.merge(
        {
          edit_preferred_colour: "green"
        }
      )
    )
    assert property.valid?
    assert_equal "green", property.element.preferred_colour
    property.edit_preferred_colour = "red"
    property.save
    assert_equal "red", property.element.preferred_colour
    #
    #  And make sure the change got saved.
    #
    property.element.reload
    assert_equal "red", property.element.preferred_colour
  end

  test "can set and change a forced colour" do
    property = Property.create(
      @valid_params.merge(
        {
          edit_preferred_colour: "green",
          force_colour: true
        }
      )
    )
    assert property.valid?
    assert_equal "green", property.element.preferred_colour
    assert property.element.force_colour
    property.edit_preferred_colour = "red"
    property.force_colour = false
    property.save
    assert_equal "red", property.element.preferred_colour
    assert_not property.element.force_colour
    #
    #  And make sure the change got saved.
    #
    property.element.reload
    assert_equal "red", property.element.preferred_colour
    assert_not property.element.force_colour
  end


end
