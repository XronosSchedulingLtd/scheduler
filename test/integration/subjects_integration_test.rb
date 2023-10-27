require 'test_helper'

class SubjectsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user =
      FactoryBot.create(
        :user, :admin, :editor, :noter, :files, :memberships,
        user_profile: UserProfile.staff_profile)
    @manual_datasource = Datasource.find_by(name: "Manual")
    @mis_datasource = Datasource.find_by(name: "School MIS")
    @manual_subject =
      FactoryBot.create(
        :subject, datasource: @manual_datasource, name: "A manual subject")
    @mis_subject =
      FactoryBot.create(
        :subject, datasource: @mis_datasource, name: "A MIS subject")
  end

  test 'must login first' do
    get new_subject_path
    assert_redirected_to sessions_new_path
  end

  test 'can edit name etc of new subject' do
    do_valid_login
    get new_subject_path
    assert_response :success
    assert_select '#subject_name' do |name_field|
      assert_not name_field.attr("disabled").present?
    end
    assert_select '#subject_current' do |current_field|
      assert_not current_field.attr("disabled").present?
    end
    assert_select '#subject_missable' do |missable_field|
      assert_not missable_field.attr("disabled").present?
    end
    assert_select '#subject_datasource_name' do |datasource_name_field|
      assert datasource_name_field.attr("disabled").present?
      assert_select '[value=?]', "Manual"
    end
  end

  test 'can edit existing manual subject' do
    do_valid_login
    get edit_subject_path(@manual_subject)
    assert_response :success
    assert_select '#subject_name' do |name_field|
      assert_not name_field.attr("disabled").present?
      assert_select '[value=?]', @manual_subject.name 
    end
    assert_select '#subject_current' do |current_field|
      assert_not current_field.attr("disabled").present?
    end
    assert_select '#subject_missable' do |missable_field|
      assert_not missable_field.attr("disabled").present?
    end
    assert_select '#subject_datasource_name' do |datasource_name_field|
      assert datasource_name_field.attr("disabled").present?
      assert_select '[value=?]', @manual_datasource.name
    end
  end


  test 'cannot really edit existing mis subject' do
    do_valid_login
    get edit_subject_path(@mis_subject)
    assert_response :success
    assert_select '#subject_name' do |name_field|
      assert name_field.attr("disabled").present?
      assert_select '[value=?]', @mis_subject.name 
    end
    assert_select '#subject_current' do |current_field|
      assert current_field.attr("disabled").present?
    end
    assert_select '#subject_missable' do |missable_field|
      assert_not missable_field.attr("disabled").present?
    end
    assert_select '#subject_datasource_name' do |datasource_name_field|
      assert datasource_name_field.attr("disabled").present?
      assert_select '[value=?]', @mis_datasource.name
    end
  end


  private 

  #
  #  Note that we're using a test-specific path to login - not available
  #  in development or production mode.  We're not testing the login
  #  functionality; we just need a really easy way to get to a state
  #  of "logged in" so we can do our other testing.
  #
  def do_valid_login(user = @admin_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

end

