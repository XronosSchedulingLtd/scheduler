require 'test_helper'

class CommitmentTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @location = FactoryBot.create(:location)
    @valid_params = {
      event: @event,
      element: @location.element
    }
  end

  test "can create commitment with valid params" do
    commitment = Commitment.create(@valid_params)
    assert commitment.valid?, "Testing commitment valid"
  end

  test "commitment requires event" do
    commitment = Commitment.create(@valid_params.merge(event: nil))
    assert_not commitment.valid?
  end

  test "commitment requires element" do
    commitment = Commitment.create(@valid_params.merge(element: nil))
    assert_not commitment.valid?
  end

  test "commitment must be unique" do
    commitment1 = Commitment.create(@valid_params)
    assert commitment1.valid?
    commitment2 = Commitment.create(@valid_params)
    assert_not commitment2.valid?
  end
end


