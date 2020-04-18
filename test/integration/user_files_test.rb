require 'test_helper'

class UserFilesTest < ActionDispatch::IntegrationTest
  setup do
    @ordinary_user =
      FactoryBot.create(
        :user, :editor, :noter, :files,
        user_profile: UserProfile.staff_profile)
    @admin_user =
      FactoryBot.create(
        :user, :editor, :noter, :admin, :files,
        user_profile: UserProfile.staff_profile)
    @file1 = FactoryBot.create(:user_file, owner: @ordinary_user)
    @file2 = FactoryBot.create(:user_file, owner: @ordinary_user)
    @file3 = FactoryBot.create(:user_file, owner: @admin_user)
    s = Setting.first
    s.user_file_allowance = 10
    s.save
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
    get user_files_path, format: :json
    assert_response :success
    response_data = unpack_response(response)
    files = response_data['files']
    assert_instance_of Array, files
    assert_equal 2, files.size
  end

  test 'can list own files implicitly html' do
    do_valid_login
    get user_files_path
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'can list users files json' do
    do_valid_login
    get user_user_files_path(@ordinary_user), format: :json
    assert_response :success
    response_data = unpack_response(response)
    files = response_data['files']
    assert_instance_of Array, files
    assert_equal 2, files.size
  end

  test 'can list users files html' do
    do_valid_login
    get user_user_files_path(@ordinary_user)
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'admin can list files of other user json' do
    do_valid_login(@admin_user)
    get user_user_files_path(@ordinary_user), format: :json
    assert_response :success
    response_data = unpack_response(response)
    files = response_data['files']
    assert_instance_of Array, files
    assert_equal 2, files.size
  end

  test 'admin can list files of other user html' do
    do_valid_login(@admin_user)
    get user_user_files_path(@ordinary_user)
    assert_response :success
    assert_select 'table#file-listing th', minimum: 5
    assert_select 'table#file-listing tbody tr', 2
  end

  test 'ordinary user cannot list files of others json' do
    do_valid_login(@ordinary_user)
    get user_user_files_path(@admin_user), format: :json
    assert_response 302
  end

  test 'ordinary user cannot list files of others html' do
    do_valid_login(@ordinary_user)
    get user_user_files_path(@admin_user)
    assert_response 302
  end

  private

  #
  #  Note that we're using a test-specific path to login - not available
  #  in development or production mode.  We're not testing the login
  #  functionality; we just need a really easy way to get to a state
  #  of "logged in" so we can do our other testing.
  #
  def do_valid_login(user = @ordinary_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

  def unpack_response(response)
    response_data = JSON.parse(response.body)
    assert_instance_of Hash, response_data
    assert_not_nil response_data['allow_upload']
    assert_not_nil response_data['allowance']
    assert_not_nil response_data['total_size']
    assert_not_nil response_data['files']
    response_data
  end

end

