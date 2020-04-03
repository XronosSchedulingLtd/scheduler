require 'test_helper'

class EventCollectionTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @base_date = @event.starts_at
    @valid_params = {
      era:                   Setting.current_era,
      repetition_start_date: @base_date,
      repetition_end_date:   @base_date + 3.months
    }
  end

  test "can create an event collection" do
    event_collection = EventCollection.new(@valid_params)
    assert event_collection.valid?
  end

  test "era is required" do
    event_collection = EventCollection.new(@valid_params.except(:era))
    assert_not event_collection.valid?
  end

  test "start date is required" do
    event_collection = EventCollection.new(@valid_params.except(:repetition_start_date))
    assert_not event_collection.valid?
  end

  test "end date is required" do
    event_collection = EventCollection.new(@valid_params.except(:repetition_end_date))
    assert_not event_collection.valid?
  end

  test "end date can't be before start date" do
    event_collection =
      EventCollection.new(
        @valid_params.merge(
          {
            repetition_end_date: @base_date - 1.day
          }
        )
    )
    assert_not event_collection.valid?
  end

  test "end date can't be more than a year after start date" do
    event_collection =
      EventCollection.new(
        @valid_params.merge(
          {
            repetition_end_date: @base_date + 1.year + 1.day
          }
        )
    )
    assert_not event_collection.valid?
  end
end
