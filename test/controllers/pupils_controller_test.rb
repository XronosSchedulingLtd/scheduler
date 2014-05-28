require 'test_helper'

class PupilsControllerTest < ActionController::TestCase
  setup do
    @pupil = pupils(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pupils)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pupil" do
    assert_difference('Pupil.count') do
      post :create, pupil: { candidate_no: @pupil.candidate_no, email: @pupil.email, forename: @pupil.forename, known_as: @pupil.known_as, name: @pupil.name, source_id: @pupil.source_id, start_year: @pupil.start_year, surname: @pupil.surname }
    end

    assert_redirected_to pupil_path(assigns(:pupil))
  end

  test "should show pupil" do
    get :show, id: @pupil
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pupil
    assert_response :success
  end

  test "should update pupil" do
    patch :update, id: @pupil, pupil: { candidate_no: @pupil.candidate_no, email: @pupil.email, forename: @pupil.forename, known_as: @pupil.known_as, name: @pupil.name, source_id: @pupil.source_id, start_year: @pupil.start_year, surname: @pupil.surname }
    assert_redirected_to pupil_path(assigns(:pupil))
  end

  test "should destroy pupil" do
    assert_difference('Pupil.count', -1) do
      delete :destroy, id: @pupil
    end

    assert_redirected_to pupils_path
  end
end
