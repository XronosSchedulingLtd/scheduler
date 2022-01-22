require 'test_helper'

class SettingTest < ActiveSupport::TestCase

  setup do
    @setting = Setting.first
    assert @setting.valid?
  end

  test "should be a setting for busy text" do
    assert Setting.respond_to?(:busy_string)
  end

  test "default busy string should be \"Busy\"" do
    assert_equal "Busy", Setting.busy_string
  end

  test "tt_cycle_weeks must be numeric" do
    @setting.tt_cycle_weeks = "Banana"
    assert_not @setting.valid?
  end

  test "tt_cycle_weeks must be in range 1..2" do
    check_range(:tt_cycle_weeks, 1, 2)
  end

  test "first_tt_day must be in range 0..6" do
    #
    #  As we're going to test setting first_tt_day to 6, we need to
    #  make sure that last_tt_day is at least six, else it won't be
    #  valid when we expect it to be.
    #
    @setting.last_tt_day = 6
    check_range(:first_tt_day, 0, 6)
  end

  test "last_tt_day must be in range 0..6" do
    @setting.first_tt_day = 0
    check_range(:last_tt_day, 0, 6)
  end

  test "first_tt_day must be less than or equal to last_tt_day" do
    @setting.first_tt_day = 5
    @setting.last_tt_day = 4
    assert_not @setting.valid?
  end

  test "must have a current era" do
    @setting.current_era = nil
    assert_not @setting.valid?
  end

  test "must have a perpetual era" do
    @setting.perpetual_era = nil
    assert_not @setting.valid?
  end

  test "tt_default_days accepts strings" do
    @setting.ft_default_days = ["", "1", "2", "3"]
    assert_equal [1,2,3], @setting.ft_default_days
  end

  test "can have prep element" do
    property = FactoryBot.create(:property, name: "Prep")
    @setting.prep_property_element = property.element
    @setting.save
    assert @setting.valid?
    assert_equal property, @setting.prep_property_element.entity
  end

  test "can have maintenance element" do
    property = FactoryBot.create(:property, name: "Maintenance")
    @setting.maintenance_property_element = property.element
    @setting.save
    assert @setting.valid?
    assert_equal property, @setting.maintenance_property_element.entity
  end

  test "can get cached property element" do
    property = FactoryBot.create(:property, name: "Prep")
    @setting.prep_property_element = property.element
    @setting.save
    element = Setting.prep_property_element
    assert_equal property, element.entity
  end

  test "can get cached maintenance element" do
    property = FactoryBot.create(:property, name: "Maintenance")
    @setting.maintenance_property_element = property.element
    @setting.save
    element = Setting.maintenance_property_element
    assert_equal property, element.entity
  end

  test "can get prep property element name" do
    property = FactoryBot.create(:property, name: "Prep")
    @setting.prep_property_element = property.element
    @setting.save
    name = @setting.prep_property_element_name
    assert_equal property.name, name
  end

  test "can get maintenance property element name" do
    property = FactoryBot.create(:property, name: "Maintenance")
    @setting.maintenance_property_element = property.element
    @setting.save
    name = @setting.maintenance_property_element_name
    assert_equal property.name, name
  end

  private

  def check_range(field, min, max)
    @setting[field] = min
    assert @setting.valid?
    @setting[field] = min - 1
    assert_not @setting.valid?
    @setting[field] = max
    assert @setting.valid?
    @setting[field] = max + 1
    assert_not @setting.valid?
  end
end
