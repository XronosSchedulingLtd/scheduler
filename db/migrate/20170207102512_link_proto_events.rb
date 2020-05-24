class LinkProtoEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :proto_event_id, :integer, :default => nil
    add_index :events, :proto_event_id
  end
end
