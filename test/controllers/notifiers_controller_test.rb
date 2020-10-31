require 'test_helper'

class NotifiersControllerTest < ActionController::TestCase

  setup do
    @today = Date.today
    @last_run = Date.today - 14.days
    user = FactoryBot.create(
      :user,
      :does_exams,
      email: 'able@baker.com',
      last_invig_run_date: @last_run
    )
    assert user.exams?
    session[:user_id] = user.id
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select '#notifier_start_date_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @today.to_s(:dmy), fields.first['value']
    end
    assert_select '#notifier_modified_since_text' do |fields|
      assert_equal 1, fields.count
      assert_equal @last_run.to_s(:dmy), fields.first['value']
    end
  end

end
