require 'test_helper'

class EventcategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  setup do
    @eventcategory = eventcategories(:one)
  end

  test "should require a name" do
    eventcategory = Eventcategory.new(:name => "", :pecking_order => 1)
    assert_not eventcategory.valid?
  end

  test "should require a unique name" do
    eventcategory = Eventcategory.new(:name => @eventcategory.name,
                                      :pecking_order => 1)
    assert_not eventcategory.valid?
  end

  test "should require a numeric pecking order" do
    eventcategory = Eventcategory.new(:name => "Banana", :pecking_order => "fred")
    assert_not eventcategory.valid?
  end

  test "should allow a valid event category" do
    eventcategory = Eventcategory.new(:name => "Banana", :pecking_order => 1)
    assert eventcategory.valid?
  end
end
