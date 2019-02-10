require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  setup do
    @event1   = events(:one)
    @event2   = events(:two)
  end

  test "can create an event" do
    e = Event.create({
      body: "A test event",
      eventcategory: eventcategories(:one),
      eventsource: eventsources(:one),
      starts_at: Time.zone.now
    })
    assert e.valid?
  end

  test "beginning scope has correct cut off" do
    tomorrow_midnight = Date.today + 2.days
    e = Event.create({
      body: "A test event",
      eventcategory: eventcategories(:one),
      eventsource: eventsources(:one),
      starts_at: Time.zone.now,
      ends_at: tomorrow_midnight
    })
    assert e.valid?
    assert_equal 1, Event.beginning(Date.today).count
    assert_equal 1, Event.beginning(Date.tomorrow).count
    assert_equal 0, Event.beginning(Date.today + 2.days).count
  end
end
