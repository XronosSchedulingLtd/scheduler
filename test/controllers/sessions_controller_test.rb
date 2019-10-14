require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @ordinary_user =
      FactoryBot.create(:user, user_profile: UserProfile.staff_profile)
    @admin_user =
      FactoryBot.create(:user, :admin, user_profile: UserProfile.staff_profile)
    @api_user =
      FactoryBot.create(:user, :api, user_profile: UserProfile.staff_profile)
    @su_user =
      FactoryBot.create(:user, :su, user_profile: UserProfile.staff_profile)
    @su_admin_user =
      FactoryBot.create(:user, :admin, :su,
                        user_profile: UserProfile.staff_profile)
    @su_user2 =
      FactoryBot.create(:user, :su, user_profile: UserProfile.staff_profile)
  end

  test "should get new" do
    get :new
    assert_redirected_to '/auth/google_oauth2'
  end

  test "should get destroy" do
    session[:user_id] = @ordinary_user.id
    get :destroy
    assert_redirected_to '/'
  end

  test "ordinary user cannot su" do
    session[:user_id] = @ordinary_user.id
    put :become, user_id: @api_user.id
    assert_redirected_to '/'
    #
    #  User should not have changed.
    #
    assert_equal @ordinary_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test "privileged user can su" do
    session[:user_id] = @su_user.id
    put :become, user_id: @api_user.id
    assert_redirected_to '/'
    #
    #  User should have changed.
    #
    assert_equal @api_user.id, session[:user_id]
    assert_equal @su_user.id, session[:original_user_id]
  end

  test "can revert after su" do
    session[:user_id] = @su_user.id
    put :become, user_id: @api_user.id
    assert_redirected_to '/'
    #
    #  User should have changed.
    #
    assert_equal @api_user.id, session[:user_id]
    assert_equal @su_user.id, session[:original_user_id]
    put :revert
    assert_redirected_to '/'
    #
    #  And now back again
    #
    assert_equal @su_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test "a revert without an su has no effect" do
    session[:user_id] = @su_user.id
    put :revert
    assert_redirected_to '/'
    assert_equal @su_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test "second su should not succeed" do
    session[:user_id] = @su_user.id
    put :become, user_id: @su_user2.id
    assert_redirected_to '/'
    #
    #  User should have changed.
    #
    assert_equal @su_user2.id, session[:user_id]
    assert_equal @su_user.id, session[:original_user_id]
    #
    #  And now try to su again.  We have permission, but it should
    #  fail because we are already su'ed.
    #
    put :become, user_id: @api_user.id
    assert_redirected_to '/'
    #
    #  User should not have changed.
    #
    assert_equal @su_user2.id, session[:user_id]
    assert_equal @su_user.id, session[:original_user_id]
  end

  test "cannot su to oneself" do
    session[:user_id] = @su_user.id
    put :become, user_id: @su_user.id
    assert_redirected_to '/'
    #
    #  User should not have changed.
    #
    assert_equal @su_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test "cannot su to non-existent user" do
    session[:user_id] = @su_user.id
    put :become, user_id: 999
    assert_redirected_to '/'
    #
    #  User should not have changed.
    #
    assert_equal @su_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test 'cannot su to admin if not admin' do
    session[:user_id] = @su_user.id
    put :become, user_id: @admin_user.id
    assert_redirected_to '/'
    #
    #  User should not have changed.
    #
    assert_equal @su_user.id, session[:user_id]
    assert_nil session[:original_user_id]
  end

  test 'can su to admin if already admin' do
    session[:user_id] = @su_admin_user.id
    put :become, user_id: @admin_user.id
    assert_redirected_to '/'
    #
    #  User should have changed.
    #
    assert_equal @admin_user.id, session[:user_id]
    assert_equal @su_admin_user.id, session[:original_user_id]
  end

  test "can login via test mechanism" do
    put :test_login, user_id: @ordinary_user.id
    assert_redirected_to '/'
    assert @ordinary_user.id, session[:user_id]
  end

end
