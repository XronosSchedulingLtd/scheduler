require 'test_helper'

class EventSummaryTest < ActiveSupport::TestCase

  setup do
    @simple_property = FactoryBot.create(:property, name: "Simple property")
    @property_owner = FactoryBot.create(:user,
                                        user_profile: UserProfile.staff_profile)
    @owned_property = FactoryBot.create(:property,
                                        owner: @property_owner,
                                        name: "Owned property")
    @owned_property.element.reload
    @minibuses = FactoryBot.create(:group,
                                   name: "Minibus",
                                   chosen_persona: 'Resourcegrouppersona')
    @mobile1 = FactoryBot.create(:service, name: "Mobile 1")
    @mobiles = FactoryBot.create(:group,
                                 name: "Mobile phone",
                                 chosen_persona: 'Resourcegrouppersona')
    @mobiles.add_member(@mobile1)
    @event_owner = FactoryBot.create(:user,
                                     user_profile: UserProfile.staff_profile)
    @event = FactoryBot.create(:event,
                               owner: @event_owner,
                               commitments_to: [@simple_property, @owned_property],
                               requests_for: {
                                 @minibuses => 2,
                                 @mobiles => 1
                               } )
    #
    #  See the event model test for an explanation of why we reload here.
    #  The bug appears to be fixed in ActiveRecord in Rails 5 so once
    #  we migrate to Rails 5 we can remove this.
    #
    @event.reload
    #
    #  Now fulfil the request for a minibus.
    #
    mb_request = @event.requests.find {|r| r.element == @mobiles.element}
    mb_request.fulfill(@mobile1.element)
    mb_request.reload
    @event_summary = EventSummary.new(@event)
  end

  test "can create event summary" do
    event_summary = EventSummary.new(@event)
    assert_not event_summary.nil?
  end

  test "implements respond_to? for event methods" do
    assert @event_summary.respond_to?(:complete)
    assert @event_summary.respond_to?(:starts_at)
    assert_not @event_summary.respond_to?(:banana_fritter)
  end

  test "passes through requests to event" do
    assert_not @event_summary.complete?
    assert_raise(Exception) {
      @event_summary.banana_fritter
    }
  end

  test "supplies a partial path" do
    assert_equal 'event_summary', EventSummary.new(@event).to_partial_path
  end

  test "can list simple resource elements" do
    assert_equal 1, @event_summary.simple_resource_elements.size
  end

  test "can find all commitment elements" do
    assert_equal 3, @event_summary.all_commitment_elements_regardless.size
  end

  test "can find all request elements" do
    assert_equal 2, @event.requests.count
    assert_equal 2, @event_summary.all_request_elements_regardless.size
  end

  test "resource request has correct count" do
    assert_equal 2, @event.requests.first.quantity
  end

  test "can find all resource elements" do

    assert_equal 5, @event_summary.all_resource_elements_regardless.size
  end

  test "can find all controlled commitments" do
    assert_equal 1, @event_summary.controlled_commitments.size
  end

  test "can find all other commitments" do
    assert_equal 1, @event_summary.other_commitments.size
  end

  test "can find all requests" do
    assert_equal 2, @event_summary.requests.size
  end

  test "can find fulfilled requests" do
    assert_equal 1, @event_summary.fulfilled_requests.size
  end

  test "can find commitments resulting from requests" do
    assert_equal 1, @event_summary.request_commitments.size
    assert_equal @mobile1.element, @event_summary.request_commitments.first.element
  end
end
