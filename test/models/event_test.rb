require 'test_helper'

class EventTest < ActiveSupport::TestCase
  setup do
    @eventcategory = FactoryBot.create(:eventcategory)
    @eventsource   = FactoryBot.create(:eventsource)
    @confidential_ec = FactoryBot.create(:eventcategory, confidential: true)
    @property = FactoryBot.create(:property)
    @location = FactoryBot.create(:location)
    @valid_params = {
      body: "A test event",
      eventcategory: @eventcategory,
      eventsource: @eventsource,
      starts_at: Time.zone.now,
      ends_at: Time.zone.now + 1.hour
    }
  end

  test "event factory can add commitments" do
    event = FactoryBot.create(:event, commitments_to: [@property, @location])
    assert_equal 2, event.resources.count
  end

  test "event factory can add requests" do
    event = FactoryBot.create(:event, requests_for: { @property => 2 })
    assert_equal 1, event.requests.count
    assert_equal 2, event.requests[0].quantity
  end

  test "should have a confidential flag" do
    event = FactoryBot.create(:event)
    assert event.respond_to?(:confidential?)
  end

  test "confidential flag should mirror that in event category" do
    event = FactoryBot.create(:event, eventcategory: @eventcategory)
    assert_not event.confidential?
    event = FactoryBot.create(:event, eventcategory: @confidential_ec)
    assert event.confidential?
  end

  test "can create an event" do
    e = Event.create(@valid_params)
    assert e.valid?
  end

  test "must have a body" do
    e = Event.create(@valid_params.except(:body))
    assert_not e.valid?
  end

  test "must have an eventcategory" do
    e = Event.create(@valid_params.except(:eventcategory))
    assert_not e.valid?
  end

  test "must have an eventsource" do
    e = Event.create(@valid_params.except(:eventsource))
    assert_not e.valid?
  end

  test "must have a starts_at" do
    e = Event.create(@valid_params.except(:starts_at))
    assert_not e.valid?
  end

  test "beginning scope has correct cut off" do
    tomorrow_midnight = Date.today + 2.days
    e = Event.create({
      body: "A test event",
      eventcategory: @eventcategory,
      eventsource: @eventsource,
      starts_at: Time.zone.now,
      ends_at: tomorrow_midnight
    })
    assert e.valid?
    assert_equal 1, Event.beginning(Date.today).count
    assert_equal 1, Event.beginning(Date.tomorrow).count
    assert_equal 0, Event.beginning(Date.today + 2.days).count
  end

  test "can add simple commitments" do
    event = FactoryBot.create(:event)
    staff = FactoryBot.create(:staff)
    commitment = event.commitments.create({
      element: staff.element
    })
    assert commitment.valid?
    assert_equal 1, event.staff.count
  end

  test "cloning an event clones simple commitments" do
    event = FactoryBot.create(:event)
    staff = FactoryBot.create(:staff)
    user = FactoryBot.create(:user)
    commitment = event.commitments.create({
      element: staff.element
    })
    assert commitment.valid?
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?
    assert_equal 1, new_event.commitments.size
    assert_not_equal event.commitments.first, new_event.commitments.first
  end

  test "cloning an event clones requests" do
    event = FactoryBot.create(:event)
    resourcegroup = FactoryBot.create(:resourcegroup)
    user = FactoryBot.create(:user)
    request = event.requests.create({
      element: resourcegroup.element,
      quantity: 1
    })
    assert request.valid?
    #
    #    This reload shouldn't be necessary, but there appears to be
    #    a bug in ActiveRecord which makes the request appear twice
    #    in the array.  The count is 1, but the size is 2 and if you
    #    iterate through then the same record appears twice.
    #
    event.reload
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?
    assert_equal 1, new_event.requests.size
    assert_not_equal event.requests.first, new_event.requests.first
  end

  test "cloning an event does not copy commitment fulfilling request" do
    event = FactoryBot.create(:event)
    resourcegroup = FactoryBot.create(:resourcegroup)
    resource1 = FactoryBot.create(:service)
    resource2 = FactoryBot.create(:service)
    resourcegroup.add_member(resource1)
    resourcegroup.add_member(resource2)
    assert_equal 2, resourcegroup.members.size

    user = FactoryBot.create(:user)
    request = event.requests.create({
      element: resourcegroup.element,
      quantity: 2
    })
    assert request.valid?
    request.fulfill(resource1.element)
    assert_equal 1, request.num_allocated, "Num allocated"
    assert_equal 1, request.num_outstanding, "Num outstanding"

    #
    #    This reload shouldn't be necessary, but there appears to be
    #    a bug in ActiveRecord which makes the request appear twice
    #    in the array.  The count is 1, but the size is 2 and if you
    #    iterate through then the same record appears twice.
    #
    event.reload
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?

    new_request = new_event.requests.first
    #
    #  num_allocated makes use of the cached commitment count in the
    #  request record.  Make sure that matches reality with a forced
    #  d/b access to get the real count.
    #
    assert_equal new_request.commitments.count, new_request.num_allocated, "Checking cached count"
    assert_equal 0, new_request.num_allocated
    assert_equal 2, new_request.num_outstanding

    assert new_event.commitments.empty?
  end

  test "make_to_match brings over new commitments" do
    event = FactoryBot.create(:event)
    staff1 = FactoryBot.create(:staff)
    staff2 = FactoryBot.create(:staff)
    user = FactoryBot.create(:user)
    commitment1 = event.commitments.create({
      element: staff1.element
    })
    assert commitment1.valid?
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?
    assert_equal 1, new_event.commitments.size
    assert_not_equal event.commitments.first, new_event.commitments.first
    commitment2 = event.commitments.create({
      element: staff2.element
    })
    assert commitment2.valid?
    assert_equal 2, event.commitments.size, "Commitments on original event"
    assert_equal 1, new_event.commitments.size
    new_event.make_to_match(user, event)
    assert_equal 2, new_event.commitments.size, "Commitments on new event"
  end

  test "make_to_match brings over new requests" do
    event = FactoryBot.create(:event)
    resourcegroup1 = FactoryBot.create(:resourcegroup)
    resourcegroup2 = FactoryBot.create(:resourcegroup)
    user = FactoryBot.create(:user)
    request1 = event.requests.create({
      element: resourcegroup1.element,
      quantity: 1
    })
    assert request1.valid?
    #
    #    This reload shouldn't be necessary, but there appears to be
    #    a bug in ActiveRecord which makes the request appear twice
    #    in the array.  The count is 1, but the size is 2 and if you
    #    iterate through then the same record appears twice.
    #
    event.reload
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?
    request2 = event.requests.create({
      element: resourcegroup2.element,
      quantity: 1
    })
    assert_equal 2, event.requests.size, "Requests on original event"
    assert_equal 1, new_event.requests.size
    new_event.make_to_match(user, event)
    assert_equal 2, new_event.requests.size, "Requests on new event"
  end

  test "make_to_match does not copy commitment filling request" do
    event = FactoryBot.create(:event)
    resourcegroup1 = FactoryBot.create(:resourcegroup)
    resource1 = FactoryBot.create(:service)
    user = FactoryBot.create(:user)
    request1 = event.requests.create({
      element: resourcegroup1.element,
      quantity: 2
    })
    assert request1.valid?
    #
    #    This reload shouldn't be necessary, but there appears to be
    #    a bug in ActiveRecord which makes the request appear twice
    #    in the array.  The count is 1, but the size is 2 and if you
    #    iterate through then the same record appears twice.
    #
    event.reload
    new_event = event.clone_and_save(user, {})
    assert new_event.valid?

    request1.fulfill(resource1.element)
    assert_equal 1, request1.num_allocated, "Num allocated"
    assert_equal 1, request1.num_outstanding, "Num outstanding"

    new_event.make_to_match(user, event)

    new_request = new_event.requests.first
    assert_equal 0, new_request.num_allocated
    assert_equal 2, new_request.num_outstanding

    assert new_event.commitments.empty?

  end

  #
  #  Leave this test at the end.  It needs investigating at some point.
  #
#  test "odd bug in ActiveRecord" do
    #
    #  Note, we're testing that the bug *does* exist.
    #
    #  This test is left here for documentary purposes.  So far I've
    #  failed to spot why this happens with requests but not with commitments.
    #
    #  I have observed this kind of behaviour before but failed to
    #  record the exact circumstances which produced hit.  Hence
    #  I'm recording it here, so I can compare the next time I come
    #  across it.
    #
#    event = FactoryBot.create(:event)
#    resourcegroup = FactoryBot.create(:resourcegroup)
#    user = FactoryBot.create(:user)
#    request = event.requests.create({
#      element: resourcegroup.element,
#      quantity: 1
#    })
#    assert request.valid?
#    assert_equal 2, event.requests.size, "requests.size"
#    assert_equal 1, event.requests.count, "requests.count"
#    count = 0
#    event.requests.each do |request|
#      count += 1
#    end
#    assert_equal 2, count, "Count of requests"
    #
    #  And try it with commitments
    #
#    staff = FactoryBot.create(:staff)
#    commitment = event.commitments.create({
#      element: staff.element
#    })
#    assert commitment.valid?
#    assert_equal 1, event.commitments.count, "Size of commitments"
#    count = 0
#    event.commitments.each do |commitment|
#      count += 1
#    end
#    assert_equal 1, count, "Count of commitments"
#  end

end
