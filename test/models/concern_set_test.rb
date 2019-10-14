require 'test_helper'

class ConcernSetTest < ActiveSupport::TestCase
  setup do
    @user   = FactoryBot.create(:user)
    @valid_params = {
      name: 'Banana',
      owner: @user
    }
  end

  test "can create a concern set" do
    cs = ConcernSet.create(@valid_params)
    assert cs.valid?
  end

  test "concern set must have an owner" do
    cs = ConcernSet.create(@valid_params.except(:owner))
    assert_not cs.valid?
  end

  test "concern set must have a name" do
    cs = ConcernSet.create(@valid_params.except(:name))
    assert_not cs.valid?
  end

end
