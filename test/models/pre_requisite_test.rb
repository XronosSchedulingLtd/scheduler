#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PreRequisiteTest < ActiveSupport::TestCase
  setup do
    @element = FactoryBot.create(:element)
    @valid_params = {
      element: @element
    }
  end

  test "can create pre-requisite" do
    pr = PreRequisite.new(@valid_params)
    assert pr.valid?
  end

  test "must have an element" do
    pr = PreRequisite.new(@valid_params.except(:element))
    assert_not pr.valid?
  end

  test "default values for flags" do
    pr = PreRequisite.new(@valid_params)
    assert pr.pre_creation?
    assert pr.quick_button?
  end

  test "provides css class" do
    pr = PreRequisite.new(@valid_params)
    assert_equal " qb-#{@element.entity_type.downcase}", pr.entity_type_class
  end

  test "provides label text" do
    pr = PreRequisite.new(@valid_params)
    assert_equal @element.short_name, pr.label_text
  end

  test "provides field id" do
    pr = PreRequisite.new(@valid_params)
    assert_equal "element-#{@element.id}", pr.field_id
  end

  test "provides element name" do
    pr = PreRequisite.new(@valid_params)
    assert_equal @element.name, pr.element_name
  end

  test "accepts and ignores element name" do
    pr = PreRequisite.new(@valid_params)
    old_name = pr.element_name
    assert_nothing_raised do
      pr.element_name = "Banana"
    end
    assert_equal old_name, pr.element_name
  end

end
