require 'test_helper'

class VanillagroupTest < ActiveSupport::TestCase
  setup do
    @era1   = eras(:eraone)
  end

  test "we have two vanilla groups to start with" do
    count = Vanillagroup.count
    assert_equal 2, count
  end

  test "we can construct a new valid vanilla group" do
    vg = Vanillagroup.new({
      name:      "Able baker",
      starts_on: Date.today,
      era:       @era1
    })
    assert vg.valid?
  end

  test "we can create a new valid vanilla group" do
    assert_nothing_raised do
      vg = Vanillagroup.create!({
        name:      "Able baker",
        starts_on: Date.today,
        era:       @era1
      })
    end
  end

  test "element should have add_directly? set to true" do
    rg = Vanillagroup.create!({
      name:      "Able baker",
      starts_on: Date.today,
      era:       @era1
    })
    assert rg.element.add_directly?
  end

end
