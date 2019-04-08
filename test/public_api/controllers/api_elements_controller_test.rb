require 'test_helper'

class ApiElementsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @api_user = FactoryBot.create(:user, :api)
    session[:user_id] = @api_user.id

  end

  test "must login before issuing request" do
    session[:user_id] = nil
    get "/api/elements"
    raise response.inspect
  end

  test "index with no params gets empty response" do
    get "/api/elements"
    raise response.inspect
  end

end
