require 'test_helper'

class RotaSlotsControllerTest < ActionController::TestCase
  setup do
    @rota_slot = rota_slots(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rota_slots)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create rota_slot" do
    assert_difference('RotaSlot.count') do
      post :create, rota_slot: { days: @rota_slot.days, ends_at: @rota_slot.ends_at, rotatemplate_id: @rota_slot.rotatemplate_id, starts_at: @rota_slot.starts_at }
    end

    assert_redirected_to rota_slot_path(assigns(:rota_slot))
  end

  test "should show rota_slot" do
    get :show, id: @rota_slot
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @rota_slot
    assert_response :success
  end

  test "should update rota_slot" do
    patch :update, id: @rota_slot, rota_slot: { days: @rota_slot.days, ends_at: @rota_slot.ends_at, rotatemplate_id: @rota_slot.rotatemplate_id, starts_at: @rota_slot.starts_at }
    assert_redirected_to rota_slot_path(assigns(:rota_slot))
  end

  test "should destroy rota_slot" do
    assert_difference('RotaSlot.count', -1) do
      delete :destroy, id: @rota_slot
    end

    assert_redirected_to rota_slots_path
  end
end
