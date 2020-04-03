#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PreRequisiteTest < ActiveSupport::TestCase
  setup do
    @element = FactoryBot.create(:element)
    @valid_params = {
      element: @element
    }
  end

  test "can create pre-requisite" do
    pr = PreRequisite.new(@valid_params)
    assert pr.valid?
  end

  test "must have an element" do
    pr = PreRequisite.new(@valid_params.except(:element))
    assert_not pr.valid?
  end

end
