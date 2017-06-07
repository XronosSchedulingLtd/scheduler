require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    session[:user_id] = users(:admin).id
  end

  test "should get new" do
    get :new
    assert_redirected_to '/auth/google_oauth2'
  end

#  test "should get create" do
#    get :create
#    assert_response :success
#  end

  test "should get destroy" do
    get :destroy
    assert_redirected_to '/'
  end

end
