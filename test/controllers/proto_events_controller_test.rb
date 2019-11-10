require 'test_helper'

class ProtoEventsControllerTest < ActionController::TestCase
  setup do
    @proto_event = proto_events(:fourthexamspe)
    @generator = exam_cycles(:fourthyearexams)
    location = FactoryBot.create(:location)
    @location_element = location.element
    @rota_template = rota_templates(:internalexams)
    session[:user_id] = users(:admin).id
  end

  test "should get index" do
    get :index, format: :json, exam_cycle_id: @generator.id
    assert_response :success
    assert_not_nil assigns(:proto_events)
  end

  test "should create proto_event" do
    assert_difference('ProtoEvent.count') do
      post :create,
           format: :json,
           exam_cycle_id: @generator.id,
           proto_event: {
             rota_template_id: @rota_template.id,
             starts_on_text: @proto_event.starts_on,
             ends_on_text: @proto_event.ends_on,
             num_staff: "1",
             location_id: @location_element.id
           }
    end
    assert_response :success
  end

  test "should update proto_event" do
    patch :update,
          format: :json,
          exam_cycle_id: @generator.id,
          id: @proto_event,
          proto_event: {
            starts_on_text: @proto_event.starts_on,
            ends_on_text: @proto_event.ends_on,
             num_staff: "1",
             location_id: @location_element.id
          }
    assert_response :success
  end

  test "should destroy proto_event" do
    assert_difference('ProtoEvent.count', -1) do
      delete :destroy, format: :json, exam_cycle_id: @generator.id, id: @proto_event
    end
    assert_response :success

  end
end
