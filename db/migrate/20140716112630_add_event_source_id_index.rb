class AddEventSourceIdIndex < ActiveRecord::Migration
  def change
    add_index :events, :source_id
  end
end
