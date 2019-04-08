require 'test_helper'

class ApiSessionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @api_user = FactoryBot.create(:user, :api)
    @ordinary_user = FactoryBot.create(:user)

  end

  test "login requests must be json" do
    get "/api/login?uid=#{@api_user.uuid}"
    assert_redirected_to "/"
  end

  test "random uid does not log in" do
    get "/api/login?uid=ablebakercharlie", format: :json
    assert_response 401
  end

  test "ordinary user cannot log in through api" do
    get "/api/login?uid=#{@ordinary_user.uuid}", format: :json
    assert_response 401
  end

  test "api user can log in through api" do
    get "/api/login?uid=#{@api_user.uuid}", format: :json
    assert_response :success
  end

  test "logout requests must be json" do
    get "/api/logout"
    assert_redirected_to "/"
  end

  test "logout always succeeds" do
    get "/api/logout", format: :json
    assert_response :success
  end

end
