require 'test_helper'

class ElementTest < ActiveSupport::TestCase

  test "should have a viewable flag" do
    element = FactoryBot.create(:element)
    assert element.respond_to?(:viewable?)
  end

end
