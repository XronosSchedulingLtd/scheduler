require 'test_helper'

class RotaTemplatesControllerTest < ActionController::TestCase
  setup do
    @rota_template = rota_templates(:internalexams)
    @rota_template_type = rota_template_types(:invigilation)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index, rota_template_type_id: @rota_template_type.id
    assert_response :success
    assert_not_nil assigns(:rota_templates)
  end

  test "should get new" do
    get :new,
        rota_template_type_id: @rota_template_type.id
    assert_response :success
  end

  test "should create rota_template" do
    assert_difference('RotaTemplate.count') do
      post :create,
           rota_template_type_id: @rota_template_type.id,
           rota_template: { name: @rota_template.name }
    end
    assert_redirected_to rota_template_path(assigns(:rota_template))
  end

  test "should show rota_template" do
    get :show, id: @rota_template
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

    assert_redirected_to rota_template_type_rota_templates_path(@rota_template_type)
  end
end
