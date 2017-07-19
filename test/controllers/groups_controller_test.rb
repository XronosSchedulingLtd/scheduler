require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  setup do
    @group = groups(:groupone)
    session[:user_id] = users(:admin).id
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
#      puts assigns(:group).errors.inspect
#      assigns(:group).reload
#      puts assigns(:group).element.uuid
    end

    assert_redirected_to edit_group_path(assigns(:group))
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

  #
  #  This test needs re-thinking.  In general, we don't delete groups,
  #  merely mark them as over.
  #
#  test "should destroy group" do
#    assert_difference('Group.count', -1) do
#      delete :destroy, id: @group
#    end

#    assert_redirected_to groups_path
#  end
  test "should destroy group" do
    assert_difference('Group.current.count', -1) do
      delete :destroy, id: @group
    end

    assert_redirected_to groups_path
  end
end
