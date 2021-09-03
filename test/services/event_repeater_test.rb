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
    #  A couple of locations for the user to own
    #
    @location1 = FactoryBot.create(:location, owner: @user)
    @location2 = FactoryBot.create(:location, owner: @user)
    #
    #  Event defaults to starting now and lasting 1 hour.
    #
    @event = FactoryBot.create(:event)
    #
    #  And some clashing events.
    #
    @clashing_event1 =
      FactoryBot.create(:event,
                        starts_at: Date.tomorrow,
                        ends_at: Date.tomorrow + 1.day,
                        all_day: true,
                        commitments_to: [@location1])
    @clashing_event2 =
      FactoryBot.create(:event,
                        starts_at: Date.tomorrow,
                        ends_at: Date.tomorrow + 1.day,
                        all_day: true,
                        commitments_to: [@location2])
    @past_clashing_event1 =
      FactoryBot.create(:event,
                        starts_at: Date.yesterday,
                        ends_at: Date.today,
                        all_day: true,
                        commitments_to: [@location1])
    @past_clashing_event2 =
      FactoryBot.create(:event,
                        starts_at: Date.yesterday,
                        ends_at: Date.today,
                        all_day: true,
                        commitments_to: [@location2])
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
    #  They start today and run for 7 days each.
    #
    create_week_letters
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
      #  Our original event may or may not be included depending on
      #  whether today is a Monday/Wednesday or not.
      #
      wday = Date.today.wday
      if [1,3].include?(wday)
        assert @event_collection.events.include?(@event)
      else
        assert_not @event_collection.events.include?(@event)
      end
      assert_equal 4, @event_collection.events.size
    end
  end

  #
  #  Note that it is not necessary for our seed event to involve a
  #  given resource for our clash detection code to work at this
  #  level.  This level of code simply checks for clashes with
  #  the element which it is told about.  It's the next level up
  #  which decides which ones are actually relevant before invoking
  #  this level of code.
  #
  test "can detect clashes" do
    clashing_commitments = []
    EventRepeater.test_for_clashes(
      @event_collection,
      @event,
      @location1.element) do |commitment|
      clashing_commitments << commitment
    end
    assert_equal 1, clashing_commitments.size
    clashing_commitments.each do |cc|
      assert_equal @location1.element, cc.element
    end
  end

  test "can detect clashes for two resources" do
    #
    #  We have a clash for location1
    #
    clashing_commitments = []
    EventRepeater.test_for_clashes(
      @event_collection,
      @event,
      @location1.element) do |commitment|
      clashing_commitments << commitment
    end
    assert_equal 1, clashing_commitments.size
    clashing_commitments.each do |cc|
      assert_equal @location1.element, cc.element
    end
    #
    #  And one for location2
    #
    clashing_commitments = []
    EventRepeater.test_for_clashes(
      @event_collection,
      @event,
      @location2.element) do |commitment|
      clashing_commitments << commitment
    end
    assert_equal 1, clashing_commitments.size
    clashing_commitments.each do |cc|
      assert_equal @location2.element, cc.element
    end
  end

  test "takes account of historical record flag when checking for clashes" do
    #
    #  Defaults to ignoring the past, even if it has a start date in the past.
    #
    @event_collection.repetition_start_date = Date.yesterday
    clashing_commitments = []
    EventRepeater.test_for_clashes(
      @event_collection,
      @event,
      @location1.element) do |commitment|
      clashing_commitments << commitment
    end
    assert_equal 1, clashing_commitments.size
    clashing_commitments.each do |cc|
      assert_equal @location1.element, cc.element
    end
    #
    #  Now let's flag past ones too.
    #
    clashing_commitments = []
    @event_collection.preserve_historical = false
    EventRepeater.test_for_clashes(
      @event_collection,
      @event,
      @location1.element) do |commitment|
      clashing_commitments << commitment
    end
    assert_equal 2, clashing_commitments.size
    clashing_commitments.each do |cc|
      assert_equal @location1.element, cc.element
    end
  end

  test "can detect no events at all" do
    assert EventRepeater.would_have_events?(@event_collection)
    #
    #  The coming 7 days are all week A, so specify that time
    #  period and week B.
    #
    @event_collection.weeks = ["B"]
    @event_collection.repetition_end_date = Date.today + 6.days
    assert_not EventRepeater.would_have_events?(@event_collection)
  end

end
