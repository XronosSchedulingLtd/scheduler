require 'test_helper'

class ProtoEventTest < ActiveSupport::TestCase
  setup do
    @eventsource = Eventsource.find_by(name: "RotaSlot")
    @eventcategory = Eventcategory.cached_category("Invigilation")
    @rota_template = FactoryBot.create(:rota_template)
    @exam_cycle    = FactoryBot.create(:exam_cycle,
                                       default_rota_template: @rota_template)
    @location      = FactoryBot.create(:location)
    @valid_params = {
      body:          "A proto event",
      eventcategory: @eventcategory,
      eventsource:   @eventsource,
      rota_template: @rota_template,
      generator:     @exam_cycle,
      starts_on:     Date.today,
      ends_on:       Date.tomorrow,
      num_staff:     "1",
      location_id:   @location.element.id
    }
    selector = FactoryBot.create(:property)
    @selector_element = selector.element
    @event1 =
      FactoryBot.create(
        :event,
        starts_at: Tod::TimeOfDay.parse("13:30").on(Date.today),
        ends_at: Tod::TimeOfDay.parse("16:00").on(Date.today),
        commitments_to: [selector, @location])
  end

  test "have source and category" do
    assert_not_nil @eventsource
    assert_not_nil @eventcategory
  end

  test "can create valid proto event" do
    pe = ProtoEvent.create(@valid_params)
    assert pe.valid?
  end

  test "auto-generates a body" do
    pe = ProtoEvent.create(@valid_params.except(:body))
    assert pe.valid?
    assert_not pe.body.blank?
  end

  test "needs a rota template" do
    pe = ProtoEvent.create(@valid_params.except(:rota_template))
    assert_not pe.valid?
  end

  test "needs a starts_on" do
    pe = ProtoEvent.create(@valid_params.except(:starts_on))
    assert_not pe.valid?
  end

  test "needs an ends_on" do
    pe = ProtoEvent.create(@valid_params.except(:ends_on))
    assert_not pe.valid?
  end

  test "needs a location" do
    pe = ProtoEvent.create(@valid_params.except(:location_id))
    assert_not pe.valid?
  end

  test "needs num_staff" do
    pe = ProtoEvent.create(@valid_params.except(:num_staff))
    assert_not pe.valid?
  end

  test "num_staff must be non-negative" do
    pe = ProtoEvent.create(@valid_params.merge(num_staff: "-1"))
    assert_not pe.valid?
  end

  test "must have an eventcategory" do
    pe = ProtoEvent.create(@valid_params.except(:eventcategory))
    assert_not pe.valid?
  end
    
  test "must have an eventsource" do
    pe = ProtoEvent.create(@valid_params.except(:eventsource))
    assert_not pe.valid?
  end
    
  test "needs a generator" do
    #
    #  This one actually raises an exception because it doesn't know
    #  how to create it without knowing what the generator is.
    #
    assert_raise(Exception) {
      ProtoEvent.create(@valid_params.except(:generator))
    }
  end

  test "dates can't be backward" do
    pe = ProtoEvent.create(@valid_params.merge(ends_on: Date.yesterday))
    assert_not pe.valid?
  end

  test "can create events" do
    pe = ProtoEvent.create(@valid_params)
    pe.ensure_required_events
    #
    #  The standard rota template has 12 slots * 2 days
    #
    assert_equal 24, pe.events.count
  end

  test "having a selector element reduces the events" do
    exam_cycle = FactoryBot.create(:exam_cycle,
                                   default_rota_template: @rota_template,
                                   selector_element: @selector_element)
    pe = ProtoEvent.create(@valid_params.merge(generator: exam_cycle))
    pe.ensure_required_events
    assert_equal 4, pe.events.count
  end
end
