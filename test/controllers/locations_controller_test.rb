require 'test_helper'

class LocationsControllerTest < ActionController::TestCase
  setup do
    @location = FactoryBot.create(:location)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:locations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create location" do
    session[:new_location_from] = locations_path
    assert_difference('Location.count') do
      post(
        :create,
        params: {
          location: {
            active: @location.active,
            current: @location.current,
            name: @location.name
          }
        }
      )
    end

    assert_redirected_to locations_path
    assert_no_errors
  end

  test "should show location" do
    get :show, params: { id: @location }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @location }
    assert_response :success
  end

  test "should update location" do
    session[:editing_location_from] = "/banana"
    patch(
      :update,
      params: {
        id: @location,
        location: {
          active: @location.active,
          current: @location.current,
          name: @location.name
        }
      }
    )
    assert_redirected_to "/banana"
    assert_no_errors
  end

  test "should destroy location" do
    assert_difference('Location.count', -1) do
      request.env["HTTP_REFERER"] = locations_path
      delete :destroy, params: { id: @location }
    end

    assert_redirected_to locations_path
  end
end
