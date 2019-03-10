require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  setup do
    @era = FactoryBot.create(:era)
    @group = FactoryBot.create(:group)
    @valid_attributes = {
      name:          'A useful group',
      era:           @era,
      starts_on:     @era.starts_on,
      persona_class: 'Vanillagrouppersona'
    }

  end

  test 'can create a valid group' do
    group = Group.new(@valid_attributes)
    assert group.valid?
  end

  test 'group requires a name' do
    group = Group.new(@valid_attributes.except(:name))
    assert_not group.valid?
  end

  test 'group requires an era' do
    group = Group.new(@valid_attributes.except(:era))
    assert_not group.valid?
  end

  test 'group requires a start date' do
    group = Group.new(@valid_attributes.except(:starts_on))
    assert_not group.valid?
  end

  test 'group requires a persona' do
    group = Group.new(@valid_attributes.except(:persona_class))
    assert_not group.valid?
  end

  test 'group should allow an end date' do
    group = Group.new(
      @valid_attributes.merge({ends_on: @era.starts_on + 1.day}))
    assert group.valid?
  end

  test 'end date cannot be before start date' do
    group = Group.new(
      @valid_attributes.merge({ends_on: @era.starts_on - 1.day}))
    assert_not group.valid?
  end

  test 'group should gain an element on creation' do
    group = Group.create(@valid_attributes)
    assert group.valid?
    assert_not_nil group.element
  end

  test 'element name should be the same as group name' do
    group = Group.create(@valid_attributes)
    assert_not_nil group.element
    assert_equal group.element.name, group.name
  end

  test 'element name should change when group name changes' do
    group = Group.create(@valid_attributes)
    assert_not_nil group.element
    assert_equal group.element.name, group.name
  end

  test 'group should recognize immediate members' do
    location = FactoryBot.create(:location)
    assert @group.add_member(location.element), 'Should be able to add member'
    assert @group.member?(location)
    assert_not @group.member?(location, Date.yesterday)
  end

  test 'can both add and remove members' do
    location = FactoryBot.create(:location)
    assert @group.add_member(location.element), 'Should be able to add member'
    assert @group.member?(location)
    assert @group.remove_member(location.element), 'Should be able to remove member'
    assert_not @group.member?(location)
  end

  test 'can be a member for a limited time' do
    location = FactoryBot.create(:location)
    joining_date = Date.today
    #
    #  This will give 4 days of membership.  The ends_on date gets set
    #  to one less than we provide here.
    #
    #  Thus if joining_date is 1/5/2019, leaving date will be set to 5/5/2019,
    #  but the ends_on will be set to 4/5/2019.
    #
    leaving_date = joining_date + 4.days
    assert @group.add_member(location.element, joining_date), 'Should be able to add member'
    assert @group.remove_member(location.element, leaving_date), 'Should be able to remove member'
    assert_not @group.member?(location, joining_date - 1.day)
    assert     @group.member?(location, joining_date)
    assert     @group.member?(location, leaving_date - 1.day)
    assert_not @group.member?(location, leaving_date)
  end

  test 'can have an explicit outcast' do
    location = FactoryBot.create(:location)
    assert     @group.add_outcast(location)
    assert     @group.outcast?(location)
    assert_not @group.outcast?(location, Date.yesterday)
  end

  test 'can add and remove an outcast' do
    location = FactoryBot.create(:location)
    assert     @group.add_outcast(location)
    assert     @group.outcast?(location)
    assert     @group.remove_outcast(location)
    assert_not @group.outcast?(location)
  end

  test 'a group can be a member of a group' do
    group2 = FactoryBot.create(:group)
    assert_not_nil group2.element
    @group.add_member(group2)
    assert @group.member?(group2)
  end

  test 'membership can be nested' do
    location = FactoryBot.create(:location)
    group2 = FactoryBot.create(:group)
    assert group2.add_member(location)
    @group.add_member(group2)
    assert @group.member?(group2)
    #
    #  Next line asks for members other than groups.
    #
    assert_not @group.members(nil, true, true).include?(group2)
    assert @group.member?(location)
    #
    #  Next line suppresses recursion.
    #
    assert_not @group.member?(location, nil, false)
  end

  test 'group inclusion can be overridden by individual exclusion' do
    location1 = FactoryBot.create(:location)
    location2 = FactoryBot.create(:location)
    group2 = FactoryBot.create(:group)
    assert     group2.add_member(location1)
    assert     group2.add_member(location2)
    assert     @group.add_member(group2)
    assert     @group.member?(location1)
    assert     @group.member?(location2)
    assert     @group.add_outcast(location1)
    assert_not @group.member?(location1)
    assert     group2.member?(location1)
    assert     @group.member?(location2)
  end

  test 'group exclusion can be overridden by individual inclusion' do
    location1 = FactoryBot.create(:location)
    location2 = FactoryBot.create(:location)
    group2    = FactoryBot.create(:group)
    assert     group2.add_member(location1)
    assert     group2.add_member(location2)
    assert     @group.add_outcast(group2)
    assert_not @group.member?(location1)
    assert_not @group.member?(location2)
    assert     @group.add_member(location1)
    assert     @group.member?(location1)
    assert_not @group.member?(location2)
  end

  test 'group exclusion overrides group inclusion' do
    location1 = FactoryBot.create(:location)
    location2 = FactoryBot.create(:location)
    location3 = FactoryBot.create(:location)
    group2    = FactoryBot.create(:group)
    group3    = FactoryBot.create(:group)
    #
    #  All locations are members of group 2
    #
    assert group2.add_member(location1)
    assert group2.add_member(location2)
    assert group2.add_member(location3)
    #
    #  But only location 2 is a member of group 3.
    #
    assert group3.add_member(location2)
    #
    #  Now group2 are in @group, but group3 is excluded.
    #
    assert @group.add_member(group2)
    assert @group.add_outcast(group3)
    #
    #  And the consequence is.
    #
    assert     @group.member?(location1)
    assert_not @group.member?(location2)
    assert     @group.member?(location3)
  end

  test 'members can be added in the future' do
    location1 = FactoryBot.create(:location)
    assert @group.add_member(location1, Date.tomorrow)
    #
    #  Not today
    #
    assert_not @group.member?(location1), 'not today'
    #
    #  But it will be tomorrow
    #
    assert @group.member?(location1, Date.tomorrow), 'but tomorrow'
    #
    #  And just generally in the future from today
    #
    assert @group.member?(location1, Date.today, true, true), 'and in the future'
    #
    #  And check all the same with recursion turned off.  It's a different
    #  path through the model code.
    #
    assert_not @group.member?(location1, nil, false), 'not today'
    #
    #  But it will be tomorrow
    #
    assert @group.member?(location1, Date.tomorrow, false), 'but tomorrow'
    #
    #  And just generally in the future from today
    #
    assert @group.member?(location1, Date.today, false, true), 'and in the future'
  end

end
