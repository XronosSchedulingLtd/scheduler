require 'test_helper'

class ConcernTest < ActiveSupport::TestCase

  setup do
    @user1 = users(:one)
    @element1 = elements(:one)
  end

  test "Can create a concern" do
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert c.valid?
  end

  test "Each concern must belong to a user" do
    c = Concern.create({
      element: @element1,
      colour:  "red"
    })
    assert_not c.valid?
  end

  test "Each concern must have an element" do
    c = Concern.create({
      user:    @user1,
      colour:  "red"
    })
    assert_not c.valid?
  end

  test "Each concern must have a colour" do
    c = Concern.create({
      element: @element1,
      user:    @user1
    })
    assert_not c.valid?
  end

  test "Can't create two identical concerns in the default set" do
    c1 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    c2 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert c1.valid?
    assert_not c2.valid?
  end

end
