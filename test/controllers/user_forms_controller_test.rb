require 'test_helper'

class UserFormsControllerTest < ActionController::TestCase
  setup do
    @user_form = user_forms(:one)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_forms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_form" do
    assert_difference('UserForm.count') do
      post(
        :create,
        params: {
          user_form: {
            definition: @user_form.definition,
            name: @user_form.name
          }
        }
      )
    end

    assert_redirected_to user_forms_path
    assert_no_errors
  end

  test "should show user_form" do
    get :show, params: { id: @user_form }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @user_form }
    assert_response :success
  end

  test "should update user_form" do
    patch(
      :update,
      params: {
        id: @user_form,
        user_form: {
          definition: @user_form.definition,
          name: @user_form.name 
        }
      }
    )
    assert_redirected_to user_forms_path
    assert_no_errors
  end

  test "should destroy user_form" do
    assert_difference('UserForm.count', -1) do
      delete :destroy, params: { id: @user_form }
    end

    assert_redirected_to user_forms_path
  end
end
