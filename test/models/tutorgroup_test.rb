#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class TutorgroupTest < ActiveSupport::TestCase
  setup do
    @staff = FactoryBot.create(:staff)
    @era = FactoryBot.create(:era)
    @valid_params = {
      name:      'A tutor group',
      era:       @era,
      starts_on: @era.starts_on,
      staff:     @staff
    }
  end

  test "can create a tutor group in one go" do
    tg = Tutorgroup.create!(@valid_params)
    assert tg.valid?
    assert tg.respond_to?(:staff)
    assert_equal @staff, tg.staff
  end

  test "can create a tutor group bit by bit" do
    tg = Tutorgroup.new
    assert tg.respond_to?(:staff)
    assert_not tg.valid?
    tg.update_attributes(@valid_params)
    assert tg.valid?
    assert tg.save
  end

  test "can also pass params all in one go" do
    tg = Tutorgroup.new(@valid_params)
    assert tg.valid?
    assert tg.save
  end

end
