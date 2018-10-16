require 'test_helper'

class ResourcegroupTest < ActiveSupport::TestCase
  setup do
    @era1   = eras(:eraone)
  end

  test "we have two resource groups to start with" do
    count = Resourcegroup.count
    assert_equal 2, count
  end

  test "we can construct a new valid resource group" do
    rg = Resourcegroup.new({
      name:      "Able baker",
      starts_on: Date.today,
      era:       @era1
    })
    assert rg.valid?
  end

  test "we can create a new valid resource group" do
    assert_nothing_raised do
      rg = Resourcegroup.create!({
        name:      "Able baker",
        starts_on: Date.today,
        era:       @era1
      })
    end
  end

  test "element should have add_directly? set to true" do
    rg = Resourcegroup.create!({
      name:      "Able baker",
      starts_on: Date.today,
      era:       @era1
    })
    assert rg.element.add_directly?
  end

end
