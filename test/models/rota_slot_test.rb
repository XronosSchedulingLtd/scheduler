#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class RotaSlotTest < ActiveSupport::TestCase
  setup do
    @rota_template = FactoryBot.create(:rota_template)

    @valid_params = {
      rota_template: @rota_template,
      starts_at: "09:00",
      ends_at: "11:00"
    }
  end

  test "can create rota slot" do
    rs = RotaSlot.new(@valid_params)
    assert rs.valid?
  end

  test "must have rota template" do
    rs = RotaSlot.new(@valid_params.except(:rota_template))
    assert_not rs.valid?
  end

  test "must have start time" do
    rs = RotaSlot.new(@valid_params.except(:starts_at))
    assert_not rs.valid?
  end

  test "must have end time" do
    rs = RotaSlot.new(@valid_params.except(:ends_at))
    assert_not rs.valid?
  end

  test "can specify to which days it applies" do
    rs = RotaSlot.new(@valid_params.merge(days: [true, false, true]))
    assert rs.valid?
    assert rs.applies_on?(Date.today.sunday)
    assert_not rs.applies_on?(Date.today.sunday + 1.day)
    assert rs.applies_on?(Date.today.sunday + 2.days)
  end
end
