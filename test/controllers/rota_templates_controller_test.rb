require 'test_helper'

class RotaTemplatesControllerTest < ActionController::TestCase
  setup do
    @rota_template = rota_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rota_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create rota_template" do
    assert_difference('RotaTemplate.count') do
      post :create, rota_template: { name: @rota_template.name }
    end

    assert_redirected_to rota_template_path(assigns(:rota_template))
  end

  test "should show rota_template" do
    get :show, id: @rota_template
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @rota_template
    assert_response :success
  end

  test "should update rota_template" do
    patch :update, id: @rota_template, rota_template: { name: @rota_template.name }
    assert_redirected_to rota_template_path(assigns(:rota_template))
  end

  test "should destroy rota_template" do
    assert_difference('RotaTemplate.count', -1) do
      delete :destroy, id: @rota_template
    end

    assert_redirected_to rota_templates_path
  end
end
