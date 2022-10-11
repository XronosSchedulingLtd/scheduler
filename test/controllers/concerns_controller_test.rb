require 'test_helper'

class ConcernsControllerTest < ActionController::TestCase

  setup do
    @today = Date.today
    @fortnight = Date.today + 14.days
    @staff = FactoryBot.create(:staff, email: 'able@baker.com')
    @user = FactoryBot.create(
      :user,
      :view_forms,
      email: 'able@baker.com'
    )
    session[:user_id] = @user.id
    @property = FactoryBot.create(:property)
    #
    #  Now a concern for this user with this property.
    #
    @concern = FactoryBot.create(:concern, user: @user, element: @property.element)
    assert @concern.valid?
    assert @user.can_edit?(@concern)
    @existing_report = FactoryBot.create(
      :itemreport,
      concern: @concern,
      starts_on: @today,
      ends_on: @fortnight)
    assert_not_nil @concern.itemreport

    @user_form = FactoryBot.create(:user_form)
    @user_form.elements << @property.element
    @element_property = FactoryBot.create(:property)
    @element = @element_property.element
  end

  test "should get edit" do
    get :edit, params: { id: @concern }
    assert_response :success
    #
    #  Check the report dates are presented correctly.
    #
    assert_select '#itemreport_starts_on' do |fields|
      assert_equal 1, fields.count
      assert_equal @today.to_s(:dmy), fields.first['value']
    end
    assert_select '#itemreport_ends_on' do |fields|
      assert_equal 1, fields.count
      assert_equal @fortnight.to_s(:dmy), fields.first['value']
    end
    assert_select '#form_report_starts_on' do |fields|
      assert_equal 1, fields.count
      assert_equal @today.beginning_of_month.to_s(:dmy), fields.first['value']
    end
    assert_select '#form_report_ends_on' do |fields|
      assert_equal 1, fields.count
      assert_equal @today.end_of_month.to_s(:dmy), fields.first['value']
    end
  end

  test "can create concern" do
    assert_difference('Concern.count') do
      post(
        :create,
        params: {
          concern: {
            element_id: @element.id
          }
        },
        xhr: true
      )
    end
  end

  test "concern inherits list flags" do
    @user.list_rooms = true
    @user.list_teachers = false
    @user.save
    assert_difference('Concern.count') do
      post(
        :create,
        params: {
          concern: {
            element_id: @element.id
          }
        },
        xhr: true
      )
    end
    concern = Concern.last
    assert concern.list_rooms?
    assert_not concern.list_teachers

  end


end
