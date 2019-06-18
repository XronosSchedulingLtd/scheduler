require 'test_helper'

class NoteTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @valid_parameters = {
      parent: @event,
      contents: "Hello world"
    }
  end

  test 'can create note' do
    note = Note.create(@valid_parameters)
    assert note.valid?
  end

  test 'note must have a parent' do
    note = Note.create(@valid_parameters.except(:parent))
    assert_not note.valid?
  end

  test 'blank notes still get formatted contents' do
    note = Note.create({
      parent: @event,
      contents: nil
    })
    assert note.valid?
    assert_equal "<p></p>", note.formatted_contents
  end
end
