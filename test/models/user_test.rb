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
    @godlike_user = FactoryBot.create(:user,
                                      user_profile: @godlike_user_profile)
    @godlike_user_profile.reload
    
    @staff = FactoryBot.create(:staff, email: 'staff@myschool.org.uk')
    @staff_user = FactoryBot.create(:user, email: 'staff@myschool.org.uk')
    @other_staff =
      FactoryBot.create(:staff, email: 'other_staff@myschool.org.uk')
    @other_staff_user =
      FactoryBot.create(:user, email: 'other_staff@myschool.org.uk')
    @admin_user = FactoryBot.create(:user, :admin,
                                    email: "admin@myschool.co.uk")
    @owned_group = FactoryBot.create(:group, owner: @staff_user)
    @system_group = FactoryBot.create(:group)

    @owned_event = FactoryBot.create(:event,
                                     owner: @staff_user,
                                     organiser: @other_staff.element)
    @system_event = FactoryBot.create(:event)
    @odd_property = FactoryBot.create(:property)
  end

  test "can create a staff user" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
    assert user.known?
  end

  test "user must have user profile" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.valid?
    user.user_profile = nil
    assert_not user.valid?
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
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    check_staff_permissions(user)
  end

  test "new staff user does not have list_teachers set on own concern" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    own_concern = user.concerns.me[0]
    assert_not_nil(own_concern)
    assert_not own_concern.list_teachers
  end

  test "new staff user does not have list_rooms set on own concern" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    own_concern = user.concerns.me[0]
    assert_not_nil(own_concern)
    assert_not own_concern.list_rooms
  end

  test "new pupil user gets correct permissions" do
    pupil = FactoryBot.create(:pupil, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    check_pupil_permissions(user)
  end

  test "new pupil user has list_teachers set on own concern" do
    pupil = FactoryBot.create(:pupil, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    own_concern = user.concerns.me[0]
    assert_not_nil(own_concern)
    assert own_concern.list_teachers
  end

  test "new pupil user does not have list_rooms set on own concern" do
    pupil = FactoryBot.create(:pupil, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    own_concern = user.concerns.me[0]
    assert_not_nil(own_concern)
    assert_not own_concern.list_rooms
  end

  test "new guest user gets correct permissions" do
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    check_guest_permissions(user)
  end

  test "changing user to guest user removes permissions" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    check_staff_permissions(user)
    user.user_profile = UserProfile.guest_profile
    user.save
    check_guest_permissions(user)
  end

  test "changing user to staff user adds permissions" do
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    check_guest_permissions(user)
    user.user_profile = UserProfile.staff_profile
    user.save
    check_staff_permissions(user)
  end

  test "can add specific permission for new user" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, :admin, email: 'able@myschool.org.uk')
    check_no(user.user_profile.permissions[:admin])
    assert user.admin?
  end

  test "can remove specific permission for new user" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
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
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
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
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
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
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
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
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.known?
    user.user_profile.known = false
    user.user_profile.save
    user.reload
    assert_not user.known?
  end

  test "adding known to profile adds it to user" do
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert_not user.known?
    user.user_profile.known = true
    user.user_profile.save
    user.reload
    assert user.known?
  end

  test "don't link to non-current staff" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk', current: false)
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
  end

  test "can create a pupil user" do
    pupil = FactoryBot.create(:pupil, email: 'student@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'student@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
  end

  test "don't link to non-current pupil" do
    pupil = FactoryBot.create(:pupil, email: 'student@myschool.org.uk', current: false)
    user = FactoryBot.create(:user, email: 'student@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_nil user.corresponding_staff
  end

  test "prefer staff record to pupil one" do
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
    pupil = FactoryBot.create(:pupil, email: 'able@myschool.org.uk')
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
  end

  test "can create a guest user" do
    user = FactoryBot.create(:user, email: 'guest@myschool.org.uk')
    assert user.valid?
  end

  test "can create staff member after user" do
    user = FactoryBot.create(:user, email: 'able@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_not user.known?
    assert_nil user.corresponding_staff
    staff = FactoryBot.create(:staff, email: 'able@myschool.org.uk')
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
    user = FactoryBot.create(:user, email: 'student@myschool.org.uk')
    assert user.valid?
    assert_equal UserProfile.guest_profile, user.user_profile
    assert_not user.known?
    assert_nil user.corresponding_staff
    pupil = FactoryBot.create(:pupil, email: 'student@myschool.org.uk')
    user.find_matching_resources
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
    assert_nil user.corresponding_staff
    assert user.known?
  end

  test "new user gets UUID" do
    user = FactoryBot.create(:user, email: 'chap@myschool.org.uk')
    assert_not_nil user.uuid
  end

  test "we can force a chosen UUID" do
    forced_uuid = "Banana fritters"
    user = FactoryBot.create(:user,
                             email: 'chap@myschool.org.uk',
                             initial_uuid: forced_uuid)
    assert_equal forced_uuid, user.uuid
  end

  test "permissions to edit groups are correctly calculated" do
    assert @admin_user.can_edit?(@system_group)
    assert @admin_user.can_edit?(@owned_group)
    assert @staff_user.can_edit?(@owned_group)
    assert_not @staff_user.can_edit?(@system_group)
  end

  test "permissions to edit events are correctly calculated" do
    assert     @admin_user.can_edit?(@system_event)
    assert_not @staff_user.can_edit?(@system_event)
    assert     @admin_user.can_edit?(@owned_event)
    assert     @staff_user.can_edit?(@owned_event)
    assert_not @other_staff_user.can_edit?(@owned_event)
    #
    #  But he can with more permissions.
    #
    @staff_user.permissions[:edit_all_events] = true
    @staff_user.save!
    assert @staff_user.can_edit?(@system_event)
  end

  test "permissions to sub edit events are correctly calculated" do
    assert     @admin_user.can_subedit?(@system_event)
    assert_not @staff_user.can_subedit?(@system_event)
    assert     @admin_user.can_subedit?(@owned_event)
    assert     @staff_user.can_subedit?(@owned_event)
    assert     @other_staff_user.can_subedit?(@owned_event)
    #
    #  But he can with more permissions.
    #
    @staff_user.permissions[:subedit_all_events] = true
    @staff_user.save!
    assert @staff_user.can_subedit?(@system_event)
  end

  test "permissions to delete concerns are correctly calculated" do
    concern = FactoryBot.create(
      :concern,
      user:    @staff_user,
      element: @odd_property.element
    )
    assert @staff_user.can_delete?(concern)
    assert @admin_user.can_delete?(concern)
    assert_not @other_staff_user.can_delete?(concern)
  end

  test "permissions to delete notes are correctly calculated" do
    note = FactoryBot.create(
      :note,
      owner: @staff_user,
      parent: @owned_event)
    assert @staff_user.can_delete?(note)
    assert_not @other_staff_user.can_delete?(note)
    assert @admin_user.can_delete?(note)
    commitment = FactoryBot.create(:commitment)
    #
    #  If a note is attached to a commitment, then we can't delete
    #  it even if we own it.  We have to delete the commitment instead.
    #
    other_note = FactoryBot.create(
      :note,
      owner: @staff_user,
      parent: commitment)
    assert_not @staff_user.can_delete?(other_note)
  end

  test "permissions to delete user files are correctly calculated" do
    user_file = FactoryBot.create(
      :user_file,
      owner: @staff_user)
    assert @staff_user.can_delete?(user_file)
    assert_not @other_staff_user.can_delete?(user_file)
    assert @admin_user.can_delete?(user_file)
  end

  test "can have a freefinder" do
    ff = @staff_user.create_freefinder(attributes_for(:freefinder))
    assert_not_nil ff
    assert ff.valid?
  end

  test "can set resource notification flags" do
    assert @staff_user.email_notification?
    assert_not @staff_user.immediate_notification?
    assert @staff_user.loading_notification?
    assert_not @staff_user.resource_clash_notification?
    @staff_user.email_notification = false
    @staff_user.immediate_notification = true
    @staff_user.loading_notification = false
    @staff_user.resource_clash_notification = true
    assert_not @staff_user.email_notification?
    assert @staff_user.immediate_notification?
    assert_not @staff_user.loading_notification?
    assert @staff_user.resource_clash_notification?
  end

  test "can create user from omniauth" do
    auth = {
      "provider" => "Google",
      "uid"      => "12345",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    assert_difference('User.count', 1) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal user.user_profile, UserProfile.guest_profile
    end
  end

  test "can pick up staff profile" do
    auth = {
      "provider" => "Google",
      "uid"      => "12345",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    FactoryBot.create(:staff, email: "able.baker@charlie.org")
    assert_difference('User.count', 1) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal user.user_profile, UserProfile.staff_profile
    end
  end

  test "can pick up pupil profile" do
    auth = {
      "provider" => "Google",
      "uid"      => "12345",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    FactoryBot.create(:pupil, email: "able.baker@charlie.org")
    assert_difference('User.count', 1) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal user.user_profile, UserProfile.pupil_profile
    end
  end

  test "can change provider through omniauth" do
    auth = {
      "provider" => "Microsoft",
      "uid"      => "6789",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    existing_user = FactoryBot.create(
      :user,
      email: "able.baker@charlie.org",
      provider: "Google",
      uid: "12345"
    )

    assert_difference('User.count', 0) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal auth["provider"], user.provider
      assert_equal auth["uid"], user.uid
    end
  end

  test "can update existing users name at login" do
    auth = {
      "provider" => "Google",
      "uid"      => "12345",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    user = nil
    assert_difference('User.count', 1) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal user.user_profile, UserProfile.guest_profile
    end
    auth["info"]["name"] = "Got married"
    auth["info"]["email"] = "ANC@de.f"
    assert_difference('User.count', 0) do
      user.update_from_omniauth(auth)
      user.reload # To make sure change has been persisted
      assert_equal "Got married", user.name
      assert_equal "anc@de.f", user.email
    end
  end

  test "but wont blank things out" do
    auth = {
      "provider" => "Google",
      "uid"      => "12345",
      "info" => {
        "name"  =>  "Able Baker Charlie",
        "email" =>  "able.baker@charlie.org"
      }
    }
    user = nil
    assert_difference('User.count', 1) do
      user = User.create_from_omniauth(auth)
      assert user.valid?
      assert_equal user.user_profile, UserProfile.guest_profile
    end
    auth["info"]["name"] = ""
    auth["info"]["email"] = nil
    assert_difference('User.count', 0) do
      user.update_from_omniauth(auth)
      user.reload # To make sure change has been persisted
      assert_equal "Able Baker Charlie", user.name
      assert_equal "able.baker@charlie.org", user.email
    end
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
