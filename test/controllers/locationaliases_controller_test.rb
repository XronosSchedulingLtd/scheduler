require 'test_helper'

class LocationaliasesControllerTest < ActionController::TestCase
  setup do
    @locationalias = FactoryBot.create(:locationalias)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:locationaliases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create locationalias" do
    session[:new_locationalias_from] = locationaliases_path
    assert_difference('Locationalias.count') do
      post(:create,
           params: {
             locationalias: {
               location_id: @locationalias.location_id,
               name: @locationalias.name,
               source_id: @locationalias.source_id
             }
           })
    end

    assert_redirected_to locationaliases_path
    assert_no_errors
  end

  test "should show locationalias" do
    get :show, params: { id: @locationalias }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @locationalias }
    assert_response :success
  end

  test "should update locationalias" do
    session[:editing_locationalias_from] = "/banana"
    patch(
      :update,
      params: {
        id: @locationalias,
        locationalias: {
          location_id: @locationalias.location_id,
          name: @locationalias.name,
          source_id: @locationalias.source_id
        }
      }
    )
    assert_redirected_to "/banana"
    assert_no_errors
  end

  test "should destroy locationalias" do
    assert_difference('Locationalias.count', -1) do
      delete :destroy, params: { id: @locationalias }
    end

    assert_redirected_to locationaliases_path
  end
end
