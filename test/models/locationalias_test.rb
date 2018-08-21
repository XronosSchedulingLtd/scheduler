require 'test_helper'

class LocationaliasTest < ActiveSupport::TestCase

  setup do
    @location1   = locations(:roomone)
    @la1         = locationaliases(:one)
  end

  test "should require a name" do
    locationalias = Locationalias.new(name: "", location: @location1)
    assert_not locationalias.valid?
  end

  test "should allow a valid locationalias" do
    locationalias = Locationalias.new(name: "Banana", location: @location1)
    assert locationalias.valid?
  end

  test "creating display locationalias should modify name" do
    org_name = @location1.element.name
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    assert_not_equal org_name, @location1.element.name
  end

  test "creating non-display locationalias should not modify name" do
    org_name = @location1.element.name
    locationalias = Locationalias.create(name: "Banana",
                                         display: false,
                                         location: @location1)
    assert_equal org_name, @location1.element.name
  end

  test "modifying alias should modify name" do
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    org_name = @location1.element.name
    locationalias.name = "Fritter"
    locationalias.save
    assert_not_equal org_name, @location1.element.name
  end

  test "deleting alias should modify name" do
    locationalias = Locationalias.create(name: "Banana",
                                         display: true,
                                         location: @location1)
    org_name = @location1.element.name
    locationalias.destroy
    assert_not_equal org_name, @location1.element.name
  end

end
