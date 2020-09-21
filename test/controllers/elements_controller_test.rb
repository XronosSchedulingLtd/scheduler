require 'test_helper'

class ElementsControllerTest < ActionController::TestCase

  setup do
    @admin_user =
      FactoryBot.create(:user,
                        :admin,
                        user_profile: UserProfile.staff_profile)
    @ordinary_user =
      FactoryBot.create(:user,
                        :not_can_roam,
                        user_profile: UserProfile.staff_profile)
    @odd_admin_user =
      FactoryBot.create(:user,
                        :admin,
                        :not_can_roam,
                        user_profile: UserProfile.staff_profile)
    @sample_element = FactoryBot.create(:element)
  end

  test "admin user can show element even without can_roam permission" do
    session[:user_id] = @odd_admin_user.id
    assert_not @odd_admin_user.can_roam?
    get :show, params: { id: @sample_element }
    assert_response :success
  end

  test "ordinary user cannot show element without can_roam permission" do
    session[:user_id] = @ordinary_user.id
    assert_not @ordinary_user.can_roam?
    get :show, params: { id: @sample_element }
    assert_response :forbidden
  end
end
