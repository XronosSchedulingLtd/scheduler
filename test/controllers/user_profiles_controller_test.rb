require 'test_helper'

class UserProfilesControllerTest < ActionController::TestCase
  setup do
    @user_profile = user_profiles(:staff)
    session[:user_id] = users(:admin).id
    @permission_flags = PermissionFlags.new
    @permission_flags[:editor] = true
    @permission_flags[:groups] = true
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_profiles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_profile" do
    assert_difference('UserProfile.count') do
      post(
        :create,
        params: {
          user_profile: {
            name: @user_profile.name,
            permissions: @permission_flags
          }
        }
      )
    end

    assert_redirected_to user_profiles_path
    assert_no_errors
  end

  test "should show user_profile" do
    get :show, params: { id: @user_profile }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @user_profile }
    assert_response :success
  end

  test "should update user_profile" do
    patch(
      :update,
      params: {
        id: @user_profile,
        user_profile: {
          name: @user_profile.name,
          permissions: @permission_flags
        }
      }
    )
    assert_redirected_to user_profiles_path
    assert_no_errors
  end

  test "should destroy user_profile" do
    assert_difference('UserProfile.count', -1) do
      delete :destroy, params: { id: @user_profile }
    end

    assert_redirected_to user_profiles_path
  end
end
