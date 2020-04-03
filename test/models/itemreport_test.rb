#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ItemreportTest < ActiveSupport::TestCase
  setup do
    @concern = FactoryBot.create(:concern)
    @valid_params = {
      concern: @concern
    }
  end

  test "can create an item report" do
    ir = Itemreport.new(@valid_params)
    assert ir.valid?
  end

  test "concern is required" do
    ir = Itemreport.new(@valid_params.except(:concern))
    assert_not ir.valid?
  end

end
