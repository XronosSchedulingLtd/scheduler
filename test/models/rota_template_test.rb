require 'test_helper'

class RotaTemplateTest < ActiveSupport::TestCase
  setup do
    @rtt = FactoryBot.create(:rota_template_type)
    @valid_attributes = {
      name: "Able baker",
      rota_template_type: @rtt
    }
  end

  test "can create valid rota template" do
    rt = RotaTemplate.create(@valid_attributes)
    assert rt.valid?
  end

  test "name is required" do
    rt = RotaTemplate.create(@valid_attributes.except(:name))
    assert_not rt.valid?
  end

  test "rota template type is required" do
    rt = RotaTemplate.create(@valid_attributes.except(:rota_template_type))
    assert_not rt.valid?
  end

  test "factory creates rota template with slots" do
    rt = FactoryBot.create(:rota_template)
    #
    #  I'd like to ask FactoryBot how many it thinks it is creating,
    #  but I've yet to find a way of doing that.
    #
    assert_equal 12, rt.rota_slots.count
  end

  test "but can do it without" do
    rt = FactoryBot.create(:rota_template, :no_slots)
    assert_equal 0, rt.rota_slots.count
  end

  test "or provide custom slots" do
    rt = FactoryBot.create(
      :rota_template,
      slots: [
        ["11:10", "11:30"],
        ["11:30", "12:20"],
        ["12:25", "13:15"]
      ])
    assert_equal 3, rt.rota_slots.count
  end

end
