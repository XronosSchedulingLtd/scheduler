#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ClashDetectorTest < ActiveSupport::TestCase

  setup do
    @event_collection = FactoryBot.create(:event_collection)
    @event = FactoryBot.create(:event)
    @user = FactoryBot.create(:user)
    create_week_letters
    #
    #  A couple of locations for the user to own
    #
    @location1 = FactoryBot.create(:location, owner: @user)
    @location2 = FactoryBot.create(:location, owner: @user)
  end


  #
  #  It is surprisingly difficult to write a test which will produce
  #  a failure rather than a run-time error if the class is not defined.
  #
  #  Arguably no real point in this test, but an interesting academic
  #  exercise.
  #
  test "service exists" do
    begin
      klass = Module.const_get("ClashDetector")
      assert klass.is_a?(Class)
    rescue NameError
      assert false, "ClashDetector not defined"
    end
  end

  #
  #  Ah, no - there's a slightly easier way.  It still needs a bit of
  #  jiggery-pokery because of Rails's dynamic loading of classes.
  #
  test "another way" do
    begin
      able = ClashDetector.new(@event_collection, @event, @user)
      assert true   # Just to keep the numbers consistent.
    rescue NameError
      assert false, "ClashDetector not defined"
    end
  end

  test "checks only resources in use" do
    #
    #  A couple of events tomorrow.
    #
    event1 = FactoryBot.create(:event,
                               starts_at: Date.tomorrow,
                               ends_at: Date.tomorrow + 1.day,
                               all_day: true,
                               commitments_to: [@location1])
    event2 = FactoryBot.create(:event,
                               starts_at: Date.tomorrow,
                               ends_at: Date.tomorrow + 1.day,
                               all_day: true,
                               commitments_to: [@location2])
    #
    #  This one will be today.
    #
    seed_event = FactoryBot.create(:event,
                                   commitments_to: [@location1])
    #
    #  And a collection in order to repeat it.
    #
    event_collection =
      FactoryBot.create(
        :event_collection,
        repetition_start_date: Date.today,
        repetition_end_date:   Date.today + 2.weeks,
        weeks: ["A", "B", " "],
        days_of_week: ["0","1","2","3","4","5","6"])
    event_collection.events << seed_event

    clashes = ClashDetector.new(event_collection, seed_event, @user).
                            detect_clashes
    assert_equal 1, clashes.size
    assert_equal @location1.name, clashes[0].resource_name
    assert_equal 1, clashes[0].messages.size
    assert_equal event1.body, clashes[0].messages[0].body
  end

end
