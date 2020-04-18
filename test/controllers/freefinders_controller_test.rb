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
