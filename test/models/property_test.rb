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

end
