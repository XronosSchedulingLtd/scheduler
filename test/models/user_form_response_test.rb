require 'test_helper'

class UserFormResponseTest < ActiveSupport::TestCase

  setup do
    @user_form = FactoryBot.create(:user_form)
    @commitment = FactoryBot.create(:commitment)
    @valid_params = {
      user_form: @user_form,
      parent:    @commitment
    }
  end

  test 'can create a valid user form' do
    user_form_response = UserFormResponse.new(@valid_params)
    assert user_form_response.valid?
  end

  test 'user form response must be linked to a user form' do
    user_form_response =
      UserFormResponse.new(@valid_params.except(:user_form))
    assert_not user_form_response.valid?
  end

  test 'user form response must have a parent' do
    user_form_response =
      UserFormResponse.new(@valid_params.except(:parent))
    assert_not user_form_response.valid?
  end

  test 'deleting a user form should delete attached responses' do
    temp_user_form = FactoryBot.create(:user_form)
    user_form_response = UserFormResponse.create(
      @valid_params.merge({user_form: temp_user_form}))
    assert user_form_response.valid?
    saved_id = user_form_response.id
    assert UserFormResponse.find_by(id: saved_id)
    temp_user_form.destroy
    assert_nil UserFormResponse.find_by(id: saved_id)
  end

end
