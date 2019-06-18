require 'test_helper'

class UserFilesTest < ActionDispatch::IntegrationTest
  setup do
    @api_user = FactoryBot.create(:user, :api, :editor, :noter)
    @admin_user = FactoryBot.create(:user, :api, :editor, :noter, :admin)
    @file1 = FactoryBot.create(:user_file, owner: @api_user)
    @file2 = FactoryBot.create(:user_file, owner: @api_user)
    @file3 = FactoryBot.create(:user_file, owner: @admin_user)
    #
    #  I can't find it documented anywhere, but once one has
    #  used an engine's url helpers, it seems to be necessary
    #  to explicitly switch back to the main application ones.
    #
    @api_paths = PublicApi::Engine.routes.url_helpers
    @main_paths = Rails.application.routes.url_helpers
  end

  test 'bug in url helpers' do
    #
    #  This test exists to record an apparent bug in the helpers.
    #
    #  After I do a login using the API, the helpers change
    #  what they return, pre-pending "/api" to otherwise valid
    #  paths.
    #
    org_path = user_files_path()
    do_valid_login
    assert_not_equal org_path, user_files_path()
  end

  test 'guest cannot list files json' do
    get user_files_path, format: :json
    assert_response 302
  end

  test 'guest cannot list files html' do
    get user_files_path
    assert_response 302
  end

  test 'can list own files implicitly json' do
    do_valid_login
    get @main_paths.user_files_path, format: :json
    assert_response :success
    response_data = unpack_response(response)
    assert_equal 2, response_data.size
  end

  test 'can list own files implicitly html' do
    do_valid_login
    get @main_paths.user_files_path
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'can list users files json' do
    do_valid_login
    get @main_paths.user_user_files_path(@api_user), format: :json
    assert_response :success
    response_data = unpack_response(response)
    assert_equal 2, response_data.size
  end

  test 'can list users files html' do
    do_valid_login
    get @main_paths.user_user_files_path(@api_user)
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'admin can list files of other user json' do
    do_valid_login(@admin_user)
    get @main_paths.user_user_files_path(@api_user), format: :json
    assert_response :success
    response_data = unpack_response(response)
    assert_equal 2, response_data.size
  end

  test 'admin can list files of other user html' do
    do_valid_login(@admin_user)
    get @main_paths.user_user_files_path(@api_user)
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'ordinary user cannot list files of others json' do
    do_valid_login(@api_user)
    get @main_paths.user_user_files_path(@admin_user), format: :json
    assert_response 302
  end

  test 'ordinary user cannot list files of others html' do
    do_valid_login(@api_user)
    get @main_paths.user_user_files_path(@admin_user)
    assert_response 302
  end

  private

  #
  #  It's cheating to use the API stuff to login, but the documentation
  #  for how to stub out omniauth is impenetrable.
  #
  def do_valid_login(user = @api_user)
    get @api_paths.login_path(uid: user.uuid), format: :json
    assert_response :success
  end

  def unpack_response(response)
    response_data = JSON.parse(response.body)
    assert_instance_of Array, response_data
    response_data
  end

end

