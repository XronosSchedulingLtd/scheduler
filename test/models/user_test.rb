require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @test_user_profile = FactoryBot.create(:user_profile)
    @test_user = FactoryBot.create(:user, user_profile: @test_user_profile)
    #
    #  It seems that we can end up with the cached copy of the
    #  test user profile not realising that it has a user attached.
    #
    @test_user_profile.reload
    @godlike_user_profile = FactoryBot.create(:user_profile, :godlike)
#    PermissionFlags::KNOWN_PERMISSIONS.each do |pf|
#      @godlike_user_profile.permissions[pf] = true
#    end
#    @godlike_user_profile.save!
    @godlike_user = FactoryBot.create(:user,
                                      user_profile: @godlike_user_profile)
    @godlike_user_profile.reload
  end

  test "can create a staff user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
    assert user.known?
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
    check_staff_permissions(user)
  end

  test "new pupil user gets correct permissions" do
    pupil = FactoryBot.create(:pupil, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_pupil_permissions(user)
  end

  test "new guest user gets correct permissions" do
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_guest_permissions(user)
  end

  test "changing user to guest user removes permissions" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_staff_permissions(user)
    user.user_profile = UserProfile.guest_profile
    user.save
    check_guest_permissions(user)
  end

  test "changing user to staff user adds permissions" do
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_guest_permissions(user)
    user.user_profile = UserProfile.staff_profile
    user.save
    check_staff_permissions(user)
  end

  test "can add specific permission for new user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, :admin, email: 'able@baker.com')
    check_no(user.user_profile.permissions[:admin])
    assert user.admin?
  end

  test "can remove specific permission for new user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_yes user.user_profile.permissions[:editor]
    check_dont_care user.permissions[:editor]
    assert user.editor?
    user.permissions[:editor] = PermissionFlags::PERMISSION_NO
    user.save!
    check_yes user.user_profile.permissions[:editor]
    check_no user.permissions[:editor]
    assert_not user.editor?
  end

  test "adding permission to profile adds it to user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_no user.user_profile.permissions[:admin]
    check_dont_care user.permissions[:admin]
    assert_not user.admin?
    user.user_profile.permissions[:admin] = true
    user.user_profile.save
    user.reload
    check_yes user.user_profile.permissions[:admin]
    check_dont_care user.permissions[:admin]
    assert user.admin?
  end

  test "all permission bits propagate" do
    assert_equal @test_user_profile, @test_user.user_profile
    PermissionFlags::KNOWN_PERMISSIONS.each do |pf|
      check_no(@test_user_profile.permissions[pf])
      check_dont_care(@test_user.permissions[pf])
      assert_not @test_user.send("#{pf}?")
      @test_user_profile.permissions[pf] = true
      @test_user_profile.save
      @test_user.reload
      check_yes(@test_user_profile.permissions[pf])
      check_dont_care(@test_user.permissions[pf])
      assert @test_user.send("#{pf}?"), "Testing #{pf}"
    end
  end

  test "all permission bits can be set for individual users" do
    assert_equal @test_user_profile, @test_user.user_profile
    PermissionFlags::KNOWN_PERMISSIONS.each do |pf|
      check_no(@test_user_profile.permissions[pf])
      check_dont_care(@test_user.permissions[pf])
      assert_not @test_user.send("#{pf}?")
      @test_user.permissions[pf] = true
      @test_user.save
      check_no(@test_user_profile.permissions[pf])
      check_yes(@test_user.permissions[pf])
      assert @test_user.send("#{pf}?"), "Testing #{pf}"
    end
  end

  test "all permission bits can be removed for individual users" do
    assert_equal @godlike_user_profile, @godlike_user.user_profile
    PermissionFlags::KNOWN_PERMISSIONS.each do |pf|
      check_yes(@godlike_user_profile.permissions[pf])
      check_dont_care(@godlike_user.permissions[pf])
      assert @godlike_user.send("#{pf}?")
      @godlike_user.permissions[pf] = false
      @godlike_user.save
      check_yes(@godlike_user_profile.permissions[pf])
      check_no(@godlike_user.permissions[pf])
      assert_not @godlike_user.send("#{pf}?"), "Testing #{pf}"
    end
  end

  test "removing permission from profile removes it from user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_yes user.user_profile.permissions[:editor]
    check_dont_care user.permissions[:editor]
    assert user.editor?
    user.user_profile.permissions[:editor] = false
    user.user_profile.save
    user.reload
    check_no user.user_profile.permissions[:editor]
    check_dont_care user.permissions[:editor]
    assert_not user.admin?
  end

  test "but not if the user has it explicitly" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    check_yes user.user_profile.permissions[:editor]
    check_dont_care user.permissions[:editor]
    assert user.editor?
    user.permissions[:editor] = true
    user.save
    user.user_profile.permissions[:editor] = false
    user.user_profile.save
    user.reload
    check_no user.user_profile.permissions[:editor]
    check_yes user.permissions[:editor]
    assert user.editor?
  end

  test "removing known from profile removes it from user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.known?
    user.user_profile.known = false
    user.user_profile.save
    user.reload
    assert_not user.known?
  end

  test "adding known to profile adds it to user" do
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert_not user.known?
    user.user_profile.known = true
    user.user_profile.save
    user.reload
    assert user.known?
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
    assert_not user.known?
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
    assert user.known?
  end

  test "can create pupil after user" do
    user = FactoryBot.create(:user, email: 'student@baker.com')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_not user.known?
    assert_nil user.corresponding_staff
    pupil = FactoryBot.create(:pupil, email: 'student@baker.com')
    user.find_matching_resources
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
    assert_nil user.corresponding_staff
    assert user.known?
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

  private

  def check_yes(value)
    assert_equal PermissionFlags::PERMISSION_YES, value
  end

  def check_no(value)
    assert_equal PermissionFlags::PERMISSION_NO, value
  end

  def check_dont_care(value)
    assert_equal PermissionFlags::PERMISSION_DONT_CARE, value
  end

  def check_staff_permissions(user)
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
    assert_not user.can_view_journals?
  end

  def check_pupil_permissions(user)
    assert user.editor?
    assert user.known?

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
    assert_not user.can_view_journals?
  end

  def check_guest_permissions(user)
    assert_not user.known?

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
    assert_not user.can_view_journals?
  end

end
