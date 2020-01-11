require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  setup do
    @location1 = FactoryBot.create(:location, weighting: 150)
    @location2 = FactoryBot.create(:location)
    @location3 = FactoryBot.create(:location, weighting: 130)
    @location4 = FactoryBot.create(:location, weighting: 129)
    @all_locations = [@location1, @location2, @location3, @location4]
    @heavy_locations = [@location1, @location3]
    @light_locations = [@location2, @location4]

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
    assert_equal @heavy_locations.size, locations.size
    @heavy_locations.each do |l|
      assert locations.include?(l)
    end
    @light_locations.each do |l|
      assert_not locations.include?(l)
    end
  end

  test "locations_for_ical should observe subsidiarity" do
    @location2.subsidiary_to = @location1
    @location2.save
    @location4.subsidiary_to = @location1
    @location4.save
    locations = @event.locations_for_ical(nil)
    assert_equal 2, locations.size
  end

  test "subsidiarity check works even if non-continuous" do
    @location2.subsidiary_to = @location1
    @location2.save
    @location3.subsidiary_to = @location2
    @location3.save
    local_event = FactoryBot.create(:event,
                                    commitments_to: [@location1, @location3])
    locations = local_event.locations_for_ical(nil)
    assert_equal 1, locations.size
    assert locations.include?(@location1)
  end

end
