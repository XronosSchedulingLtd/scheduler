#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PromptnoteTest < ActiveSupport::TestCase
  setup do
    @element = FactoryBot.create(:element)
    @valid_params = {
      element: @element
    }
  end

  test "can create prompt note" do
    pn = Promptnote.new(@valid_params)
    assert pn.valid?
  end

  test "must have an element" do
    pn = Promptnote.new(@valid_params.except(:element))
    assert_not pn.valid?
  end

end
