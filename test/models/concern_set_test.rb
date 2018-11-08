require 'test_helper'

class ConcernSetTest < ActiveSupport::TestCase
  setup do
    @user   = users(:one)
  end

  test "can create a concern set" do
    cs = ConcernSet.create({
      name: "Banana",
      owner: @user
    })
    assert cs.valid?
  end
end
