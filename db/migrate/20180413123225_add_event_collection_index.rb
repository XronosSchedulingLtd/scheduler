class AddEventCollectionIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :events, :event_collection_id
  end
end
