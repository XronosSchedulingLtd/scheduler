require 'test_helper'

class DayNamerTest < ActiveSupport::TestCase

  test "can scan elements" do
    assert_equal 7, DayNamer.daynames_with_index.size
    DayNamer.daynames_with_index.each do |dwi|
      assert dwi.respond_to?(:index)
      assert dwi.respond_to?(:name)
    end
  end
end
