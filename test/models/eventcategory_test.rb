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

  test "should have a confidential flag" do
    ec = FactoryBot.create(:eventcategory)
    assert ec.respond_to?(:confidential?)
  end

  test "confidential should default to false" do
    ec = FactoryBot.create(:eventcategory)
    assert_not ec.confidential?
  end

  test "modifying confidential flag should modify dependent events" do
    ec = FactoryBot.create(:eventcategory)
    assert_not ec.confidential?
    event = FactoryBot.create(:event, eventcategory: ec)
    assert_not event.confidential?
    ec.confidential = true
    ec.save!
    event.reload
    assert event.confidential?
    ec.confidential = false
    ec.save!
    event.reload
    assert_not event.confidential?
  end

end
