require 'test_helper'

class FreefindersControllerTest < ActionController::TestCase
  setup do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(:user, email: 'able@baker.com')
    session[:user_id] = user.id
    @source_group = FactoryBot.create(:group)
    3.times do
      @source_group.add_member(FactoryBot.create(:staff))
    end
    @source_group.reload
    assert_equal 3, @source_group.members.count
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "new date should display as ddmmyyyy" do
    get :new
    assert_response :success
    today = Date.today.to_s(:dmy)
    assert_select '#freedatepicker' do |fields|
      assert_equal 1, fields.count
      assert_equal today, fields.first['value']
    end
  end

  test "can update new date with ddmmyyyy" do
    tomorrow_dmy = Date.tomorrow.to_s(:dmy)
    post(
      :create,
      params: {
        freefinder: {
          element_id: @source_group.element,
          on: tomorrow_dmy
        }
      }
    )
    assert_response :success
    assert_select '#freedatepicker' do |fields|
      assert_equal 1, fields.count
      assert_equal tomorrow_dmy, fields.first['value']
    end

  end

  test "can update new date with yyyymmdd" do
    tomorrow_dmy = Date.tomorrow.to_s(:dmy)
    tomorrow_ymd = Date.tomorrow.to_s(:ymd)
    post(
      :create,
      params: {
        freefinder: {
          element_id: @source_group.element,
          on: tomorrow_ymd
        }
      }
    )
    assert_response :success
    #
    #  We would normally expect the date to have been converted by the
    #  controller into dd/mm/yyyy, but in this instance the controller
    #  doesn't actually save the record to the database, so we get back
    #  what we sent.
    #
    assert_select '#freedatepicker' do |fields|
      assert_equal 1, fields.count
      assert_equal tomorrow_ymd, fields.first['value']
    end
  end

  test "edit date should display as ddmmyyyy" do
    #
    #  It doesn't matter what ID we specify - what we get is the
    #  freefinder attached to the user, which will be created
    #  from scratch if needs be.
    #
    get :edit, params: {id: 1}
    assert_response :success
    today = Date.today.to_s(:dmy)
    assert_select '#freefinder_ft_start_date' do |fields|
      assert_equal 1, fields.count
      assert_equal today, fields.first['value']
    end
  end

  test "should create group" do
    assert_difference('Group.count') do
      post(
        :create,
        params: {
          freefinder: {
            element_id: @source_group.element
          },
          create: "Create group"
        }
      )
    end
    assert_redirected_to edit_group_path(assigns(:new_group),
                                         just_created: true)
  end

end
