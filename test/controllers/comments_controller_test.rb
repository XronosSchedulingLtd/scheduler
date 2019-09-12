require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  setup do
    UserProfile.ensure_basic_profiles
    @user_form_response = FactoryBot.create(:user_form_response)
    @ordinary_user = FactoryBot.create(:user)
    @admin_user    = FactoryBot.create(:user, :admin)
    @existing_comment = FactoryBot.create(:comment, parent: @user_form_response)
    #
    #  And now a whole heirarchy so we can test that the controller of a
    #  resource can add comments.
    #
    @resourcegroup = FactoryBot.create(:resourcegroup)
    @allocating_user = FactoryBot.create(:user)
    @concern = FactoryBot.create(:concern,
                                 user: @allocating_user,
                                 element: @resourcegroup.element,
                                 owns: true)
    @event = FactoryBot.create(:event)
    @resource_request = FactoryBot.create(:request,
                                 event: @event,
                                 element: @resourcegroup.element)
    @rg_user_form = FactoryBot.create(:user_form,
                                      elements: [@resourcegroup.element])
    @rg_ufr = FactoryBot.create(:user_form_response,
                                user_form: @rg_user_form,
                                parent: @resource_request,
                                status: :complete)
  end

  test 'should create a comment' do
    session[:user_id] = @admin_user.id
    request.env['HTTP_REFERER'] = user_form_response_path(@user_form_response)
    assert_difference('Comment.count') do
      post :create,
        user_form_response_id: @user_form_response.id,
        user_id: @admin_user.id,
        comment: {
          body: "Hello there - I'm a comment!"
        }
    end

    assert_redirected_to user_form_response_path(@user_form_response)
  end

  test 'should destroy a comment' do
    session[:user_id] = @admin_user.id
    request.env['HTTP_REFERER'] = user_form_response_path(@user_form_response)
    assert_difference('Comment.count', -1) do
      delete :destroy, id: @existing_comment
    end

    assert_redirected_to user_form_response_path(@user_form_response)
  end

  test 'ordinary user cannot create' do
    session[:user_id] = @ordinary_user.id
    request.env['HTTP_REFERER'] = user_form_response_path(@user_form_response)
    assert_no_difference('Comment.count') do
      post :create,
        user_form_response_id: @user_form_response.id,
        user_id: @ordinary_user.id,
        comment: {
          body: "Hello there - I'm a comment!"
        }
    end

    assert_redirected_to root_path
  end

  test 'ordinary user cannot create a comment' do
    session[:user_id] = @ordinary_user.id
    assert_no_difference('Comment.count') do
      delete :destroy, id: @existing_comment
    end

    assert_redirected_to root_path
  end

  test 'allocating user can create a comment' do
    session[:user_id] = @allocating_user.id
    request.env['HTTP_REFERER'] = user_form_response_path(@rg_ufr)
    assert @allocating_user.owns?(@resourcegroup.element)
    assert_difference('Comment.count') do
      post :create,
        user_form_response_id: @rg_ufr.id,
        user_id: @allocating_user.id,
        comment: {
          body: "Hello there - I'm a comment!"
        }
    end

    assert_redirected_to user_form_response_path(@rg_ufr)
  end

  test 'owning user can delete a comment' do
    comment = Comment.create({
      parent: @user_form_response,
      user:   @ordinary_user,
      body:   'A sacrificial comment'
    })
    assert comment.valid?

    #
    #  And now delete it as our ordinary user, via the controller.
    #
    session[:user_id] = @ordinary_user.id
    request.env['HTTP_REFERER'] = user_form_response_path(@user_form_response)
    assert_difference('Comment.count', -1) do
      delete :destroy, id: comment
    end

    assert_redirected_to user_form_response_path(@user_form_response)
  end

end
