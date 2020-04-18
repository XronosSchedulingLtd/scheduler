require 'test_helper'

class ExamCycleTest < ActiveSupport::TestCase

  setup do
    @default_rota_template = FactoryBot.create(:rota_template)
    default_group = FactoryBot.create(:group)
    @default_group_element = default_group.element
    selector_property = FactoryBot.create(:property)
    @selector_element = selector_property.element
    @valid_params = {
      name: "An exam cycle",
      starts_on: Date.today,
      ends_on: Date.tomorrow,
      default_rota_template: @default_rota_template,
      default_group_element: @default_group_element
    }
    ec = FactoryBot.create(:exam_cycle)
  end

  test "can create valid exam cycle" do
    ec = ExamCycle.create(@valid_params)
    assert ec.valid?
    assert_equal ec, @default_group_element.exam_cycles_as_default_group.first
  end

  test "name is required" do
    ec = ExamCycle.create(@valid_params.except(:name))
    assert_not ec.valid?
  end

  test "starts_on is required" do
    ec = ExamCycle.create(@valid_params.except(:starts_on))
    assert_not ec.valid?
  end

  test "ends_on is required" do
    ec = ExamCycle.create(@valid_params.except(:ends_on))
    assert_not ec.valid?
  end

  test "default group element is required" do
    ec = ExamCycle.create(@valid_params.except(:default_group_element))
    assert_not ec.valid?
  end

  test "can specify a selector element" do
    ec =
      ExamCycle.create(
        @valid_params.merge(
          {
            selector_element: @selector_element
          }
        )
      )
    assert ec.valid?
    assert_equal @selector_element, ec.selector_element
    #
    #  This next one is really just testing that the link works both
    #  ways.  We know our exam cycle will be the first because we
    #  only just created the element.
    #
    assert_equal ec, @selector_element.exam_cycles_as_selector.first
  end

end
