require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  setup do
    @group = FactoryBot.create(:group)
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, :admin, email: 'able@baker.com')
    session[:user_id] = user.id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create group" do
    assert_difference('Group.count') do
      post :create, group: {
        current: @group.current,
        era_id: @group.era_id,
        starts_on: @group.starts_on,
        name: @group.name }
    end

    assert_redirected_to edit_group_path(assigns(:group), just_created: true)
  end

  test "should show group" do
    get :show, id: @group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @group
    assert_response :success
  end

  test "should update group" do
    patch :update, id: @group, group: { current: @group.current, era_id: @group.era_id, name: @group.name  }
    assert_redirected_to groups_path
  end

  test "should destroy group" do
    assert_difference('Group.current.count', -1) do
      delete :destroy, id: @group
    end

    assert_redirected_to groups_path
  end
end
