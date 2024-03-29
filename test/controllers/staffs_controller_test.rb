require 'test_helper'

class StaffsControllerTest < ActionController::TestCase
  setup do
    @staff = staffs(:staffone)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:staffs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create staff" do
    assert_difference('Staff.count') do
      post(
        :create,
        params: {
          staff: {
            active: @staff.active,
            current: @staff.current,
            email: @staff.email,
            forename: @staff.forename,
            initials: @staff.initials,
            name: @staff.name,
            source_id: @staff.source_id,
            surname: @staff.surname,
            title: @staff.title
          }
        }
      )
    end

    assert_redirected_to staff_path(assigns(:staff))
    assert_no_errors
  end

  test "should show staff" do
    get :show, params: { id: @staff }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @staff }
    assert_response :success
  end

  test "should update staff" do
    patch(
      :update,
      params: {
        id: @staff,
        staff: {
          active: @staff.active,
          current: @staff.current,
          email: @staff.email,
          forename: @staff.forename,
          initials: @staff.initials,
          name: @staff.name,
          source_id: @staff.source_id,
          surname: @staff.surname,
          title: @staff.title
        }
      }
    )
    assert_redirected_to staffs_path
    assert_no_errors
  end

  test "should destroy staff" do
    assert_difference('Staff.count', -1) do
      delete :destroy, params: { id: @staff }
    end

    assert_redirected_to staffs_path
  end
end
