require 'test_helper'

class ProtoEventsControllerTest < ActionController::TestCase
  setup do
    @proto_event = proto_events(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:proto_events)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create proto_event" do
    assert_difference('ProtoEvent.count') do
      post :create, proto_event: { body: @proto_event.body, ends_on: @proto_event.ends_on, event_category_id: @proto_event.event_category_id, event_source_id: @proto_event.event_source_id, starts_on: @proto_event.starts_on }
    end

    assert_redirected_to proto_event_path(assigns(:proto_event))
  end

  test "should show proto_event" do
    get :show, id: @proto_event
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @proto_event
    assert_response :success
  end

  test "should update proto_event" do
    patch :update, id: @proto_event, proto_event: { body: @proto_event.body, ends_on: @proto_event.ends_on, event_category_id: @proto_event.event_category_id, event_source_id: @proto_event.event_source_id, starts_on: @proto_event.starts_on }
    assert_redirected_to proto_event_path(assigns(:proto_event))
  end

  test "should destroy proto_event" do
    assert_difference('ProtoEvent.count', -1) do
      delete :destroy, id: @proto_event
    end

    assert_redirected_to proto_events_path
  end
end
