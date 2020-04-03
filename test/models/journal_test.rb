#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @valid_params = {
      event: @event
    }
  end

  test "can create journal" do
    journal = Journal.new(@valid_params)
    assert journal.valid?
  end

  test "event is required" do
    journal = Journal.new(@valid_params.except(:event))
    assert_not journal.valid?
  end

end
