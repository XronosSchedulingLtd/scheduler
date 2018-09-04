require 'test_helper'

class SortingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  #
  test "it should be possible to sort mixed elements" do
    pupils = Pupil.all.to_a
    staff = Staff.all.to_a
    everything = pupils + staff
    assert_nothing_raised do
      everything.sort
    end
  end
end

