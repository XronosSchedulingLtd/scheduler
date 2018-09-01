require 'test_helper'

class PropertyTest < ActiveSupport::TestCase
  test "creating a property should create an element" do
    property = Property.create(name: "Google")
    assert_not_nil property.element
  end

end
