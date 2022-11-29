#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2022 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PreferredColourTest < ActiveSupport::TestCase
  setup do
    @default_result = true
    @lesson_category   = Eventcategory.find_by(name: "Lesson")
    @an_event = FactoryBot.create(
      :event,
      body: "An event",
      starts_at: Time.zone.parse("2020-03-31 12:00"),
      ends_at: Time.zone.parse("2020-03-31 12:30"),
      eventcategory: @lesson_category)
    @colouring_property_params = {
      name: "Colouring property",
      edit_preferred_colour: "#abcdef",
      force_colour: true,
      force_weight: 10
    }
    @colouring_property =
      FactoryBot.create(:property, @colouring_property_params)
    @stronger_colouring_property = FactoryBot.create(
      :property,
      name: "Stronger colouring property",
      edit_preferred_colour: "#fedcba",
      force_colour: true,
      force_weight: 20
    )
    @inert_colouring_property = FactoryBot.create(
      :property,
      name: "Inert colouring property",
      edit_preferred_colour: "#ababab",
      force_colour: false,
      force_weight: 15
    )
  end

  test "creating a property transfers parameters to element" do
    assert @colouring_property.element.force_colour
    assert_equal @colouring_property_params[:edit_preferred_colour],
      @colouring_property.element.preferred_colour
    assert_equal @colouring_property_params[:force_weight],
      @colouring_property.element.force_weight
  end

  test "adding and removing commitment of suitable property changes colour of event" do
    assert_nil @an_event.preferred_colours.current
    commitment = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_equal @colouring_property.element.id,
      @an_event.preferred_colours[0].sponsor
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours[0].colour
    assert_equal @colouring_property.force_weight,
      @an_event.preferred_colours[0].weight
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    commitment.destroy
    @an_event.reload
    assert_nil @an_event.preferred_colours.current
    assert_equal 0, @an_event.preferred_colours.size
  end

  test "adding or removing stronger colouring property changes colour of event" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    commitment2 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @stronger_colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    commitment2.destroy
    @an_event.reload
    assert_equal @colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
  end

  test "adding or removing weaker colouring property has no effect" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @stronger_colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    commitment2 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    commitment2.destroy
    @an_event.reload
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
  end

  test "setting or removing force flag amends existing linked events" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @inert_colouring_property.element)
    assert_nil @an_event.preferred_colours.current
    @inert_colouring_property.force_colour = true
    @inert_colouring_property.save
    assert @inert_colouring_property.element.force_colour
    @an_event.reload
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @inert_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    @inert_colouring_property.force_colour = false
    @inert_colouring_property.save
    assert_not @inert_colouring_property.element.force_colour
    @an_event.reload
    assert_nil @an_event.preferred_colours.current
  end

  test "amending preferred colour amends existing linked events" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours.current
    @colouring_property.edit_preferred_colour = "blue"
    @colouring_property.save
    @an_event.reload
    assert_not_nil @an_event.preferred_colours.current
    assert_equal "blue", @colouring_property.element.preferred_colour
    assert_equal "blue",  @an_event.preferred_colours.current
  end

  test "amending weight of preference amends existing linked events" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours.current
    commitment2 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @stronger_colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    @colouring_property.force_weight = 30
    @colouring_property.save
    @an_event.reload
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours.current
  end

  test "deleting a colour property removes colour effects" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours.current
    @colouring_property.destroy
    @an_event.reload
    assert_nil @an_event.preferred_colours.current
  end

  test "deleting a stronger colour property reverts colour effects" do
    assert_nil @an_event.preferred_colours.current
    commitment1 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @colouring_property.edit_preferred_colour,
      @an_event.preferred_colours.current
    commitment2 = FactoryBot.create(
      :commitment,
      event: @an_event,
      element: @stronger_colouring_property.element)
    assert_not_nil @an_event.preferred_colours.current
    assert_equal @stronger_colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
    @stronger_colouring_property.destroy
    @an_event.reload
    assert_equal @colouring_property.element.preferred_colour,
      @an_event.preferred_colours.current
  end

end

