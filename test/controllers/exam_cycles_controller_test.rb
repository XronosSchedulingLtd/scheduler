require 'test_helper'

class ExamCyclesControllerTest < ActionController::TestCase
  setup do
    @exam_cycle = exam_cycles(:fourthyearexams)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:exam_cycles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create exam_cycle" do
    assert_difference('ExamCycle.count') do
      post :create, exam_cycle: {
        default_rota_template_id: @exam_cycle.default_rota_template_id,
        name: @exam_cycle.name,
        starts_on_text: @exam_cycle.starts_on,
        ends_on_text: @exam_cycle.ends_on,
        default_group_element_id: @exam_cycle.default_group_element_id
      }
    end

    assert_redirected_to exam_cycles_path
  end

  test "should show exam_cycle" do
    get :show, id: @exam_cycle
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @exam_cycle
    assert_response :success
  end

  test "should update exam_cycle" do
    patch :update, id: @exam_cycle, exam_cycle: { default_rota_template_id: @exam_cycle.default_rota_template_id, name: @exam_cycle.name }
    assert_redirected_to exam_cycles_path
  end

  test "should destroy exam_cycle" do
    assert_difference('ExamCycle.count', -1) do
      delete :destroy, id: @exam_cycle
    end

    assert_redirected_to exam_cycles_path
  end
end
