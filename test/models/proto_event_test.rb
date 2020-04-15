require 'test_helper'

class ProtoEventTest < ActiveSupport::TestCase
  setup do
    @eventsource = Eventsource.find_by(name: "RotaSlot")
    @eventcategory = Eventcategory.cached_category("Invigilation")
    @rota_template = FactoryBot.create(:rota_template)
    @exam_cycle    = FactoryBot.create(:exam_cycle,
                                       default_rota_template: @rota_template)
    @location      = FactoryBot.create(:location)
    @today         = Date.today
    @tomorrow      = Date.tomorrow
    @valid_params = {
      body:          "A proto event",
      eventcategory: @eventcategory,
      eventsource:   @eventsource,
      rota_template: @rota_template,
      generator:     @exam_cycle,
      starts_on:     @today,
      ends_on:       @tomorrow,
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

  #
  #  ProtoEvents involve a bit of meta-programming.  They mix in
  #  a module of code to suit the type of ProtoEvent required.  Currently
  #  there is only one type of persona - for Invigilation purposes - but
  #  there could in the future be more.
  #
  #  Catching all ways of creating a ProtoEvent record (or rather, of
  #  getting one into memory) and making sure each gets its persona
  #  at the right time is quite tricky and we need to make sure all the
  #  possible routes work.  Possibilities are:
  #
  #  * ActiveRecord Create or New with all params
  #  * ActiveRecord New, then add params later, including generator
  #  * ActiveRecord New, then add params later, including persona name
  #  * FactoryBot Create (creates, then adds params)
  #  * Create in context of generator (generator is never assigned to)
  #  * Load from disk
  #
  test "can create valid proto event" do
    pe = ProtoEvent.create(@valid_params)
    assert pe.valid?
  end

  test 'can use new, then add values later' do
    pe = ProtoEvent.new
    assert_not pe.valid?
    assert_not pe.has_persona?
    pe.assign_attributes(@valid_params)
    assert pe.valid?
    assert pe.has_persona?
  end

  test 'can use persona name rather than generator' do
    #
    #  Note that this gives us a persona, but the record is still
    #  not valid until we have a generator.
    #
    pe = ProtoEvent.new(@valid_params.except(:generator).merge({
      persona: "Invigilation"
    }))
    assert pe.has_persona?
    assert_not pe.valid?
  end

  test 'can use new, then give persona name' do
    pe = ProtoEvent.new
    assert_not pe.valid?
    assert_not pe.has_persona?
    pe.assign_attributes(@valid_params.except(:generator))
    assert_not pe.valid?
    assert_not pe.has_persona?
    pe.generator = @exam_cycle
    assert pe.valid?
  end

  test 'can add persona-specific values before or after generator' do
    pe = ProtoEvent.new
    assert_not pe.valid?
    pe.body = "A hand-crafted body"
    #
    #  Now exam-specific stuff.
    #
    pe.num_staff   = "1"
    assert_not pe.respond_to?(:num_staff)
    pe.generator   = @exam_cycle
    assert pe.respond_to?(:num_staff)
    pe.location_id = @location.element.id
    assert_equal "1", pe.num_staff
    assert_equal @location.element.id, pe.location_id
  end

  test 'loading proto_event from disk populates persona' do
    pe = ProtoEvent.create(@valid_params)
    id = pe.id
    npe = ProtoEvent.find(id)
    assert npe.has_persona?
    assert npe.valid?
  end

  test 'can generate through factory bot' do
    #
    #  This test because we struggled with this for a long time.
    #
    pe = FactoryBot.create(:proto_event)
    assert pe.valid?
    assert pe.has_persona?
    assert_equal 1, pe.proto_commitments.count
    assert_equal 1, pe.proto_requests.count
  end

  test 'can generate from exam_cycle' do
    pe = @exam_cycle.proto_events.create(@valid_params.except(:generator))
    assert pe.valid?
    assert pe.has_persona?
  end

  test "auto-generates a body" do
    pe = ProtoEvent.create(@valid_params.except(:body))
    assert pe.valid?
    assert_not pe.body.blank?
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
    pe =  ProtoEvent.create(@valid_params.except(:generator))
    assert_not pe.valid?
  end

  test "dates can't be backward" do
    pe = ProtoEvent.create(@valid_params.merge(ends_on: Date.yesterday))
    assert_not pe.valid?
  end

  test 'creating proto_event creates proto_commitment and proto_request' do
    pe = ProtoEvent.create(@valid_params)
    assert pe.valid?
    assert_equal 1, pe.proto_commitments.count
    assert_equal 1, pe.proto_requests.count
  end

  test "can create events" do
    pe = ProtoEvent.create(@valid_params)
    pe.ensure_required_events
    #
    #  The standard rota template has 12 slots * 2 days
    #
    assert_equal 24, pe.events.count
  end

  test 'having events prevents destruction' do
    pe = ProtoEvent.create(@valid_params)
    assert pe.can_destroy?
    pe.ensure_required_events
    assert_not pe.can_destroy?
  end

  test "having a selector element reduces the events" do
    exam_cycle = FactoryBot.create(:exam_cycle,
                                   default_rota_template: @rota_template,
                                   selector_element: @selector_element)
    pe = ProtoEvent.create(@valid_params.merge(generator: exam_cycle))
    pe.ensure_required_events
    assert_equal 4, pe.events.count
  end

  test "can split a proto_event by date" do
    pe = ProtoEvent.create(@valid_params)
    pe.ensure_required_events
    #
    #  The standard rota template has 12 slots * 2 days
    #
    assert_equal 24, pe.events.count
    other = pe.split(@tomorrow)
    pe.reload
    assert_equal 12, pe.events.count
    assert_equal 12, other.events.count
  end

end
