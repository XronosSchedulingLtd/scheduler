require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    UserProfile.ensure_basic_profiles
    @user_form_response = FactoryBot.create(:user_form_response)
    @user = FactoryBot.create(:user)
    @valid_params = {
      parent: @user_form_response,
      user:   @user,
      body:   "Hello there - I'm a comment"
    }
  end

  test "can create comment with valid params" do
    comment = Comment.create(@valid_params)
    assert comment.valid?, "Testing comment valid"
  end

  test "comment requires user" do
    comment = Comment.create(@valid_params.merge(user: nil))
    assert_not comment.valid?
  end

  test "comment requires body" do
    comment = Comment.create(@valid_params.merge(body: nil))
    assert_not comment.valid?
  end

  test "comment requires parent" do
    comment = Comment.create(@valid_params.merge(parent: nil))
    assert_not comment.valid?
  end

end

