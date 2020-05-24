class AddEventsourceIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :events, :eventsource_id
  end
end
