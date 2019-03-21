require 'test_helper'

class ErasControllerTest < ActionController::TestCase
  setup do
    @era = eras(:eraone)
    @eratodelete = eras(:eratwo)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:eras)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create era" do
    assert_difference('Era.count') do
      post(
        :create,
        params: {
          era: {
            ends_on: @era.ends_on,
            name: @era.name,
            starts_on: @era.starts_on
          }
        }
      )
    end

    assert_redirected_to era_path(assigns(:era))
  end

  test "should show era" do
    get :show, params: { id: @era }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @era }
    assert_response :success
  end

  test "should update era" do
    patch(
      :update,
      params: {
        id: @era,
        era: {
          ends_on: @era.ends_on,
          name: @era.name,
          starts_on: @era.starts_on
        }
      }
    )
    assert_redirected_to eras_path
  end

  test "should destroy era" do
    request.env["HTTP_REFERER"] = "/"
    assert_difference('Era.count', -1) do
      delete :destroy, params: { id: @eratodelete }
    end

    assert_redirected_to eras_path
  end

  test "should fail to destroy era" do
    request.env["HTTP_REFERER"] = "/"
    assert_difference('Era.count', 0) do
      delete :destroy, params: { id: @era }
    end

    assert_redirected_to "/"
  end
end
