require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  setup do
    @event = events(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create event" do
    assert_difference('Event.count') do
      post :create, event: { approximate: @event.approximate, body: @event.body, ends_at: @event.ends_at, eventcategory_id: @event.eventcategory_id, eventsource_id: @event.eventsource_id, non_existent: @event.non_existent, owner_id: @event.owner_id, private: @event.private, reference_id: @event.reference_id, reference_type: @event.reference_type, starts_at: @event.starts_at }
    end

    assert_redirected_to event_path(assigns(:event))
  end

  test "should show event" do
    get :show, id: @event
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @event
    assert_response :success
  end

  test "should update event" do
    patch :update, id: @event, event: { approximate: @event.approximate, body: @event.body, ends_at: @event.ends_at, eventcategory_id: @event.eventcategory_id, eventsource_id: @event.eventsource_id, non_existent: @event.non_existent, owner_id: @event.owner_id, private: @event.private, reference_id: @event.reference_id, reference_type: @event.reference_type, starts_at: @event.starts_at }
    assert_redirected_to event_path(assigns(:event))
  end

  test "should destroy event" do
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event
    end

    assert_redirected_to events_path
  end
end
