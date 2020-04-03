require 'test_helper'

class JournalEntryTest < ActiveSupport::TestCase
  setup do
    @journal = FactoryBot.create(:journal)
    @user    = FactoryBot.create(:user)
    @valid_params = {
      journal: @journal,
      user: @user
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

end
