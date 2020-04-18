#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ProtoCommitmentTest < ActiveSupport::TestCase
  setup do
    @eventsource = Eventsource.find_by(name: "RotaSlot")
    @eventcategory = Eventcategory.cached_category("Invigilation")
    @rota_template = FactoryBot.create(:rota_template)
    @exam_cycle    = FactoryBot.create(:exam_cycle,
                                       default_rota_template: @rota_template)
    @location      = FactoryBot.create(:location)
    @valid_pe_params = {
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
    @proto_event = ProtoEvent.create(@valid_pe_params)
    @element = FactoryBot.create(:element)
    @valid_params = {
      proto_event: @proto_event,
      element: @element
    }
  end

  test "can create proto commitment" do
    pc = ProtoCommitment.new(@valid_params)
    assert pc.valid?
  end

  test "must have a proto event" do
    pc = ProtoCommitment.new(@valid_params.except(:proto_event))
    assert_not pc.valid?
  end

  test "must have an element" do
    pc = ProtoCommitment.new(@valid_params.except(:element))
    assert_not pc.valid?
  end

  test "must be unique" do
    pc1 = ProtoCommitment.create(@valid_params)
    pc2 = ProtoCommitment.new(@valid_params)
    assert_not pc2.valid?
  end

end
