require 'test_helper'

class FreefindersControllerTest < ActionController::TestCase
  setup do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    @user = FactoryBot.create(:user, email: 'able@baker.com')
    session[:user_id] = @user.id
    @source_group = FactoryBot.create(:group)
    3.times do
      @source_group.add_member(FactoryBot.create(:staff))
    end
    @source_group.reload
    assert_equal 3, @source_group.members.count
    @settings = Setting.current
    @staff1 = FactoryBot.create(:staff)
    @staff2 = FactoryBot.create(:staff)
    @staff3 = FactoryBot.create(:staff)
  end

  test "check default days" do
    settings = Setting.first
    assert_equal 5, settings.ft_default_days.size
    assert settings.ft_default_days.include?(1)
    assert settings.ft_default_days.include?(2)
    assert settings.ft_default_days.include?(3)
    assert settings.ft_default_days.include?(4)
    assert settings.ft_default_days.include?(5)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "new date should display as ddmmyyyy" do
    get :new
    assert_response :success
    today = Date.today.to_s(:dmy)
    assert_select '#freefinder_on' do |fields|
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
    assert_select '#freefinder_on' do |fields|
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
    assert_select '#freefinder_on' do |fields|
      assert_equal 1, fields.count
      assert_equal tomorrow_ymd, fields.first['value']
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

  #
  #  And now the tests relating to finding free times.
  #
  test "can invoke edit" do
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
    assert_select '#freefinder_ft_num_days' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_num_days.to_s, fields.first['value']
      assert_equal 7, @settings.ft_default_num_days
    end
    assert_select '#freefinder_ft_day_starts_at' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_day_starts_at.strftime("%H:%M:%S"),
        fields.first['value']
    end
    assert_select '#freefinder_ft_day_ends_at' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_day_ends_at.strftime("%H:%M:%S"),
        fields.first['value']
    end
    assert_select '#freefinder_ft_duration' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_duration.to_s, fields.first['value']
    end
  end

  test "can add an element" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    freefinder = @user.freefinder
    assert_not_nil freefinder
    assert_equal [@staff1.element.id], freefinder.ft_element_ids
  end

  test "can add two element" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    post :add_element,
      params: {id: 1, element_id: @staff2.element.id},
      xhr: true
    assert_response :success
    freefinder = @user.freefinder
    assert_not_nil freefinder
    assert_equal [@staff1.element.id, @staff2.element.id],
      freefinder.ft_element_ids
  end

  test "can remove an element" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    post :add_element,
      params: {id: 1, element_id: @staff2.element.id},
      xhr: true
    assert_response :success
    post :remove_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    freefinder = @user.freefinder
    assert_not_nil freefinder
    assert_equal [@staff2.element.id],
      freefinder.ft_element_ids
  end

  test "can execute search" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    put :update,
      params: {
        id: 1,
        freefinder: {
          ft_start_date: Date.tomorrow
        }
      }
    assert_response :success
    assert_select '.field_with_errors', false, "There should be no errors"
  end

  test "can set num days to 14" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    put :update,
      params: {
        id: 1,
        freefinder: {
          ft_start_date: Date.tomorrow,
          ft_num_days: 14
        }
      }
    assert_response :success
    assert_select '.field_with_errors', false, "There should be no errors"
  end

  test "15 days is too many" do
    post :add_element,
      params: {id: 1, element_id: @staff1.element.id},
      xhr: true
    assert_response :success
    put :update,
      params: {
        id: 1,
        freefinder: {
          ft_start_date: Date.tomorrow,
          ft_num_days: 15
        }
      }
    assert_response :success
    assert_select '.field_with_errors'
    assert_select '#error_explanation' do |fields|
      assert_match /less than or equal to 14/, fields.first.inner_html
    end
  end

  test "can reset form" do
    post :reset, params: {id: 1}
    assert_response :success
    today = Date.today.to_s(:dmy)
    assert_select '#freefinder_ft_start_date' do |fields|
      assert_equal 1, fields.count
      assert_equal today, fields.first['value']
    end
    assert_select '#freefinder_ft_num_days' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_num_days.to_s, fields.first['value']
    end
    assert_select '#freefinder_ft_day_starts_at' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_day_starts_at.strftime("%H:%M:%S"),
        fields.first['value']
    end
    assert_select '#freefinder_ft_day_ends_at' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_day_ends_at.strftime("%H:%M:%S"),
        fields.first['value']
    end
    assert_select '#freefinder_ft_duration' do |fields|
      assert_equal 1, fields.count
      assert_equal @settings.ft_default_duration.to_s, fields.first['value']
    end
    check_checkbox_collection(:ft_days, :ft_default_days, 7)
     
  end

  test "can work with a group" do
    post :add_element,
      params: {id: 1, element_id: @source_group.element.id},
      xhr: true
    assert_response :success
    put :update,
      params: {
        id: 1,
        freefinder: {
          ft_start_date: Date.tomorrow
        }
      }
    assert_response :success
    assert_select '.field_with_errors', false, "There should be no errors"
  end

  private

  def check_checked(field, checked)
    assert_select "#freefinder_#{field}" do |fields|
      assert_equal 1, fields.count
      if checked
        assert_equal "checked", fields.first["checked"]
      else
        assert_nil fields.first["checked"]
      end
    end
  end

  def check_checkbox_collection(field, setting_field, count)
    count.times do |i|
      checked = Setting.current[setting_field].include?(i)
      check_checked("#{field}_#{i}", checked)
    end
  end

end
