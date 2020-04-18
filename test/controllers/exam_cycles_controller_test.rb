require 'test_helper'

class ExamCyclesControllerTest < ActionController::TestCase
  setup do
    selector_entity = FactoryBot.create(:property)
    location1 = FactoryBot.create(:location)
    location2 = FactoryBot.create(:location)
    @num_rooms = 2
    @exam_cycle = FactoryBot.create(:exam_cycle,
                                    selector_element: selector_entity.element)
    exam_session = 
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("08:45").on(Date.today),
        ends_at: Tod::TimeOfDay.parse("12:00").on(Date.today),
        commitments_to: [selector_entity, location1, location2])
    #
    #  The above event should give 6 invigilation slots per room.
    #
    @slots_per_room = 6
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
      post :create,
           params: {
             exam_cycle: {
               default_rota_template_id: @exam_cycle.default_rota_template_id,
               name: @exam_cycle.name,
               starts_on_text: @exam_cycle.starts_on,
               ends_on_text: @exam_cycle.ends_on,
               default_group_element_id: @exam_cycle.default_group_element_id
             }
           }
    end

    assert_redirected_to exam_cycles_path
  end

  test "should show exam_cycle" do
    get :show, params: { id: @exam_cycle }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @exam_cycle }
    assert_response :success
  end

  test "should update exam_cycle" do
    patch :update,
          params: {
            id: @exam_cycle,
            exam_cycle: {
              default_rota_template_id: @exam_cycle.default_rota_template_id,
              name: @exam_cycle.name
            }
          }
    assert_redirected_to exam_cycles_path
  end

  test "should destroy exam_cycle" do
    assert_difference('ExamCycle.count', -1) do
      delete :destroy, params: { id: @exam_cycle }
    end

    assert_redirected_to exam_cycles_path
  end

  test "can scan rooms and create proto_events" do
    assert_equal 0, @exam_cycle.proto_events.count
    put :scan_rooms, params: { id: @exam_cycle }
    assert_redirected_to exam_cycle_path(@exam_cycle)
    #
    #  One proto event per room.
    #
    assert_equal @num_rooms, @exam_cycle.proto_events.count
  end

  test "can generate invigilation slots" do
    put :scan_rooms, params: { id: @exam_cycle }
    assert_redirected_to exam_cycle_path(@exam_cycle)
    put :generate_all, params: { id: @exam_cycle }
    assert_redirected_to exam_cycle_path(@exam_cycle)
    @exam_cycle.reload
    num_proto_events = 0
    @exam_cycle.proto_events.each do |pe|
      assert_equal @slots_per_room, pe.events.count
      num_proto_events += 1
    end
    assert_equal @num_rooms, num_proto_events
  end

end
