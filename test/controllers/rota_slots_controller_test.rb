require 'test_helper'

class RotaSlotsControllerTest < ActionController::TestCase
  setup do
    @rota_template = rota_templates(:internalexams)
    @rota_slot = rota_slots(:ie1)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index, format: :json, params: { rota_template_id: @rota_template.id }
    assert_response :success
    assert_not_nil assigns(:rota_slots)
  end

  test "should create rota_slot" do
    assert_difference('RotaSlot.count') do
      post(
        :create,
        format: :json,
        params: {
          rota_template_id: @rota_template.id,
          rota_slot: {
            days: @rota_slot.days,
            ends_at: @rota_slot.ends_at,
            starts_at: @rota_slot.starts_at
          }
        }
      )
    end
    assert_response :success
  end

  test "should update rota_slot" do
    patch(
      :update,
      format: :json,
      params: {
        rota_template_id: @rota_template.id,
        id: @rota_slot,
        rota_slot: {
          days: @rota_slot.days,
          ends_at: @rota_slot.ends_at,
          starts_at: @rota_slot.starts_at
        }
      }
    )
    assert_response :success
  end

  test "should destroy rota_slot" do
    assert_difference('RotaSlot.count', -1) do
      delete(
        :destroy,
        format: :json,
        params: {
          rota_template_id: @rota_template.id,
          id: @rota_slot
        }
      )
    end
    assert_response :success
  end
end
