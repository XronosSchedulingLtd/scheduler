require 'test_helper'

class RecordingBugTest < ActionDispatch::IntegrationTest
  setup do
    @api_user =
      FactoryBot.create(:user, :api, :editor, :noter, :files)
    #
    #  I can't find it documented anywhere, but once one has
    #  used an engine's url helpers, it seems to be necessary
    #  to explicitly switch back to the main application ones.
    #
    @api_paths = PublicApi::Engine.routes.url_helpers
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

  private

  #
  #  It's cheating to use the API stuff to login, but the documentation
  #  for how to stub out omniauth is impenetrable.
  #
  def do_valid_login(user = @api_user)
    get @api_paths.login_path(uid: user.uuid), format: :json
    assert_response :success
  end

end

