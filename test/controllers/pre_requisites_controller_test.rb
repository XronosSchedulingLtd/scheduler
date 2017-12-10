require 'test_helper'

class PreRequisitesControllerTest < ActionController::TestCase
  setup do
    @pre_requisite = pre_requisites(:one)
    session[:user_id] = users(:admin).id
    @element = elements(:staffoneelement)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pre_requisites)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pre_requisite" do
    assert_difference('PreRequisite.count') do
      post :create, pre_requisite: {
        description: @pre_requisite.description,
        element_id: @element.id,
        label: @pre_requisite.label,
        priority: @pre_requisite.priority }
    end

    assert_redirected_to pre_requisites_path
  end

  test "should show pre_requisite" do
    get :show, id: @pre_requisite
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pre_requisite
    assert_response :success
  end

  test "should update pre_requisite" do
    patch :update, id: @pre_requisite, pre_requisite: {
      description: @pre_requisite.description,
      element_id: @element.id,
      label: @pre_requisite.label,
      priority: @pre_requisite.priority
    }
    assert_redirected_to pre_requisites_path
  end

  test "should destroy pre_requisite" do
    assert_difference('PreRequisite.count', -1) do
      delete :destroy, id: @pre_requisite
    end

    assert_redirected_to pre_requisites_path
  end
end
