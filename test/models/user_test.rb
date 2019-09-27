require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "can create a staff user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
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
