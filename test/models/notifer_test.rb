#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class NotifierTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      start_date: Date.today
    }
  end

  test "can create notifier" do
    notifier = Notifier.new(@valid_params)
    assert notifier.valid?
  end

  test "must have a start date" do
    notifier = Notifier.new(@valid_params.except(:start_date))
    assert_not notifier.valid?
  end

  test "end date can't be before start date" do
    notifier = Notifier.new(@valid_params.merge({end_date: Date.yesterday}))
    assert_not notifier.valid?
  end

end
