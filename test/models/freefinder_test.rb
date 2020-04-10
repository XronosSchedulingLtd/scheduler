#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

require 'csv'

class FreefinderTest < ActiveSupport::TestCase
  setup do
    @minimal_valid_params = {}
    @group = FactoryBot.create(:group)
    @property = FactoryBot.create(:property)
    @staff1 = FactoryBot.create(:staff)
    @staff2 = FactoryBot.create(:staff)
    @staff3 = FactoryBot.create(:staff)
    @staff4 = FactoryBot.create(:staff)
    @user = FactoryBot.create(:user)
    @group.add_member(@staff1)
    @group.add_member(@staff2)
    @group.add_member(@staff3)
    @group.add_member(@staff4)
    @full_valid_params = {
      element: @group.element,
      start_time_text: "12:30",
      end_time_text: "15:00",
      on: Date.today
    }
    #
    #  Now give staff2 and staff 4 clashing commitments.
    #
    today = Date.today.to_s(:dmy)
    @event1 = FactoryBot.create(
      :event,
      starts_at: "#{today} 12:00",
      ends_at: "#{today} 13:00",
      commitments_to: [@staff2]
    )
    @event2 = FactoryBot.create(
      :event,
      starts_at: "#{today} 14:00",
      ends_at: "#{today} 14:30",
      commitments_to: [@staff4]
    )
  end

  test 'can create a free finder' do
    ff = Freefinder.new(@minimal_valid_params)
    assert ff.valid?
  end

  test 'can specify a group element' do
    ff = Freefinder.new(@minimal_valid_params.merge({element: @group.element}))
    assert ff.valid?
  end

  test 'element must be a group element' do
    ff = Freefinder.new(@full_valid_params.merge({element: @property.element}))
    assert ff.valid?
    ff.do_find
    assert_not ff.errors.empty?
    assert_not ff.done_search
  end

  test 'can create with full details' do
    ff = Freefinder.new(@full_valid_params)
    assert ff.valid?
  end

  test 'produces start and end times in correct format' do
    ff = Freefinder.new(@full_valid_params)
    assert_equal "12:30", ff.start_time_text
    assert_equal "15:00", ff.end_time_text
  end

  test 'produces element name' do
    ff = Freefinder.new(@full_valid_params)
    assert_equal @group.element.name, ff.element_name
    assert_equal @group.element.id, ff.element_id
  end

  test 'produces on text' do
    ff = Freefinder.new(@full_valid_params)
    today = Date.today
    assert_equal(
      today.strftime("%a #{today.day.ordinalize} %B, %Y"),
      ff.on_text)
  end

  test 'can find free staff' do
    ff = Freefinder.new(@full_valid_params)
    assert ff.valid?
    ff.do_find
    assert ff.errors.empty?
    assert ff.done_search
    assert_equal 2, ff.free_elements.size
  end

  test 'can produce csv' do
    ff = Freefinder.new(@full_valid_params)
    ff.do_find
    output = CSV.parse(ff.to_csv)
    #
    #  Expect 4 lines of output.
    #
    assert_equal 4, output.size
    assert_equal(
      "On #{ff.on_text} between #{ff.start_time_text} and #{ff.end_time_text}",
      output[1][0])
    assert_equal @staff1.short_name, output[2][0]
    assert_equal @staff3.short_name, output[3][0]
  end

  test 'can create new group' do
    ff = Freefinder.new(@full_valid_params)
    ff.do_find
    group = ff.create_group(@user)
    assert group.valid?
    members = group.members
    assert members.include?(@staff1)
    assert members.include?(@staff3)
    assert_not members.include?(@staff2)
    assert_not members.include?(@staff4)

  end
end
