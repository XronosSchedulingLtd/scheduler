require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  setup do
    @service1   = services(:one)
    @service2   = services(:two)
  end

  test "creating a service should create a corresponding element" do
    service = Service.create({
      name: "Random service",
      current:  true,
      add_directly: true
    })
    service.reload
    assert_not_nil service.element
  end

  test "created element should not have preferred colour by default" do
    service = Service.create({
      name: "Random service",
      current:  true,
      add_directly: true
    })
    service.reload
    assert_nil service.element.preferred_colour
  end

  test "specifying a preferred colour should add it to element" do
    service = Service.create({
      name: "Random service",
      current:  true,
      add_directly: true,
      edit_preferred_colour: "red"
    })
    service.reload
    assert_equal "red", service.element.preferred_colour
  end

  test "updating entity should not change element colour" do
    org_colour = @service1.element.preferred_colour
    @service1.name = "Banana"
    @service1.save
    @service1.reload
    assert_equal org_colour, @service1.element.preferred_colour
  end

  test "explicitly changing colour should change element colour" do
    org_colour = @service1.element.preferred_colour
    @service1.edit_preferred_colour = "Banana"
    @service1.save
    @service1.reload
    assert_not_equal org_colour, @service1.element.preferred_colour
  end

  test "can remove preferred colour" do
    @service1.edit_preferred_colour = ""
    @service1.save
    @service1.reload
    assert_nil @service1.element.preferred_colour
  end
end
