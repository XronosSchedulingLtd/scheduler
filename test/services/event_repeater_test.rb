#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class EventRepeaterTest < ActiveSupport::TestCase

  setup do
    @user = FactoryBot.create(:user)
    #
    #  Event defaults to starting now and lasting 1 hour.
    #
    @event = FactoryBot.create(:event)
    #
    #  Event collection defaults to starting today and going on for
    #  a month.  This gives us an unpredictable number of events because
    #  the number of days in a month can vary.  Go for 2 weeks instead.
    #  Only a problem then if tested in France.
    #
    @event_collection =
      FactoryBot.create(
        :event_collection,
        repetition_start_date: Date.today,
        repetition_end_date:   Date.today + 2.weeks,
        weeks: ["A", "B", " "],
        days_of_week: ["0","1","2","3","4","5","6"])
    @event_collection.events << @event
    #
    #  And let's create some week letter definitions.
    #  Start today and run each for 7 days.
    #
    base_date = Date.today
    @weekA1 =
      FactoryBot.create(
        :event,
        starts_at: base_date,
        ends_at: base_date + 7.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week A")
    @weekB1 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 7.days,
        ends_at: base_date + 14.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week B")
    #
    #  1 week gap.  Half term?
    #
    @weekA2 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 21.days,
        ends_at: base_date + 28.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week A")
    @weekB2 =
      FactoryBot.create(
        :event,
        starts_at: base_date + 28.days,
        ends_at: base_date + 35.days,
        all_day: true,
        eventcategory: Eventcategory.cached_category("Week letter"),
        body: "Week B")
  end

  test "can do basic repetition" do
    #
    #  We are going from today to the date two weeks from today, including
    #  both those days.  Hence our repeated event will span 15 days in
    #  total.  We already have one event, so 14 more should be created.
    #
    assert_difference('Event.count', 14) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      assert @event_collection.events.include?(@event)
      assert_equal 15, @event_collection.events.size
    end
  end

  test "can repeat on just one day of week" do
    #
    #  If we repeat on just today's day of the week we should get 2 new
    #  events for a total of 3.
    #
    @event_collection.days_of_week = [Date.today.wday.to_s]
    assert_difference('Event.count', 2) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      assert @event_collection.events.include?(@event)
      assert_equal 3, @event_collection.events.size
    end
  end

  test "can repeat on two days of week" do
    today_wday = Date.today.wday
    other_wday = today_wday + 1
    if other_wday > 6
      other_wday = 0
    end
    @event_collection.days_of_week = [today_wday.to_s, other_wday.to_s]
    assert_difference('Event.count', 4) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      assert @event_collection.events.include?(@event)
      assert_equal 5, @event_collection.events.size
    end
  end

  test "can restrict to week A" do
    @event_collection.weeks = ["A"]
    assert_difference('Event.count', 6) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      assert @event_collection.events.include?(@event)
      assert_equal 7, @event_collection.events.size
    end
  end

  test "can restrict to week B" do
    @event_collection.weeks = ["B"]
    assert_difference('Event.count', 6) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      #
      #  Our original event will have been deleted because it was in
      #  Week A.
      #
      assert_not @event_collection.events.include?(@event)
      assert_equal 7, @event_collection.events.size
    end
  end

  test "monday and wednesday of week A over 5 weeks" do
    @event_collection.weeks = ["A"]
    @event_collection.days_of_week = ["1", "3"]
    @event_collection.repetition_end_date = Date.today + 34.days
    assert_difference('Event.count', 3) do
      assert EventRepeater.effect_repetition(@user, @event_collection, @event)
      @event_collection.reload
      #
      #  Our original event will have been deleted because it was in
      #  Week A.
      #
      assert_not @event_collection.events.include?(@event)
      assert_equal 4, @event_collection.events.size
    end

  end

end
