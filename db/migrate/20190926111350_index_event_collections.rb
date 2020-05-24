class IndexEventCollections < ActiveRecord::Migration[4.2]
  def change
    add_index :event_collections, :requesting_user_id
    add_index :commitments, :by_whom_id
  end
end
