require 'test_helper'

class ResourcegroupTest < ActiveSupport::TestCase
  setup do
    @era1   = eras(:eraone)
    @valid_params = {
      name:      "Able baker",
      starts_on: Date.today,
      era:       @era1
    }
  end

  test "we have two resource groups to start with" do
    count = Resourcegroup.count
    assert_equal 2, count
  end

  test "we can construct a new valid resource group" do
    rg = Resourcegroup.new(@valid_params)
    assert rg.valid?
  end

  test "we can create a new valid resource group" do
    assert_nothing_raised do
      rg = Resourcegroup.create!(@valid_params)
    end
  end

  test "element should have add_directly? set to true" do
    rg = Resourcegroup.create!(@valid_params)
    assert rg.element.add_directly?
  end

end
