require 'test_helper'

class RotaEditorTest < ActiveSupport::TestCase

  setup do
    @template = FactoryBot.create(:rota_template)
    @rota     = FactoryBot.create(:rota_template, :no_slots)
  end

  test "can instantiate rota editor" do
    assert_nothing_raised do
      rota_editor = RotaEditor.new(@rota, @template)
      assert rota_editor.instance_of? RotaEditor
    end
  end

  test "template is optional" do
    assert_nothing_raised do
      rota_editor = RotaEditor.new(@rota)
      assert rota_editor.instance_of? RotaEditor
    end
  end

  test "can produce array of events" do
    rota_editor = RotaEditor.new(@rota, @template)
    events = rota_editor.events
    assert_equal @template.rota_slots.size * 7, events.size
    assert events[0].respond_to? :as_json
    for_json = events[0].as_json
    assert for_json.is_a? Hash
    assert for_json.has_key? :start
    assert for_json.has_key? :end
    assert for_json.has_key? :rendering
    assert_equal 'background', for_json[:rendering]
  end

  test "can add an event" do
    rota_editor = RotaEditor.new(@rota, @template)
    #
    #  First just a start time.
    #
    params = {
      day_no: 3,
      starts_at: "09:30"
    }
    assert_difference("RotaSlot.count") do
      rota_editor.add_event(params)
    end
    rs = RotaSlot.last
    assert_equal "09:25", rs.starts_at
    assert_equal "10:15", rs.ends_at
    assert_day_set(rs, 3)
    #
    #  Now both times
    #
    params = {
      day_no: 4,
      starts_at: "09:30",
      ends_at: "10:30"
    }
    assert_difference("RotaSlot.count") do
      rota_editor.add_event(params)
    end
    rs = RotaSlot.last
    assert_equal "09:30", rs.starts_at
    assert_equal "10:30", rs.ends_at
    assert_day_set(rs, 4)
    #
    #  And a single time which doesn't fit in a defined slot.
    #
    params = {
      day_no: 5,
      starts_at: "09:22"
    }
    assert_difference("RotaSlot.count") do
      rota_editor.add_event(params)
    end
    rs = RotaSlot.last
    assert_equal "09:22", rs.starts_at
    assert_equal "10:22", rs.ends_at
    assert_day_set(rs, 5)
  end

  private

  def assert_day_set(rs, n)
    rs.days.each_with_index do |day, i|
      if i == n
        assert day
      else
        assert_not day
      end
    end
  end

end
