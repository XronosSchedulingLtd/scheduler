require 'test_helper'

class StaffTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "viewable should default to true" do
    staff = FactoryBot.create(:staff)
    assert staff.element.viewable?
  end

end
