require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location, weighting: 150)
    @location2 = FactoryBot.create(:location)
    @location3 = FactoryBot.create(:location, weighting: 130)
    @location4 = FactoryBot.create(:location, weighting: 129)
    @all_locations = [@location1, @location2, @location3, @location4]
    @included_locations = [@location1, @location3]
    @excluded_locations = [@location2, @location4]

    @event = FactoryBot.create(:event, commitments_to: @all_locations)
  end

  test "should have a viewable flag" do
    element = FactoryBot.create(:element)
    assert element.respond_to?(:viewable?)
  end

  test "locations_for_ical should return locations" do
    locations = @event.locations_for_ical(nil)
    assert_equal @all_locations.size, locations.size
    @all_locations.each do |l|
      assert locations.include?(l)
    end
  end

  test "locations_for_ical should observe weighting and spread" do
    locations = @event.locations_for_ical(20)
    assert_equal @included_locations.size, locations.size
    @included_locations.each do |l|
      assert locations.include?(l)
    end
    @excluded_locations.each do |l|
      assert_not locations.include?(l)
    end
  end

end
