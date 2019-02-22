require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  setup do
    @element1  = elements(:pupiloneelement)
    @element2  = elements(:pupiltwoelement)
    @group     = groups(:groupone)
  end

  test "two membership records as fixtures" do
    assert_equal 2, Membership.count
  end

  test "can create a valid membership record" do
    membership = Membership.new({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      inverse:   false
    })
    assert membership.valid?
  end

  test "reverse dates are rejected" do
    membership = Membership.new({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      ends_on:  @group.starts_on - 1.day,
      inverse:   false
    })
    assert_not membership.valid?
  end

  test "can't have two overlapping memberships" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.new({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      inverse:   false
    })
    assert_not membership2.valid?, "Second membership should not be valid"
    assert membership2.errors.added?(:base,
                                     "Duplicate memberships are not allowed."),
                                     "Message should contain 'Duplicate'"
  end

  test "consecutive is ok" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      ends_on:   @group.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?
    membership2 = Membership.new({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on + 2.days,
      inverse:   false
    })
    assert membership2.valid?
  end

  test "but not one day of overlap" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on,
      ends_on:   @group.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.new({
      element:   @element2,
      group:     @group,
      starts_on: @group.starts_on + 1.day,
      inverse:   false
    })
    assert_not membership2.valid?, "Second membership should not be valid"
    assert membership2.errors.added?(:base,
                                     "Duplicate memberships are not allowed."),
                                     "Message should contain 'Duplicate'"
  end

end
