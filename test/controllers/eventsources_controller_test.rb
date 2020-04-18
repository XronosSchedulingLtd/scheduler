require 'test_helper'

class EventsourcesControllerTest < ActionController::TestCase
  setup do
    @eventsource = eventsources(:one)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:eventsources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create eventsource" do
    assert_difference('Eventsource.count') do
      post :create, params: {eventsource: { name: "Banana" }}
    end

    assert_redirected_to eventsources_path
  end

  test "should show eventsource" do
    get :show, params: { id: @eventsource}
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @eventsource }
    assert_response :success
  end

  test "should update eventsource" do
    patch :update, params: { id: @eventsource, eventsource: { name: "Baker" }}
    assert_redirected_to eventsources_path
  end

  test "should destroy eventsource" do
    assert_difference('Eventsource.count', -1) do
      delete :destroy, params: { id: @eventsource }
    end

    assert_redirected_to eventsources_path
  end
end
