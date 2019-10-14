require 'test_helper'

class RequestsControllerTest < ActionController::TestCase
  setup do
    @organiser_staff =
      FactoryBot.create(:staff, email: 'staff@myschool.org.uk')
    @organiser_user =
      FactoryBot.create(:user, email: 'staff@myschool.org.uk')
    @owning_staff =
      FactoryBot.create(:staff, email: 'owner@myschool.org.uk')
    @owning_user    =
      FactoryBot.create(:user, email: 'owner@myschool.org.uk')
    @other_staff =
      FactoryBot.create(:staff, email: 'other@myschool.org.uk')
    @other_user    =
      FactoryBot.create(:user, email: 'other@myschool.org.uk')
    @resourcegroup = FactoryBot.create(:resourcegroup)
    @allocating_user = FactoryBot.create(:user)
    @concern = FactoryBot.create(:concern,
                                 user: @allocating_user,
                                 element: @resourcegroup.element,
                                 owns: true)
    @event = FactoryBot.create(:event,
                               owner: @owning_user,
                               organiser: @organiser_staff.element)
    @resource_request = FactoryBot.create(:request,
                                 event: @event,
                                 element: @resourcegroup.element)
  end

  #
  #  A response of OK means it was a reasonable request, although
  #  it may not have been carried out.
  #  302 means you don't have per.
  #
  test 'event owner can increment request' do
    session[:user_id] = @owning_user.id
    put :increment, id: @resource_request.id, format: :js
    assert_response :ok
    @resource_request.reload
    assert_equal 2, @resource_request.quantity
  end

  test 'event owner can decrement request' do
    @resource_request.quantity = 2
    @resource_request.save!
    session[:user_id] = @owning_user.id
    put :decrement, id: @resource_request.id, format: :js
    assert_response :ok
    @resource_request.reload
    assert_equal 1, @resource_request.quantity
  end

  test 'but not below 1' do
    @resource_request.save!
    session[:user_id] = @owning_user.id
    put :decrement, id: @resource_request.id, format: :js
    assert_response :ok
    @resource_request.reload
    assert_equal 1, @resource_request.quantity
  end

  test 'organiser can increment request' do
    session[:user_id] = @organiser_user.id
    put :increment, id: @resource_request.id, format: :js
    assert_response :ok
    @resource_request.reload
    assert_equal 2, @resource_request.quantity
  end

  test 'but other user cannot' do
    session[:user_id] = @other_user.id
    put :increment, id: @resource_request.id, format: :js
    assert_response 302
    @resource_request.reload
    assert_equal 1, @resource_request.quantity
  end

end
