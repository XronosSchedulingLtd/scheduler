require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    @user_form_response = FactoryBot.create(:user_form_response)
    @user = FactoryBot.create(:user)
    @valid_params = {
      parent: @user_form_response,
      user:   @user,
      body:   "Hello there - I'm a comment"
    }
  end

  test "can create comment with hand-crafted ufr" do
    user_form = FactoryBot.create(:user_form)
    commitment = FactoryBot.create(:commitment)
    ufr_valid_params = {
      user_form: user_form,
      parent:    commitment
    }
    ufr = UserFormResponse.create(ufr_valid_params)
    puts "ufr id = #{ufr.id}"
    assert ufr.valid?
    comment = Comment.new(@valid_params.merge({parent: ufr}))
    comment.valid?
    puts comment.inspect
    puts comment.errors.inspect
    assert comment.valid?, "Testing comment valid"
  end



  test "can create comment with valid params" do
    assert @user_form_response.valid?, "Testing user_form_response valid"
    comment = Comment.create(@valid_params)
    comment.valid?
    puts comment.errors.inspect
    assert comment.valid?, "Testing comment valid"
  end
end

