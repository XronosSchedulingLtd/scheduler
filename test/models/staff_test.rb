#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class StaffTest < ActiveSupport::TestCase

  setup do
    @valid_params = {
      name: "Hello there - I'm staff"
    }
  end

  test "can create a staff record" do
    staff = Staff.new(@valid_params)
    assert staff.valid?
  end

  test "name is required" do
    staff = Staff.new(@valid_params.except(:name))
    assert_not staff.valid?
  end

  test "viewable should default to true" do
    staff = FactoryBot.create(:staff)
    assert staff.element.viewable?
  end

  test "can create staff with viewable false" do
    staff = FactoryBot.create(:staff, edit_viewable: false)
    assert_not staff.element.viewable?
  end

  test "string \"0\" should work as false too" do
    staff = FactoryBot.create(:staff, edit_viewable: "0")
    assert_not staff.element.viewable?
  end

  test "and \"1\" should work as true" do
    staff = FactoryBot.create(:staff, edit_viewable: "1")
    assert staff.element.viewable?
  end

  test "gets given a UUID" do
    staff = FactoryBot.create(:staff)
    assert_not_nil staff.element.uuid
  end

  test "can dictate the UUID" do
    chosen_uuid = "Banana fritters"
    staff = FactoryBot.create(:staff, preferred_uuid: chosen_uuid)
    assert_equal chosen_uuid, staff.element.uuid
  end

end
