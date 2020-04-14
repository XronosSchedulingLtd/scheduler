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

  test 'must have an entity' do
    #
    #  Normally an element record is created automatically every
    #  time an entity is created.
    #
    #  It's hard to create an entity without an element, but it can
    #  be done provided the entity has a real "active" field in the
    #  database.  Locations do.
    #
    element = Element.new
    assert_not element.valid?
    assert_equal "must exist", element.errors.messages[:entity][0]
    location = FactoryBot.create(:location, active: false)
    assert_not location.active?
    assert_nil location.element
    #
    #  Wouldn't normally do this.  We normally just set the active
    #  flag to true on the entity and then save the entity which
    #  will cause an element to be created to match.  What I'm doing
    #  her is just demonstrating that the element becomes valid if
    #  it is linked to an entity - even if the two don't really belong
    #  together.
    #
    element.entity = location
    assert element.valid?
  end

  test 'can have memberships attached' do
    element = FactoryBot.create(:element)
    element.memberships << m1 = FactoryBot.create(:membership, element: element)
    element.memberships << m2 = FactoryBot.create(:membership, element: element)
    element.memberships << m3 = FactoryBot.create(:membership, element: element)
    assert_equal 3, element.memberships.count
    element.destroy
    assert m1.destroyed?
    assert m2.destroyed?
    assert m3.destroyed?
  end

  test 'can have commitments attached' do
    element = FactoryBot.create(:element)
    element.commitments << c1 = FactoryBot.create(:commitment, element: element)
    element.commitments << c2 = FactoryBot.create(:commitment, element: element)
    element.commitments << c3 = FactoryBot.create(:commitment, element: element)
    assert_equal 3, element.commitments.count
    element.destroy
    assert c1.destroyed?
    assert c2.destroyed?
    assert c3.destroyed?
  end
if false
  test 'can have proto_commitments attached' do
    element = FactoryBot.create(:element)
    element.proto_commitments <<
      pc1 = FactoryBot.create(:proto_commitment, element: element)
    element.proto_commitments <<
      pc2 = FactoryBot.create(:proto_commitment, element: element)
    element.proto_commitments <<
      pc3 = FactoryBot.create(:proto_commitment, element: element)
    assert_equal 3, element.proto_commitments.count
    element.destroy
    assert pc1.destroyed?
    assert pc2.destroyed?
    assert pc3.destroyed?
  end
end

  test 'can have requests attached' do
    element = FactoryBot.create(:element)
    element.requests << r1 = FactoryBot.create(:request, element: element)
    element.requests << r2 = FactoryBot.create(:request, element: element)
    element.requests << r3 = FactoryBot.create(:request, element: element)
    assert_equal 3, element.requests.count
    assert_equal 3, element.requested_events.count
    element.destroy
    assert r1.destroyed?
    assert r2.destroyed?
    assert r3.destroyed?
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
