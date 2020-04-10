require 'test_helper'

class UserFormTest < ActiveSupport::TestCase
  setup do
    @valid_params = {
      name: "Banana"
    }
    @user = FactoryBot.create(:user)
    @commitment = FactoryBot.create(:commitment)
    @valid_ufr_params = {
      parent:    @commitment
    }
    @service1 = FactoryBot.create(:service)
    @service2 = FactoryBot.create(:service)
  end

  test 'can create valid user form' do
    user_form = UserForm.new(@valid_params)
    assert user_form.valid?
  end

  test 'user form must have a name' do
    user_form = UserForm.new(@valid_params.except(:name))
    assert_not user_form.valid?
  end

  test 'can have a created by user' do
    user_form = UserForm.new(
      @valid_params.merge({
        created_by_user: @user
      }))
    assert user_form.valid?
  end

  test 'can have a edited by user' do
    user_form = UserForm.new(
      @valid_params.merge({
        edited_by_user: @user
      }))
    assert user_form.valid?
  end

  test 'can have user form responses' do
    user_form = UserForm.new(@valid_params)
    ufr = user_form.user_form_responses.new(@valid_ufr_params)
    assert ufr.valid?
  end

  test 'can have several form responses' do
    user_form = UserForm.create(@valid_params)
    ufr1 = user_form.user_form_responses.create(@valid_ufr_params)
    assert ufr1.valid?
    ufr2 = user_form.user_form_responses.create(@valid_ufr_params)
    assert ufr2.valid?
    assert_equal 2, user_form.user_form_responses.count
  end

  test 'destroying user form destroys linked responses' do
    user_form = UserForm.create(@valid_params)
    ufr1 = user_form.user_form_responses.create(@valid_ufr_params)
    ufr2 = user_form.user_form_responses.create(@valid_ufr_params)
    user_form.destroy
    assert ufr1.destroyed?
    assert ufr2.destroyed?
  end

  test 'can be linked to elements' do
    user_form = UserForm.create(@valid_params)
    user_form.elements << @service1.element
    user_form.elements << @service2.element
    assert_equal 2, user_form.elements.count
    assert_equal "#{@service1.element.name},#{@service2.element.name}",
      user_form.resource_name
  end

  test 'destroying user form unlinks elements' do
    user_form = UserForm.create(@valid_params)
    user_form.elements << @service1.element
    user_form.elements << @service2.element
    assert_not_nil @service1.element.user_form
    assert_not_nil @service2.element.user_form
    user_form.destroy
    @service1.reload
    @service2.reload
    assert_nil @service1.element.user_form
    assert_nil @service2.element.user_form
  end

  test 'linked responses mark form as not to be destroyed' do
    user_form = UserForm.create(@valid_params)
    assert user_form.can_destroy?
    ufr = user_form.user_form_responses.create(@valid_ufr_params)
    assert_not user_form.can_destroy?
  end

end
