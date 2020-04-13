#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class RotaTemplateTypeTest < ActiveSupport::TestCase

  test "can create a valid rota template type" do
    rtt = RotaTemplateType.new(
      attributes_for(:rota_template_type)
    )
    assert rtt.valid?
  end

  test "rota template type must have a name" do
    rtt = RotaTemplateType.new(
      attributes_for(:rota_template_type).except(:name)
    )
    assert_not rtt.valid?
  end

  test "can create the basic types" do
    RotaTemplateType.create_basics
    invigilation_rtt = RotaTemplateType.find_by(name: "Invigilation")
    assert_not_nil invigilation_rtt
    day_shape_rtt = RotaTemplateType.find_by(name: "Day shape")
    assert_not_nil day_shape_rtt
  end
end

