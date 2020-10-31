require 'test_helper'

class MembershipsControllerTest < ActionController::TestCase

  setup do
    staff = FactoryBot.create(:staff, email: 'able@baker.com')
    user = FactoryBot.create(
      :user,
      email: 'able@baker.com',
      permissions_memberships: true
    )
    assert user.can_has_groups?
    session[:user_id] = user.id
    @source_group = FactoryBot.create(:group, owner: user)
    3.times do
      @source_group.add_member(FactoryBot.create(:staff))
    end
    @source_group.reload
    assert_equal 3, @source_group.members.count
    @spare_thing = FactoryBot.create(:property)
  end

  test "should get index" do
    get :index, params: { group_id: @source_group }
    assert_response :success
    assert_not_nil assigns(:memberships)
  end

  test "should get new" do
    get :new, params: { group_id: @source_group }
    assert_response :success
  end

  test "should create membership" do
    assert_difference('Membership.count') do
      post(
        :create,
        params: {
          group_id: @source_group,
          membership: {
            starts_on_text: Date.today.to_s(:dmy),
            element_id: @spare_thing.element,
            inverse: false
          }
        }
      )
    end
    assert_redirected_to group_memberships_path(@source_group)
  end

  test "should get edit" do
    get :edit, params: { id: @source_group.memberships[0] }
    assert_response :success
  end

  test "should update membership" do
    membership = @source_group.memberships[0]
    assert_equal 3, @source_group.members(Date.today).count
    patch(
      :update,
      params: {
        id: membership,
        membership: {
          starts_on_text: Date.tomorrow.to_s(:dmy)
        }
      }
    )
    assert_redirected_to group_memberships_path(@source_group)
    #
    #  Because we have moved one of the memberships to starting
    #  tomorrow, there should now be only 2 members today.
    #
    assert_equal 2, @source_group.members(Date.today).count
    membership.reload
    assert_equal Date.tomorrow, membership.starts_on
  end

  test "should destroy membership" do
    assert_difference('Membership.count', -1) do
      delete :destroy, params: { id: @source_group.memberships[0] }
    end

    assert_redirected_to group_memberships_path(@source_group)
  end

  test "date should display as ddmmyyyy" do
    today_dmy = Date.today.to_s(:dmy)
    get :edit, params: { id: @source_group.memberships[0] }
    assert_response :success
    assert_select '#membership_starts_on_text' do |fields|
      assert_equal 1, fields.count
      assert_equal today_dmy, fields.first['value']
    end
  end

  test "can update date with yyyymmdd" do
    #
    #  We already tried dd/mm/yyyy in the update test above.
    #
    membership = @source_group.memberships[0]
    assert_equal 3, @source_group.members(Date.today).count
    patch(
      :update,
      params: {
        id: membership,
        membership: {
          starts_on_text: Date.tomorrow.to_s(:ymd)
        }
      }
    )
    assert_redirected_to group_memberships_path(@source_group)
    #
    #  Because we have moved one of the memberships to starting
    #  tomorrow, there should now be only 2 members today.
    #
    assert_equal 2, @source_group.members(Date.today).count
    membership.reload
    assert_equal Date.tomorrow, membership.starts_on
  end

end
