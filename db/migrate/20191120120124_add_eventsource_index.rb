class AddEventsourceIndex < ActiveRecord::Migration
  def change
    add_index :events, :eventsource_id
  end
end
