require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    UserProfile.ensure_basic_profiles
  end

  test "can create a staff user" do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    assert user.valid?
    assert_equal UserProfile.staff_profile, user.user_profile
    assert_equal user.corresponding_staff, staff
  end

  test "can create a pupil user" do
    pupil = FactoryBot.create(:pupil, email: 'student@baker.com')
    user = FactoryBot.create(:user, email: 'student@baker.com')
    assert user.valid?
    assert_equal UserProfile.pupil_profile, user.user_profile
  end

  test "can create a guest user" do
    user = FactoryBot.create(:user, email: 'guest@baker.com')
    assert user.valid?
  end

end
