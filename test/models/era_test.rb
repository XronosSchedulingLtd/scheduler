require 'test_helper'

class EraTest < ActiveSupport::TestCase

  setup do
    @valid_attributes = {
      name:          'A jolly useful era',
      short_name:    'Useful era',
      starts_on:     Date.today,
      ends_on:       Date.tomorrow
    }
    @test_era = Era.create(@valid_attributes)
    @staff = FactoryBot.create(:staff)

  end

  test 'can create a valid era' do
    era = Era.new(@valid_attributes)
    assert era.valid?
  end

  test 'era requires a name' do
    era = Era.new(@valid_attributes.except(:name))
    assert_not era.valid?
  end

  test 'era requires a start date' do
    era = Era.new(@valid_attributes.except(:starts_on))
    assert_not era.valid?
  end

  test 'end date cannot be before start date' do
    era = Era.new(@valid_attributes.merge({ends_on: Date.yesterday}))
    assert_not era.valid?
  end

  test 'can have groups' do
    era = Era.create(@valid_attributes)
    era.groups << @group1 = FactoryBot.create(:group)
    era.groups << @group2 = FactoryBot.create(:group)
    era.groups << @group3 = FactoryBot.create(:group)
    assert_equal 3, era.groups.count
    #
    #  And if the era is deleted, they should go too.
    #
    era.destroy
    assert @group1.destroyed?
    assert @group2.destroyed?
    assert @group3.destroyed?
  end

  test 'can have event_collections' do
    era = Era.create(@valid_attributes)
    era.event_collections <<
      @event_collection1 = FactoryBot.create(:event_collection)
    era.event_collections <<
      @event_collection2 = FactoryBot.create(:event_collection)
    era.event_collections <<
      @event_collection3 = FactoryBot.create(:event_collection)
    assert_equal 3, era.event_collections.count
    #
    #  And if the era is deleted, they should go too.
    #
    era.destroy
    assert @event_collection1.destroyed?
    assert @event_collection2.destroyed?
    assert @event_collection3.destroyed?
  end

  test 'can be assigned as the current era' do
    era = Era.create(@valid_attributes)
    #
    #  This is slightly messy.  We have to use the existing Settings
    #  record because there can be only one, but we want to modify it
    #  for our tests.  Need to save things which we change and put them
    #  back afterwards.
    #
    settings = Setting.first
    original_current_era = settings.current_era
    settings.current_era = era
    settings.save
    settings.reload
    assert_equal era, settings.current_era
    era.destroy
    settings.reload
    assert_nil settings.current_era
    #
    #  Need to put this back or other tests will fail.
    #
    settings.current_era = original_current_era
    settings.save
  end

  test 'can filter groups' do
    tug1 = FactoryBot.create(
      :group,
      chosen_persona: Tutorgrouppersona,
      staff: @staff,
      era: @test_era)
    assert tug1.valid?
    teg1 = FactoryBot.create(
      :group,
      chosen_persona: Teachinggrouppersona,
      era: @test_era)
    assert teg1.valid?
    tug2 = FactoryBot.create(
      :group,
      chosen_persona: Tutorgrouppersona,
      staff: @staff,
      era: @test_era)
    teg2 = FactoryBot.create(
      :group,
      chosen_persona: Teachinggrouppersona,
      era: @test_era)
    tug3 = FactoryBot.create(
      :group,
      chosen_persona: Tutorgrouppersona,
      staff: @staff,
      era: @test_era)

    assert_equal 5, @test_era.groups.count
    assert_equal 2, @test_era.teachinggroups.count
    assert_equal 3, @test_era.tutorgroups.count
  end

  test 'groups prevent destruction' do
    era = Era.create(@valid_attributes)
    assert era.can_destroy?
    FactoryBot.create(:group, era: era)
    era.reload
    assert_not era.can_destroy?
  end

  test 'use in settings prevents destruction' do
    era = Era.create(@valid_attributes)
    assert era.can_destroy?
    settings = Setting.first
    original_current_era = settings.current_era
    settings.current_era = era
    settings.save

    era.reload
    assert_not era.can_destroy?

    settings.current_era = original_current_era
    settings.save
  end

end
