#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  setup do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    @group = FactoryBot.create(:group, owner: user)
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
      post(
        :create,
        params: {
          group: {
            current: @group.current,
            era_id: @group.era_id,
            starts_on: @group.starts_on,
            name: @group.name
          }
        }
      )
    end
    assert_redirected_to edit_group_path(assigns(:group), just_created: true)
    assert_no_errors
  end

  test "should clone group" do
    assert_difference('Group.count') do
      post(
        :do_clone,
        params: {
          id: @group
        }
      )
    end
    assert_redirected_to edit_group_path(assigns(:new_group),
                                         just_created: true)
    assert_no_errors
  end

  test "should flatten group" do
    assert_difference('Group.count') do
      post(
        :flatten,
        params: {
          id: @group
        }
      )
    end
    assert_redirected_to edit_group_path(assigns(:new_group),
                                         just_created: true)
    assert_no_errors
  end

  test "should show group" do
    get :show, params: { id: @group }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @group }
    assert_response :success
  end

  test "should update group" do
    patch(
      :update,
      params: {
        id: @group,
        group: {
          current: @group.current,
          era_id: @group.era_id,
          name: @group.name
        }
      }
    )
    assert_redirected_to groups_path
    assert_no_errors
  end

  test "should destroy group" do
    assert_difference('Group.current.count', -1) do
      delete :destroy, params: { id: @group }
    end

    assert_redirected_to groups_path
  end
end
