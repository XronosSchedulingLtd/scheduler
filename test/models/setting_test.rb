require 'test_helper'

class SettingTest < ActiveSupport::TestCase

  test "should be a setting for busy text" do
    assert Setting.respond_to?(:busy_string)
  end

  test "default busy string should be \"Busy\"" do
    assert_equal "Busy", Setting.busy_string
  end

end
