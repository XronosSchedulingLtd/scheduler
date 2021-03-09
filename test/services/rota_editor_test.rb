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

end
