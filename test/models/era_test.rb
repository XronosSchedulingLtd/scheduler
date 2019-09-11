require 'test_helper'

class EraTest < ActiveSupport::TestCase

  setup do
    @valid_attributes = {
      name:          'A jolly useful era',
      short_name:    'Useful era',
      starts_on:     Date.today,
      ends_on:       Date.tomorrow
    }
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

  test 'era requires an end date' do
    era = Era.new(@valid_attributes.except(:ends_on))
    assert_not era.valid?
  end

  test 'end date cannot be before start date' do
    era = Era.new(@valid_attributes.merge({ends_on: Date.yesterday}))
    assert_not era.valid?
  end

end
