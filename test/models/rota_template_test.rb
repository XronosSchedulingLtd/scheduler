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

end
