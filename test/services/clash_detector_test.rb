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

end
