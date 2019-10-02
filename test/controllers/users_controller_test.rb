require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @ordinary_user = FactoryBot.create(:user, user_profile: UserProfile.staff_profile)
    @admin_user = FactoryBot.create(:user, :admin, user_profile: UserProfile.staff_profile)
    @su_user = FactoryBot.create(:user, :admin, :su, user_profile: UserProfile.staff_profile)
  end

  test "ordinary user cannot list users" do
    session[:user_id] = @ordinary_user.id
    get :index
    assert_redirected_to '/'
  end

  test "admin user can list users" do
    session[:user_id] = @admin_user.id
    get :index
    assert_response :success
    assert_select 'h1', 'Listing users'
    assert_select 'table.zftable' do
      assert_select 'tbody' do
        #
        #  This will fail if we create so many that it paginates.
        #
        assert_select 'tr', User.count
      end
    end
  end

  test "ordinary admin cannot su" do
    session[:user_id] = @admin_user.id
    get :index
    assert_response :success
    assert_select 'h1', 'Listing users'
    assert_select 'table.zftable' do
      assert_select 'tbody' do
        assert_select 'a' do |elements|
          assert_equal 0, elements.select {|e| e.text == 'su'}.count
        end
      end
    end
  end

  test "special admin can su" do
    session[:user_id] = @su_user.id
    get :index
    assert_response :success
    assert_select 'h1', 'Listing users'
    assert_select 'table.zftable' do
      assert_select 'tbody' do
        assert_select 'a' do |elements|
          #
          #  Cannot su to onesself
          #
          assert_equal User.count - 1, elements.select {|e| e.text == 'su'}.count
        end
      end
    end
  end

end
