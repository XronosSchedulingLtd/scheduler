require 'test_helper'

class EventCollectionTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    base_date = @event.starts_at
    @valid_params = {
      era:                   Setting.current_era,
      repetition_start_date: base_date,
      repetition_end_date:   base_date + 3.months,
      pre_select:            base_date.wday,
      weeks:                 ["A", "B", " "]
    }
  end

  test "can create an event collection" do
    event_collection = EventCollection.new(@valid_params)
    assert event_collection.valid?
  end

end
