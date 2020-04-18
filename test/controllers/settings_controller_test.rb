require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  setup do
    @setting = settings(:one)
    session[:user_id] = users(:admin).id
  end

  test "should show setting" do
    get :show, params: { id: @setting }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @setting }
    assert_response :success
  end

  test "should update setting" do
    patch(
      :update,
      params: {
        id: @setting,
        setting: {
          current_era_id: @setting.current_era_id
        }
      }
    )
    assert_redirected_to setting_path(assigns(:setting))
  end

end
