#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class EventsourceTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      name: "Hi there - I'm an event source"
    }
  end

  test "can create an event source" do
    es = Eventsource.new(@valid_params)
    assert es.valid?
  end

  test "must have a name" do
    es = Eventsource.new(@valid_params.except(:name))
    assert_not es.valid?
  end

  test "must have a non-blank name" do
    es = Eventsource.new(@valid_params.merge({name: ""}))
    assert_not es.valid?
  end

  test "must have a unique name" do
    es1 = Eventsource.create(@valid_params)
    assert es1.valid?
    es2 = Eventsource.new(@valid_params)
    assert_not es2.valid?
  end

end
