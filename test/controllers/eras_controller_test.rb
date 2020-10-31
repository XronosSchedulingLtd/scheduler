require 'test_helper'

class ErasControllerTest < ActionController::TestCase
  setup do
    @era = eras(:eraone)
    @eratodelete = eras(:eratwo)
    session[:user_id] = users(:admin).id

    @eratoedit = FactoryBot.create(
      :era,
      starts_on: Date.parse("2016-09-01"),
      ends_on: Date.parse("2017-08-31")
    )
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:eras)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create era" do
    assert_difference('Era.count') do
      post(
        :create,
        params: {
          era: {
            ends_on: @era.ends_on,
            name: @era.name,
            starts_on: @era.starts_on
          }
        }
      )
    end

    assert_redirected_to era_path(assigns(:era))
  end

  test "should show era" do
    get :show, params: { id: @era }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { id: @era }
    assert_response :success
  end

  test "should update era" do
    patch(
      :update,
      params: {
        id: @era,
        era: {
          ends_on: @era.ends_on,
          name: @era.name,
          starts_on: @era.starts_on
        }
      }
    )
    assert_redirected_to eras_path
  end

  test "should destroy era" do
    request.env["HTTP_REFERER"] = "/"
    assert_difference('Era.count', -1) do
      delete :destroy, params: { id: @eratodelete }
    end

    assert_redirected_to eras_path
  end

  test "should fail to destroy era" do
    request.env["HTTP_REFERER"] = "/"
    assert_difference('Era.count', 0) do
      delete :destroy, params: { id: @era }
    end

    assert_redirected_to "/"
  end

  test "date should display as ddmmyyyy" do
    get :edit, params: { id: @eratoedit }
    assert_response :success
    assert_select '#era_starts_on' do |fields|
      assert_equal 1, fields.count
      assert_equal "01/09/2016", fields.first['value']
    end
    assert_select '#era_ends_on' do |fields|
      assert_equal 1, fields.count
      assert_equal "31/08/2017", fields.first['value']
    end
  end

  test "can update date with ddmmyyyy" do
    patch(
      :update,
      params: {
        id: @eratoedit,
        era: {
          starts_on: "02/09/2016",
          ends_on: "10/09/2016"
        }
      }
    )
    assert_redirected_to eras_path
    @eratoedit.reload
    assert_equal Date.parse("2016-09-02"), @eratoedit.starts_on
    assert_equal Date.parse("2016-09-10"), @eratoedit.ends_on
  end

  test "can update date with yyyymmdd" do
    patch(
      :update,
      params: {
        id: @eratoedit,
        era: {
          starts_on: "2016-09-02",
          ends_on: "2016-09-10"
        }
      }
    )
    assert_redirected_to eras_path
    @eratoedit.reload
    assert_equal Date.parse("2016-09-02"), @eratoedit.starts_on
    assert_equal Date.parse("2016-09-10"), @eratoedit.ends_on
  end


end
