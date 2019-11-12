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
      post :create, location: { active: @location.active, current: @location.current, name: @location.name }
    end

    assert_redirected_to locations_path
  end

  test "should show location" do
    get :show, id: @location
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @location
    assert_response :success
  end

  test "should update location" do
    session[:editing_location_from] = "/banana"
    patch :update, id: @location, location: { active: @location.active, current: @location.current, name: @location.name }
    assert_redirected_to "/banana"
  end

  test "should destroy location" do
    assert_difference('Location.count', -1) do
      request.env["HTTP_REFERER"] = locations_path
      delete :destroy, id: @location
    end

    assert_redirected_to locations_path
  end
end
