require 'test_helper'

class UserFormResponsesControllerTest < ActionController::TestCase
  setup do
    @user_form_response = FactoryBot.create(:user_form_response)
    @user_form = @user_form_response.user_form
    @user = users(:one)
    session[:user_id] = users(:admin).id
    session[:return_to] = user_form_path(@user_form)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_form_responses)
  end

  test "should get new" do
    get :new, params: { user_form_id: @user_form.id }
    assert_response :success
  end

  test "should create user_form_response" do
    assert_difference('UserFormResponse.count') do
      post(
        :create,
        params: {
          user_form_id: @user_form.id,
          user_id: @user.id,
          user_form_response: {
            form_data: @user_form_response.form_data,
            parent_id: @user_form_response.parent_id,
            parent_type: @user_form_response.parent_type
          }
        }
      )
    end

    assert_redirected_to user_form_path(@user_form)
  end

  test "should show user_form_response" do
    get :show, params: { id: @user_form_response }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @user_form_response }
    assert_response :success
  end

  test "should update user_form_response" do
    patch(
      :update,
      params: {
        id: @user_form_response,
        user_form_response: {
          form_data: @user_form_response.form_data,
          parent_id: @user_form_response.parent_id,
          parent_type: @user_form_response.parent_type,
          user_form_id: @user_form_response.user_form_id,
          user_id: @user_form_response.user_id
        }
      }
    )
    assert_redirected_to user_form_path(@user_form)
  end

  test "should destroy user_form_response" do
    assert_difference('UserFormResponse.count', -1) do
      delete :destroy, params: { id: @user_form_response }
    end

    assert_redirected_to user_form_user_form_responses_path(@user_form)
  end
end
