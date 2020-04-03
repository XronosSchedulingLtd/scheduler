#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class ProtoRequestTest < ActiveSupport::TestCase
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

  test "can create proto request" do
    pr = ProtoRequest.new(@valid_params)
    assert pr.valid?
  end

  test "element is required" do
    pr = ProtoRequest.new(@valid_params.except(:element))
    assert_not pr.valid?
  end

  test "proto event is required" do
    pr = ProtoRequest.new(@valid_params.except(:proto_event))
    assert_not pr.valid?
  end

end
