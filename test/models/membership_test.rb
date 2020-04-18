require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  setup do
    @element1  = elements(:pupiloneelement)
    @element2  = elements(:pupiltwoelement)
    @element3  = elements(:staffoneelement)
    @group1    = groups(:groupone)
    @group2    = groups(:grouptwo)
  end

  test "two membership records as fixtures" do
    assert_equal 2, Membership.count
  end

  test "can create a valid membership record" do
    membership = Membership.new({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership.valid?
  end

  test "must reference a group" do
    membership = Membership.new({
      element:   @element2,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert_not membership.valid?
  end

  test "must reference an element" do
    membership = Membership.new({
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert_not membership.valid?
  end

  test "must have a start date" do
    membership = Membership.new({
      element:   @element2,
      group:     @group1,
      inverse:   false
    })
    assert_not membership.valid?
  end

  test "reverse dates are rejected" do
    membership = Membership.new({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:  @group1.starts_on - 1.day,
      inverse:   false
    })
    assert_not membership.valid?
  end

  test "can't have two overlapping memberships" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.new({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
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
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:   @group1.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?
    membership2 = Membership.new({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on + 2.days,
      inverse:   false
    })
    assert membership2.valid?
  end

  test "but not one day of overlap" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:   @group1.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.new({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on + 1.day,
      inverse:   false
    })
    assert_not membership2.valid?, "Second membership should not be valid"
    assert membership2.errors.added?(:base,
                                     "Duplicate memberships are not allowed."),
                                     "Message should contain 'Duplicate'"
  end

  test "memberships sort by start date" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.create({
      element:   @element3,
      group:     @group1,
      starts_on: @group1.starts_on + 1.day,
      inverse:   false
    })
    assert membership2.valid?, "Second membership should be valid"
    assert_operator membership1, :<, membership2
  end

  test "and then by end date" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:   @group1.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.create({
      element:   @element3,
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:   @group1.starts_on + 2.days,
      inverse:   false
    })
    assert membership2.valid?, "Second membership should be valid"
    assert_operator membership1, :<, membership2
  end

  test "no end date comes last" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      ends_on:   @group1.starts_on + 1.day,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.create({
      element:   @element3,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership2.valid?, "Second membership should be valid"
    #
    #  We can't just use < because the model doesn't include Comparable.
    #
    assert_equal 1, (membership2 <=> membership1)
  end

  test "two memberships with identical dates should not compare equal" do
    membership1 = Membership.create({
      element:   @element2,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership1.valid?, "Initial membership should be valid"
    membership2 = Membership.create({
      element:   @element3,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert membership2.valid?, "Second membership should be valid"
    assert_not_equal membership1, membership2
  end

  test "group cannot be a member of itself" do
    membership = Membership.create({
      element:   @group1.element,
      group:     @group1,
      starts_on: @group1.starts_on,
      inverse:   false
    })
    assert_not membership.valid?
  end
end
