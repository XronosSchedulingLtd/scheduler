require 'test_helper'

class StaffTest < ActiveSupport::TestCase

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
