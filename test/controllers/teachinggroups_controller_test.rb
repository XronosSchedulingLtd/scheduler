require 'test_helper'

class TeachinggroupsControllerTest < ActionController::TestCase
  setup do
    @teachinggroup = teachinggroups(:teachingone)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:teachinggroups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create teachinggroup" do
    assert_difference('Teachinggroup.count') do
      post :create, teachinggroup: { current: @teachinggroup.current, era_id: @teachinggroup.era_id, name: "Banana", source_id: @teachinggroup.source_id }
    end

    assert_redirected_to teachinggroup_path(assigns(:teachinggroup))
  end

  test "should show teachinggroup" do
    get :show, id: @teachinggroup
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @teachinggroup
    assert_response :success
  end

  test "should update teachinggroup" do
    patch :update, id: @teachinggroup, teachinggroup: { current: @teachinggroup.current, era_id: @teachinggroup.era_id, name: @teachinggroup.name, source_id: @teachinggroup.source_id }
    assert_redirected_to teachinggroup_path(assigns(:teachinggroup))
  end

  test "should destroy teachinggroup" do
    assert_difference('Teachinggroup.count', -1) do
      delete :destroy, id: @teachinggroup
    end

    assert_redirected_to teachinggroups_path
  end
end
