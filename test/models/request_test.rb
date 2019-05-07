require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @resource_group = FactoryBot.create(:resourcegroup)
    @valid_params = {
      event: @event,
      element: @resource_group.element
    }
  end

  test "can create request with valid params" do
    request = Request.create(@valid_params)
    assert request.valid?, "Testing request valid"
  end

  test "request requires event" do
    request = Request.create(@valid_params.merge(event: nil))
    assert_not request.valid?
  end

  test "request requires element" do
    request = Request.create(@valid_params.merge(element: nil))
    assert_not request.valid?
  end

  test "request must be unique" do
    request1 = Request.create(@valid_params)
    assert request1.valid?
    request2 = Request.create(@valid_params)
    assert_not request2.valid?
  end
end


