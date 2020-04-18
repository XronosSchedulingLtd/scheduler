#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ItemreportTest < ActiveSupport::TestCase
  setup do
    @concern = FactoryBot.create(:concern)
    @valid_params = {
      concern: @concern
    }
    @element = FactoryBot.create(:element)
    @extra_params = {
      compact:          true,
      duration:         true,
      mark_end:         true,
      locations:        true,
      staff:            true,
      pupils:           true,
      periods:          true,
      twelve_hour:      true,
      end_time:         false,
      breaks:           true,
      suppress_empties: true,
      tentative:        true,
      firm:             true,
      categories:       "Able, Baker",
      notes:            true,
      no_space:         true,
      enddot:           false
    }
  end

  test 'can create an item report' do
    ir = Itemreport.new(@valid_params)
    assert ir.valid?
  end

  test 'concern is required' do
    ir = Itemreport.new(@valid_params.except(:concern))
    assert_not ir.valid?
  end

  test 'can have an excluded element' do
    ir = Itemreport.new(@valid_params.merge({excluded_element: @element}))
    assert ir.valid?
  end

  test 'can specify a full set of parameters' do
    ir = Itemreport.new(@valid_params.merge(@extra_params))
    assert ir.valid?
    @extra_params.each do |key, value|
      assert_equal value, ir.send(key)
    end
  end

  test 'can construct a basic url' do
    ir = Itemreport.new(@valid_params)
    assert_equal "/item/#{@concern.element_id}/days", ir.url
  end

  test 'can construct a really long url' do
    ir = Itemreport.new(@valid_params.merge(@extra_params))
    assert_equal "/item/#{@concern.element_id}/days?compact&duration&mark_end&locations&staff&pupils&periods&twelve_hour&no_space&no_end_time&breaks&suppress_empties&no_dot&tentative&firm&categories=Able,Baker", ir.url
  end

  test 'can construct a basic url for csv' do
    ir = Itemreport.new(@valid_params)
    ir.note_type("csv")
    assert_equal "/item/#{@concern.element_id}/days.csv", ir.url
  end

  test 'can construct a basic url for doc' do
    ir = Itemreport.new(@valid_params)
    ir.note_type("doc")
    assert_equal "/item/#{@concern.element_id}/days.doc", ir.url
  end

end
