require 'test_helper'

class ProtoEventsControllerTest < ActionController::TestCase
  setup do
    @rota_template = FactoryBot.create(:rota_template)
    @exam_cycle    = FactoryBot.create(:exam_cycle,
                                       default_rota_template: @rota_template)
    location = FactoryBot.create(:location)
    @location_element = location.element
    @valid_params = {
      body:             "I'm a proto event",
      rota_template_id: @rota_template.id,
      starts_on_text:   "2017-05-01",
      ends_on_text:     "2017-05-07",
      num_staff:        "1",
      location_id:      @location_element.id
    }
    #
    #  There is an apparent limitation in FactoryBot which prevents
    #  me assigning arbitrary attributes to the model which I am creating.
    #
    #  Hence we have to do this one manually.
    #
    @existing_proto_event =
      @exam_cycle.proto_events.create!(@valid_params)
    #
    session[:user_id] = users(:admin).id
  end

  test "have existing proto_event" do
    assert @existing_proto_event.valid?
  end

  test "should get index" do
    get :index, format: :json, exam_cycle_id: @exam_cycle.id
    assert_response :success
    assert_not_nil assigns(:proto_events)
  end

  test "should create proto_event" do
    assert_difference('ProtoEvent.count') do
      post :create,
           format: :json,
           exam_cycle_id: @exam_cycle.id,
           proto_event: @valid_params
    end
    assert_response :success
  end

  test "should update proto_event" do
    patch :update,
          format: :json,
          exam_cycle_id: @exam_cycle.id,
          id: @existing_proto_event,
          proto_event: @valid_params
    assert_response :success
  end

  test "should destroy proto_event" do
    assert_difference('ProtoEvent.count', -1) do
      delete :destroy, format: :json, exam_cycle_id: @exam_cycle.id, id: @existing_proto_event
    end
    assert_response :success

  end

end
