require 'test_helper'

class UserProfileTest < ActiveSupport::TestCase

  #
  #  Really just testing that our test environment has been set up
  #  correctly.
  #
  test "staff profile has correct permissions" do
    staff_should_have = [
      :editor,
      :can_repeat_events,
      :can_add_resources,
      :can_add_notes,
      :can_has_groups,
      :public_groups,
      :can_find_free,
      :can_add_concerns,
      :can_roam,
      :can_has_files
    ]
    check_permission_set(UserProfile.staff_profile, staff_should_have)
  end

  test "staff profile is known" do
    assert UserProfile.staff_profile.known?
  end

  test "pupil profile has correct permissions" do
    pupil_should_have = [
      :editor
    ]
    check_permission_set(UserProfile.pupil_profile, pupil_should_have)
  end

  test "pupil profile is known" do
    assert UserProfile.pupil_profile.known?
  end

  test "guest profile has correct permissions" do
    guest_should_have = [
    ]
    check_permission_set(UserProfile.guest_profile, guest_should_have)
  end

  test "guest profile is unknown" do
    assert_not UserProfile.guest_profile.known?
  end

  private

  def check_permission_set(profile, should_have)
    PermissionFlags::KNOWN_PERMISSIONS.each do |key|
      value = profile.permissions[key]
      if should_have.include?(key)
        assert_equal PermissionFlags::PERMISSION_YES, value, "Should have #{key}"
      else
        assert_equal PermissionFlags::PERMISSION_NO, value, "Should not have #{key}"
      end
    end
  end

end
