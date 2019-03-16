require 'test_helper'

class UserFormTest < ActiveSupport::TestCase
  test 'user form must have a name' do
    user_form = UserForm.new
    assert_not user_form.valid?
    user_form = UserForm.new({
      name: "Banana"
    })
    assert user_form.valid?
  end
end
