require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  setup do
    @journal = FactoryBot.create(:journal)
    @user    = FactoryBot.create(:user)
    @event   = FactoryBot.create(:event)
    @valid_params = {
      journal: @journal,
      user:    @user,
      event:   @event
    }
  end

  test "can create journal entry" do
    je = JournalEntry.new(@valid_params)
    assert je.valid?
  end

  test "must have a journal" do
    je = JournalEntry.new(@valid_params.except(:journal))
    assert_not je.valid?
  end

  test "must have a user" do
    je = JournalEntry.new(@valid_params.except(:user))
    assert_not je.valid?
  end

  test "event is optional" do
    je = JournalEntry.new(@valid_params.except(:event))
    assert je.valid?
  end

  test "event details are copied over" do
    je = JournalEntry.new(@valid_params)
    assert_equal @event.starts_at, je.event_starts_at
    assert_equal @event.ends_at, je.event_ends_at
    assert_equal @event.all_day, je.event_all_day
  end

  test "can get entry type text for each entry" do
    JournalEntry.entry_types.each do |key, value|
      je = JournalEntry.new(@valid_params.merge(entry_type: key))
      assert_equal JournalEntry::NEATER_TEXTS[value],
        je.entry_type_text
      assert_equal JournalEntry::ELEMENT_TEXTS[key.to_sym],
        je.element_entry_type_text
    end
  end
end
