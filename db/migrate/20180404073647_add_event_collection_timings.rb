class AddEventCollectionTimings < ActiveRecord::Migration
  def change
    add_column :event_collections, :update_requested_at, :datetime, default: nil
    add_column :event_collections, :update_started_at,   :datetime, default: nil
    add_column :event_collections, :update_finished_at,  :datetime, default: nil
    add_column :event_collections, :lock_version,        :integer,  default: 0, null: false
    add_column :event_collections, :requesting_user_id,  :integer,  default: nil
  end
end
