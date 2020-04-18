require 'test_helper'

class EventcategoriesControllerTest < ActionController::TestCase
  setup do
    @eventcategory = eventcategories(:one)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:eventcategories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create eventcategory" do
    assert_difference('Eventcategory.count') do
      post(
        :create,
        params: {
          eventcategory: {
            for_users: @eventcategory.for_users,
            name: "Charlie",
            pecking_order: @eventcategory.pecking_order,
            public: @eventcategory.public,
            publish: @eventcategory.publish,
            schoolwide: @eventcategory.schoolwide,
            unimportant: @eventcategory.unimportant
          }
        }
      )
    end

    assert_redirected_to eventcategories_path
  end

  test "should show eventcategory" do
    get :show, params: {id: @eventcategory}
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: {id: @eventcategory}
    assert_response :success
  end

  test "should update eventcategory" do
    patch(
      :update,
      params: {
        id: @eventcategory,
        eventcategory: {
          for_users: @eventcategory.for_users,
          name: @eventcategory.name,
          pecking_order: @eventcategory.pecking_order,
          public: @eventcategory.public,
          publish: @eventcategory.publish,
          schoolwide: @eventcategory.schoolwide,
          unimportant: @eventcategory.unimportant
        }
      }
    )
    assert_redirected_to eventcategories_path
  end

  test "should destroy eventcategory" do
    assert_difference('Eventcategory.count', -1) do
      delete :destroy, params: {id: @eventcategory}
    end

    assert_redirected_to eventcategories_path
  end
end
