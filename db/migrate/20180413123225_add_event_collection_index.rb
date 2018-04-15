class AddEventCollectionIndex < ActiveRecord::Migration
  def change
    add_index :events, :event_collection_id
  end
end
