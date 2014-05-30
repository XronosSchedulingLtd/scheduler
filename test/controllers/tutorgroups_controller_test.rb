require 'test_helper'

class TutorgroupsControllerTest < ActionController::TestCase
  setup do
    @tutorgroup = tutorgroups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tutorgroups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tutorgroup" do
    assert_difference('Tutorgroup.count') do
      post :create, tutorgroup: { current: @tutorgroup.current, era_id: @tutorgroup.era_id, house: @tutorgroup.house, name: @tutorgroup.name, staff_id: @tutorgroup.staff_id, start_year: @tutorgroup.start_year }
    end

    assert_redirected_to tutorgroup_path(assigns(:tutorgroup))
  end

  test "should show tutorgroup" do
    get :show, id: @tutorgroup
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tutorgroup
    assert_response :success
  end

  test "should update tutorgroup" do
    patch :update, id: @tutorgroup, tutorgroup: { current: @tutorgroup.current, era_id: @tutorgroup.era_id, house: @tutorgroup.house, name: @tutorgroup.name, staff_id: @tutorgroup.staff_id, start_year: @tutorgroup.start_year }
    assert_redirected_to tutorgroup_path(assigns(:tutorgroup))
  end

  test "should destroy tutorgroup" do
    assert_difference('Tutorgroup.count', -1) do
      delete :destroy, id: @tutorgroup
    end

    assert_redirected_to tutorgroups_path
  end
end
