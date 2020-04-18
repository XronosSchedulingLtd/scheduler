#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  setup do
    @entity_class = Service
    @service1   = services(:one)
    @service2   = services(:two)
    @valid_params = {
      name:    "Random service",
      current: true
    }
  end

  include CommonEntityTests

  test "add_directly defaults to true" do
    service = Service.create(@valid_params)
    service.reload
    assert service.element.add_directly?
  end

  test "add_directly can be set to false" do
    service = Service.create(@valid_params.merge({add_directly: false}))
    service.reload
    assert_not service.element.add_directly?
  end

end
