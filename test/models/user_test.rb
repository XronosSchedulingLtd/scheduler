require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "can create a staff user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
  end

  test "new staff user gets correct permissions" do
    #
    #  Note that here we're really just checking that the user
    #  has been linked to the right profile, and then that the
    #  permissions have propagated through in the correct way.
    #
    #  The flags in the profiles are set up by a fixture when
    #  in test mode, and by code in the UserProfile model for
    #  real systems.  I have yet to find a way to unify these two.
    #
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.editor?
    assert user.can_repeat_events?
    assert user.can_add_resources?
    assert user.can_add_notes?
    assert user.can_has_groups?
    assert user.public_groups?
    assert user.can_find_free?
    assert user.can_add_concerns?
    assert user.can_roam?
    assert user.can_has_files?

    assert_not user.admin?
    assert_not user.edit_all_events?
    assert_not user.subedit_all_events?
    assert_not user.privileged?
    assert_not user.can_has_forms?
    assert_not user.can_su?
    assert_not user.exams?
    assert_not user.can_relocate_lessons?
    assert_not user.can_view_forms?
    assert_not user.can_view_unconfirmed?
    assert_not user.can_edit_memberships?
    assert_not user.can_api?
  end

  test "new pupil user gets correct permissions" do
    #
    #  Note that here we're really just checking that the user
    #  has been linked to the right profile, and then that the
    #  permissions have propagated through in the correct way.
    #
    #  The flags in the profiles are set up by a fixture when
    #  in test mode, and by code in the UserProfile model for
    #  real systems.  I have yet to find a way to unify these two.
    #
    pupil = FactoryBot.create(:pupil, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.editor?

    assert_not user.can_repeat_events?
    assert_not user.can_add_resources?
    assert_not user.can_add_notes?
    assert_not user.can_has_groups?
    assert_not user.public_groups?
    assert_not user.can_find_free?
    assert_not user.can_add_concerns?
    assert_not user.can_roam?
    assert_not user.can_has_files?
    assert_not user.admin?
    assert_not user.edit_all_events?
    assert_not user.subedit_all_events?
    assert_not user.privileged?
    assert_not user.can_has_forms?
    assert_not user.can_su?
    assert_not user.exams?
    assert_not user.can_relocate_lessons?
    assert_not user.can_view_forms?
    assert_not user.can_view_unconfirmed?
    assert_not user.can_edit_memberships?
    assert_not user.can_api?
  end

  test "new guest user gets correct permissions" do
    #
    #  Note that here we're really just checking that the user
    #  has been linked to the right profile, and then that the
    #  permissions have propagated through in the correct way.
    #
    #  The flags in the profiles are set up by a fixture when
    #  in test mode, and by code in the UserProfile model for
    #  real systems.  I have yet to find a way to unify these two.
    #
    user = FactoryBot.create(:user, email: 'able@baker.com')

    assert_not user.editor?
    assert_not user.can_repeat_events?
    assert_not user.can_add_resources?
    assert_not user.can_add_notes?
    assert_not user.can_has_groups?
    assert_not user.public_groups?
    assert_not user.can_find_free?
    assert_not user.can_add_concerns?
    assert_not user.can_roam?
    assert_not user.can_has_files?
    assert_not user.admin?
    assert_not user.edit_all_events?
    assert_not user.subedit_all_events?
    assert_not user.privileged?
    assert_not user.can_has_forms?
    assert_not user.can_su?
    assert_not user.exams?
    assert_not user.can_relocate_lessons?
    assert_not user.can_view_forms?
    assert_not user.can_view_unconfirmed?
    assert_not user.can_edit_memberships?
    assert_not user.can_api?
  end

  test "can add specific permission for new user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, :admin, email: 'able@baker.com')
    assert user.admin?
    assert_equal PermissionFlags::PERMISSION_NO,
                 user.user_profile.permissions[:admin]
  end

  test "don't link to non-current staff" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com', current: false)
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
  end

  test "can create a pupil user" do
    pupil = FactoryBot.create(:pupil, email: 'student@baker.com')
    user = FactoryBot.create(:user, email: 'student@baker.com')
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
  end

  test "don't link to non-current pupil" do
    pupil = FactoryBot.create(:pupil, email: 'student@baker.com', current: false)
    user = FactoryBot.create(:user, email: 'student@baker.com')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
  end

  test "prefer staff record to pupil one" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    pupil = FactoryBot.create(:pupil, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
  end

  test "can create a guest user" do
    user = FactoryBot.create(:user, email: 'guest@baker.com')
    assert user.valid?
  end

  test "can create staff member after user" do
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    #
    #  We do an explicit call on find_matching_resources here to
    #  emulate the case of the user logging in for a second time,
    #  having logged in the first time before the staff record
    #  was created.
    #
    user.find_matching_resources
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
  end

  test "can create pupil after user" do
    user = FactoryBot.create(:user, email: 'student@baker.com')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
    pupil = FactoryBot.create(:pupil, email: 'student@baker.com')
    user.find_matching_resources
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
    assert_nil user.corresponding_staff
  end

  test "new user gets UUID" do
    user = FactoryBot.create(:user, email: 'chap@baker.com')
    assert_not_nil user.uuid
  end

  test "we can force a chosen UUID" do
    forced_uuid = "Banana fritters"
    user = FactoryBot.create(:user,
                             email: 'chap@baker.com',
                             initial_uuid: forced_uuid)
    assert_equal forced_uuid, user.uuid
  end
end
